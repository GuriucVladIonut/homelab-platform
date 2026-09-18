package main

import (
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"html/template"
	"io"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"time"

	_ "github.com/lib/pq"
)

const dataRoot = "/srv/homelab/data"

type app struct {
	db  *sql.DB
	log *log.Logger
}
type mediaItem struct {
	ID           string    `json:"id"`
	MediaType    string    `json:"media_type"`
	Title        string    `json:"title"`
	RelativePath string    `json:"relative_path"`
	Filename     string    `json:"filename"`
	Extension    string    `json:"extension"`
	MimeType     string    `json:"mime_type"`
	SizeBytes    int64     `json:"size_bytes"`
	SHA256       string    `json:"sha256"`
	Status       string    `json:"status"`
	Description  string    `json:"description,omitempty"`
	CreatedAt    time.Time `json:"created_at"`
	ModifiedAt   time.Time `json:"modified_at"`
	DiscoveredAt time.Time `json:"discovered_at"`
}
type stats struct {
	Total      int            `json:"total"`
	Incoming   int            `json:"incoming"`
	Failed     int            `json:"failed"`
	Duplicates int            `json:"duplicates"`
	ByType     map[string]int `json:"by_type"`
}

func main() {
	logg := log.New(os.Stdout, "catalog ", log.LstdFlags)
	dsn := os.Getenv("DATABASE_URL")
	if dsn == "" {
		logg.Fatal("DATABASE_URL is required")
	}
	db, err := sql.Open("postgres", dsn)
	if err != nil {
		logg.Fatal(err)
	}
	defer db.Close()
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	if err := db.PingContext(ctx); err != nil {
		logg.Fatal(err)
	}
	if err := migrate(ctx, db); err != nil {
		logg.Fatal(err)
	}
	a := &app{db: db, log: logg}
	mux := http.NewServeMux()
	mux.HandleFunc("/", a.index)
	mux.HandleFunc("/healthz", a.health)
	mux.HandleFunc("/api/items", a.items)
	mux.HandleFunc("/api/stats", a.stats)
	mux.HandleFunc("/api/ingest", a.ingest)
	s := &http.Server{Addr: ":8080", Handler: security(mux), ReadHeaderTimeout: 3 * time.Second, ReadTimeout: 10 * time.Second, WriteTimeout: 10 * time.Second, IdleTimeout: 30 * time.Second}
	logg.Printf("listening on %s", s.Addr)
	logg.Fatal(s.ListenAndServe())
}
func migrate(ctx context.Context, db *sql.DB) error {
	b, err := os.ReadFile("/app/schema.sql")
	if err != nil {
		return err
	}
	_, err = db.ExecContext(ctx, string(b))
	return err
}
func security(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("X-Content-Type-Options", "nosniff")
		w.Header().Set("X-Frame-Options", "DENY")
		w.Header().Set("Referrer-Policy", "same-origin")
		next.ServeHTTP(w, r)
	})
}
func (a *app) health(w http.ResponseWriter, r *http.Request) {
	ctx, cancel := context.WithTimeout(r.Context(), 2*time.Second)
	defer cancel()
	if err := a.db.PingContext(ctx); err != nil {
		http.Error(w, "database unavailable", 503)
		return
	}
	w.WriteHeader(http.StatusOK)
	_, _ = io.WriteString(w, "ok\n")
}
func (a *app) index(w http.ResponseWriter, r *http.Request) {
	if r.URL.Path != "/" {
		http.NotFound(w, r)
		return
	}
	rows, err := a.db.QueryContext(r.Context(), `SELECT title,media_type,relative_path,size_bytes,status FROM media_item ORDER BY discovered_at DESC LIMIT 100`)
	if err != nil {
		http.Error(w, "query failed", 500)
		return
	}
	defer rows.Close()
	type row struct {
		Title, Type, Path, Status string
		Size                      int64
	}
	data := struct{ Rows []row }{Rows: []row{}}
	for rows.Next() {
		var x row
		if rows.Scan(&x.Title, &x.Type, &x.Path, &x.Size, &x.Status) == nil {
			data.Rows = append(data.Rows, x)
		}
	}
	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	_ = catalogPage.Execute(w, data)
}
func (a *app) items(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "GET required", 405)
		return
	}
	limit := 50
	if v, err := strconv.Atoi(r.URL.Query().Get("limit")); err == nil && v > 0 && v <= 100 {
		limit = v
	}
	q := r.URL.Query().Get("q")
	typ := r.URL.Query().Get("media_type")
	rows, err := a.db.QueryContext(r.Context(), `SELECT id,media_type,title,relative_path,filename,extension,mime_type,size_bytes,sha256,status,COALESCE(description,''),created_at,modified_at,discovered_at FROM media_item WHERE ($1='' OR title ILIKE '%'||$1||'%' OR filename ILIKE '%'||$1||'%') AND ($2='' OR media_type=$2) ORDER BY discovered_at DESC LIMIT $3`, q, typ, limit)
	if err != nil {
		http.Error(w, "query failed", 500)
		return
	}
	defer rows.Close()
	out := []mediaItem{}
	for rows.Next() {
		var x mediaItem
		if err := rows.Scan(&x.ID, &x.MediaType, &x.Title, &x.RelativePath, &x.Filename, &x.Extension, &x.MimeType, &x.SizeBytes, &x.SHA256, &x.Status, &x.Description, &x.CreatedAt, &x.ModifiedAt, &x.DiscoveredAt); err != nil {
			http.Error(w, "row failed", 500)
			return
		}
		out = append(out, x)
	}
	writeJSON(w, out)
}
func (a *app) stats(w http.ResponseWriter, r *http.Request) {
	var s stats
	s.ByType = map[string]int{}
	_ = a.db.QueryRowContext(r.Context(), `SELECT count(*) FROM media_item`).Scan(&s.Total)
	_ = a.db.QueryRowContext(r.Context(), `SELECT count(*) FROM media_item WHERE relative_path LIKE 'incoming/%'`).Scan(&s.Incoming)
	_ = a.db.QueryRowContext(r.Context(), `SELECT count(*) FROM ingest_event WHERE status='failed' AND created_at > now()-interval '24 hours'`).Scan(&s.Failed)
	_ = a.db.QueryRowContext(r.Context(), `SELECT count(*) FROM file_asset WHERE duplicate_of IS NOT NULL`).Scan(&s.Duplicates)
	rows, err := a.db.QueryContext(r.Context(), `SELECT media_type,count(*) FROM media_item GROUP BY media_type`)
	if err == nil {
		defer rows.Close()
		for rows.Next() {
			var k string
			var n int
			if rows.Scan(&k, &n) == nil {
				s.ByType[k] = n
			}
		}
	}
	writeJSON(w, s)
}
func (a *app) ingest(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "POST required", 405)
		return
	}
	http.Error(w, "ingest worker is intentionally explicit; place files in incoming and run the approved worker", 501)
}
func writeJSON(w http.ResponseWriter, v any) {
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(v)
}
func discover(path string) error {
	clean := filepath.Clean(path)
	if clean != path || !strings.HasPrefix(clean, dataRoot+string(os.PathSeparator)) {
		return errors.New("path outside data root")
	}
	st, err := os.Lstat(clean)
	if err != nil {
		return err
	}
	if !st.Mode().IsRegular() {
		return errors.New("not a regular file")
	}
	return nil
}

var catalogPage = template.Must(template.New("catalog").Parse(`<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width"><title>Homelab Catalog</title><style>body{font:16px system-ui;max-width:1100px;margin:2rem auto;padding:0 1rem}table{width:100%;border-collapse:collapse}th,td{text-align:left;padding:.5rem;border-bottom:1px solid #ccc}code{overflow-wrap:anywhere}</style><h1>Homelab Catalog</h1><p>Metadata only. Files remain on the homelab filesystem.</p>{{if .Rows}}<table><tr><th>Title</th><th>Type</th><th>Path</th><th>Size</th><th>Status</th></tr>{{range .Rows}}<tr><td>{{.Title}}</td><td>{{.Type}}</td><td><code>{{.Path}}</code></td><td>{{.Size}}</td><td>{{.Status}}</td></tr>{{end}}</table>{{else}}<p>No catalog items yet.</p>{{end}}`))
