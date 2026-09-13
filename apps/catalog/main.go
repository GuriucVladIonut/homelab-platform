package main

import (
	"encoding/json"
	"errors"
	"net/http"
	"path/filepath"
	"strings"
)

type Media struct { ID string `json:"id"`; MediaType string `json:"media_type"`; Title string `json:"title"`; CanonicalPath string `json:"canonical_path"`; Filename string `json:"filename"`; MimeType string `json:"mime_type"`; SizeBytes int64 `json:"size_bytes"`; SHA256 string `json:"sha256"`; Tags []string `json:"tags"`; Description string `json:"description"`; Status string `json:"status"` }
func validate(m Media) error { if m.MediaType == "" || m.Title == "" || m.CanonicalPath == "" { return errors.New("media_type, title, and canonical_path are required") }; clean := filepath.Clean(m.CanonicalPath); if clean != m.CanonicalPath || strings.HasPrefix(clean, "..") || !strings.HasPrefix(clean, "/srv/homelab/data/") { return errors.New("path must remain under /srv/homelab/data") }; if m.SizeBytes < 0 { return errors.New("size_bytes cannot be negative") }; return nil }
func main() { http.HandleFunc("/healthz", func(w http.ResponseWriter, _ *http.Request) { w.WriteHeader(http.StatusOK) }); http.HandleFunc("/api/media", func(w http.ResponseWriter, r *http.Request) { if r.Method != http.MethodPost { http.Error(w, "POST-only create endpoint", http.StatusMethodNotAllowed); return }; var m Media; if err := json.NewDecoder(r.Body).Decode(&m); err != nil { http.Error(w, "invalid JSON", 400); return }; if err := validate(m); err != nil { http.Error(w, err.Error(), 400); return }; w.WriteHeader(http.StatusAccepted); _ = json.NewEncoder(w).Encode(m) }); _ = http.ListenAndServe("127.0.0.1:8081", nil) }
