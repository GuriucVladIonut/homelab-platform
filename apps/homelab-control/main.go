package main

import (
	"crypto/rand"
	"encoding/hex"
	"flag"
	"fmt"
	"html/template"
	"log"
	"net/http"
	"os/exec"
	"strings"
	"time"
)

type app struct{ csrf string; endpoints string }

func main() {
	listen := flag.String("listen", "127.0.0.1:8090", "listen address")
	endpoints := flag.String("endpoints", "infra/config/endpoints.yaml", "endpoint registry")
	flag.Parse()
	buf := make([]byte, 32)
	if _, err := rand.Read(buf); err != nil { log.Fatal(err) }
	a := &app{csrf: hex.EncodeToString(buf), endpoints: *endpoints}
	mux := http.NewServeMux()
	// Use path-only registrations for Ubuntu 22.04's Go 1.18 toolchain;
	// method-pattern ServeMux routes require newer Go versions.
	mux.HandleFunc("/healthz", a.health)
	mux.HandleFunc("/", a.index)
	mux.HandleFunc("/cluster", a.cluster)
	log.Printf("homelab-control listening on %s", *listen)
	log.Fatal(http.ListenAndServe(*listen, a.secure(mux)))
}

func (a *app) secure(next http.Handler) http.Handler { return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) { w.Header().Set("X-Content-Type-Options", "nosniff"); w.Header().Set("Content-Security-Policy", "default-src 'self'; style-src 'unsafe-inline'"); next.ServeHTTP(w, r) }) }
func (a *app) health(w http.ResponseWriter, r *http.Request) { if r.Method != http.MethodGet { http.Error(w, "GET required", http.StatusMethodNotAllowed); return }; w.WriteHeader(http.StatusOK); _, _ = w.Write([]byte("ok\n")) }
func (a *app) index(w http.ResponseWriter, r *http.Request) { if r.URL.Path != "/" { http.NotFound(w, r); return }; data := struct{ CSRF, Endpoints, Uptime string }{a.csrf, a.endpoints, time.Since(start).Round(time.Second).String()}; _ = page.Execute(w, data) }
func (a *app) cluster(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost { http.Error(w, "POST required", http.StatusMethodNotAllowed); return }
	if r.FormValue("csrf") != a.csrf { http.Error(w, "invalid CSRF token", http.StatusForbidden); return }
	action := r.FormValue("action")
	allowed := map[string]bool{"status": true, "start": true, "stop": true, "restart": true, "autostart-enable": true, "autostart-disable": true}
	if !allowed[action] { http.Error(w, "operation not allowed", http.StatusBadRequest); return }
	if (action == "stop" || action == "restart") && r.FormValue("confirm") != "yes" { http.Error(w, "confirmation required", http.StatusBadRequest); return }
	cmd := exec.Command("sudo", "-n", "/usr/local/sbin/homelab-control-helper", action)
	out, err := cmd.CombinedOutput()
	log.Printf("cluster action=%s result=%q err=%v", action, strings.TrimSpace(string(out)), err)
	if err != nil { http.Error(w, "cluster operation failed", http.StatusBadGateway); return }
	fmt.Fprintf(w, "<pre>%s</pre><p><a href=\"/\">Back</a></p>", template.HTMLEscapeString(string(out)))
}

var start = time.Now()
var page = template.Must(template.New("page").Parse(`<!doctype html><html><head><meta name="viewport" content="width=device-width"><title>Homelab Control</title><style>body{font:16px system-ui;max-width:900px;margin:auto;padding:1rem}section{border:1px solid #aaa;border-radius:8px;padding:1rem;margin:1rem 0}button{margin:.25rem;padding:.5rem}a{color:#0645ad}</style></head><body><h1>Homelab Control</h1><section><h2>HOST</h2><p>Service uptime: {{.Uptime}}</p></section><section><h2>CLUSTER CONTROL</h2><form method="post" action="/cluster"><input type="hidden" name="csrf" value="{{.CSRF}}"><button name="action" value="status">Status</button><button name="action" value="start">Start</button><button name="action" value="autostart-enable">Enable auto-start</button><button name="action" value="autostart-disable">Disable auto-start</button><br><label>Confirm stop/restart <input type="checkbox" name="confirm" value="yes"></label><button name="action" value="stop">Stop</button><button name="action" value="restart">Restart</button></form></section><section><h2>KUBERNETES</h2><p>Use k9s/Grafana for detailed cluster state. The host UI reports OFFLINE cleanly until a status adapter is enabled.</p></section><section><h2>ENDPOINTS</h2><p>Canonical registry: {{.Endpoints}}</p></section><section><h2>OBSERVABILITY</h2><p>Summaries and links are added from the private endpoint registry after deployment.</p></section><section><h2>STORAGE</h2><p>Host paths remain outside Kubernetes lifecycle.</p></section><section><h2>DATA CATALOG</h2><p>Catalog service is prepared but disabled until the GitOps baseline is validated.</p></section></body></html>`))
