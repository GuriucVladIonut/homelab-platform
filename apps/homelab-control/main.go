package main

import (
	"context"
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"flag"
	"fmt"
	"html/template"
	"io"
	"log"
	"net/http"
	"net/url"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strconv"
	"strings"
	"sync"
	"syscall"
	"time"
)

const defaultKubeconfig = "/opt/homelab/control/kubeconfig-reader"

type app struct {
	csrf, endpoints, kubeconfig, promService, helper string
	started                                          time.Time
	mu                                               sync.RWMutex
	lastAction                                       string
	cache                                            dashboard
	cacheAt                                          time.Time
	cacheValid                                       bool
}
type endpoint struct {
	Name, Category, Namespace, Exposure, PrivateURL, PublicURL, HealthPath, Documentation, State string
	Enabled                                                                                      bool
}
type hostStatus struct {
	Hostname, OS, Kernel, Uptime, ServiceUptime, CPUModel, Load, Route, IPv4, UFW, FailedUnits                                   string
	CPUs, RAMTotal, RAMUsed, RAMAvailable, RAMPercent, ZRAMSize, ZRAMUsed, ZRAMState, Root, Homelab, Backups, Data, SMART, State string
}
type workloadSummary struct{ Ready, Total int }
type unhealthy struct{ Kind, Namespace, Name, Status string }
type kubeStatus struct {
	Available, Ready                                        bool
	State, Node, Version, Error                             string
	Namespaces, Pods, Running, Pending, Failed, NonReady    int
	Deployments, DaemonSets, StatefulSets, PVCs, Flux, Helm workloadSummary
	Unhealthy                                               []unhealthy
	ServiceClusterIP                                        string
}
type alert struct{ Name, Severity, Description string }
type observabilityStatus struct {
	State, Prometheus, Grafana, Targets, DownTargets, NodeExporter, KubeStateMetrics, Firing, Pending, CPU, Memory, Root, Homelab, NodeReady string
	Alerts                                                                                                                                   []alert
}
type backupStatus struct {
	State, LastBackup, LastVerification, Snapshot, Repository, LastError, NextRun string
}
type dashboard struct {
	CSRF, LastAction      string
	Host                  hostStatus
	Cluster               kubeStatus
	Observability         observabilityStatus
	Endpoints             []endpoint
	Backups               backupStatus
	K3sActive, K3sEnabled bool
}

var page = template.Must(template.New("page").Funcs(template.FuncMap{"statusClass": func(s string) string { return strings.ToLower(strings.ReplaceAll(s, " ", "-")) }}).Parse(`<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width"><title>Homelab Control</title>
<style>:root{color-scheme:light dark}body{font:15px system-ui,sans-serif;max-width:1180px;margin:auto;padding:1rem;line-height:1.4}section{border:1px solid #888;border-radius:8px;padding:1rem;margin:1rem 0;overflow:auto}h1{margin-top:0}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(220px,1fr));gap:.55rem}.card{padding:.55rem;border:1px solid #777;border-radius:6px}table{border-collapse:collapse;width:100%;min-width:520px}th,td{text-align:left;padding:.4rem .55rem;border-bottom:1px solid #666;vertical-align:top}.ok{color:#16803c}.degraded,.warn{color:#b06b00}.error,.offline{color:#b00020}.disabled,.unknown{color:#777}.badge{font-weight:700}button{margin:.2rem;padding:.45rem .7rem}a{color:#4d9cff}.muted{opacity:.8;font-size:.9em}pre{white-space:pre-wrap}</style></head>
<body><h1>Homelab Control</h1>{{if .LastAction}}<section><strong>Last action:</strong> <pre>{{.LastAction}}</pre></section>{{end}}
<section><h2>HOST <span class="badge {{statusClass .Host.State}}">{{.Host.State}}</span></h2><div class="grid"><div class="card"><b>System</b><br>{{.Host.Hostname}}<br>{{.Host.OS}}<br>{{.Host.Kernel}}<br>Uptime: {{.Host.Uptime}}<br>Service: {{.Host.ServiceUptime}}</div><div class="card"><b>CPU</b><br>{{.Host.CPUModel}}<br>{{.Host.CPUs}} logical CPUs<br>Load: {{.Host.Load}}</div><div class="card"><b>Memory</b><br>{{.Host.RAMUsed}} used / {{.Host.RAMTotal}} total<br>{{.Host.RAMAvailable}} available ({{.Host.RAMPercent}})</div><div class="card"><b>Storage</b><br>/: {{.Host.Root}}<br>/srv/homelab: {{.Host.Homelab}}<br>backups: {{.Host.Backups}}<br>data: {{.Host.Data}}</div><div class="card"><b>Network/security</b><br>Route: {{.Host.Route}}<br>IPv4: {{.Host.IPv4}}<br>UFW: {{.Host.UFW}}<br>Failed units: {{.Host.FailedUnits}}</div><div class="card"><b>zram / disk health</b><br>{{.Host.ZRAMState}}<br>{{.Host.ZRAMSize}} ({{.Host.ZRAMUsed}} used)<br>SMART: {{.Host.SMART}}</div></div></section>
<section><h2>CLUSTER CONTROL</h2><p>k3s: <span class="badge {{if .K3sActive}}ok{{else}}offline{{end}}">{{if .K3sActive}}ACTIVE{{else}}STOPPED{{end}}</span> · autostart: {{if .K3sEnabled}}ENABLED{{else}}DISABLED{{end}} · node: {{.Cluster.State}} · {{.Cluster.Version}}</p><form method="post" action="/cluster"><input type="hidden" name="csrf" value="{{.CSRF}}"><button name="action" value="status">Status</button><button name="action" value="start">Start</button><button name="action" value="autostart-enable">Enable auto-start</button><button name="action" value="autostart-disable">Disable auto-start</button><br><label>Confirm stop/restart <input type="checkbox" name="confirm" value="yes"></label><button name="action" value="stop">Stop</button><button name="action" value="restart">Restart</button></form></section>
<section><h2>KUBERNETES <span class="badge {{statusClass .Cluster.State}}">{{.Cluster.State}}</span></h2>{{if .Cluster.Available}}<p>Node {{.Cluster.Node}} · Kubernetes {{.Cluster.Version}}</p><div class="grid"><div class="card">Namespaces: {{.Cluster.Namespaces}}<br>Pods: {{.Cluster.Pods}}<br>Running: {{.Cluster.Running}}<br>Pending: {{.Cluster.Pending}}<br>Failed: {{.Cluster.Failed}}<br>Non-Ready: {{.Cluster.NonReady}}</div><div class="card">Deployments: {{.Cluster.Deployments.Ready}}/{{.Cluster.Deployments.Total}}<br>DaemonSets: {{.Cluster.DaemonSets.Ready}}/{{.Cluster.DaemonSets.Total}}<br>StatefulSets: {{.Cluster.StatefulSets.Ready}}/{{.Cluster.StatefulSets.Total}}<br>PVCs: {{.Cluster.PVCs.Total}}</div><div class="card">Flux Kustomizations: {{.Cluster.Flux.Ready}}/{{.Cluster.Flux.Total}}<br>HelmReleases: {{.Cluster.Helm.Ready}}/{{.Cluster.Helm.Total}}</div></div>{{if .Cluster.Unhealthy}}<h3>Unhealthy resources</h3><table><tr><th>Kind</th><th>Namespace</th><th>Name</th><th>Status</th></tr>{{range .Cluster.Unhealthy}}<tr><td>{{.Kind}}</td><td>{{.Namespace}}</td><td>{{.Name}}</td><td>{{.Status}}</td></tr>{{end}}</table>{{end}}{{else}}<p><strong>CLUSTER OFFLINE</strong>{{if .Cluster.Error}} — {{.Cluster.Error}}{{end}}</p>{{end}}</section>
<section><h2>ENDPOINTS</h2><table><tr><th>Name</th><th>Component</th><th>Scope</th><th>URL</th><th>State</th></tr>{{range .Endpoints}}<tr><td>{{.Name}}</td><td>{{.Category}}</td><td>{{.Exposure}}</td><td>{{if .Enabled}}<a href="{{.PrivateURL}}">{{.PrivateURL}}</a>{{else}}{{.PrivateURL}}{{end}}</td><td class="{{statusClass .State}}">{{.State}}</td></tr>{{end}}</table></section>
<section><h2>OBSERVABILITY <span class="badge {{statusClass .Observability.State}}">{{.Observability.State}}</span></h2><div class="grid"><div class="card">Prometheus: {{.Observability.Prometheus}}<br>Targets: {{.Observability.Targets}}<br>Down: {{.Observability.DownTargets}}<br>node-exporter: {{.Observability.NodeExporter}}<br>kube-state-metrics: {{.Observability.KubeStateMetrics}}</div><div class="card">Grafana: {{.Observability.Grafana}}<br>Firing alerts: {{.Observability.Firing}}<br>Pending alerts: {{.Observability.Pending}}</div><div class="card">CPU/load: {{.Observability.CPU}}<br>Memory: {{.Observability.Memory}}<br>Root: {{.Observability.Root}}<br>/srv: {{.Observability.Homelab}}<br>Node Ready: {{.Observability.NodeReady}}</div></div>{{if .Observability.Alerts}}<h3>Firing alerts</h3><table><tr><th>Alert</th><th>Severity</th><th>Description</th></tr>{{range .Observability.Alerts}}<tr><td>{{.Name}}</td><td>{{.Severity}}</td><td>{{.Description}}</td></tr>{{end}}</table>{{end}}</section>
<section><h2>STORAGE</h2><p>Root: {{.Host.Root}} · /srv/homelab: {{.Host.Homelab}} · backups: {{.Host.Backups}} · data: {{.Host.Data}}</p><p>Data hierarchy: {{.Host.Data}}<br>Local-path PVCs: {{.Cluster.PVCs.Total}} · SMART: {{.Host.SMART}} · Samba: DISABLED</p></section><section><h2>BACKUPS <span class="badge {{statusClass .Backups.State}}">{{.Backups.State}}</span></h2><p><strong>NOT DISASTER RECOVERY</strong></p><p>Last backup: {{.Backups.LastBackup}}<br>Last verification: {{.Backups.LastVerification}}<br>K3s snapshot: {{.Backups.Snapshot}}<br>Repository: {{.Backups.Repository}}<br>Next run: {{.Backups.NextRun}}<br>Last error: {{.Backups.LastError}}</p></section><section><h2>DATA CATALOG</h2><p class="muted">OPTIONAL_DISABLED — metadata-only catalog is prepared but not deployed.</p></section></body></html>`))

func main() {
	listen := flag.String("listen", "127.0.0.1:8090", "listen address")
	endpoints := flag.String("endpoints", "infra/config/endpoints.yaml", "endpoint registry")
	kubeconfig := flag.String("kubeconfig", defaultKubeconfig, "read-only Kubernetes kubeconfig")
	promService := flag.String("prometheus-service", "observability-kube-prometh-prometheus", "Prometheus service name")
	flag.Parse()
	buf := make([]byte, 32)
	if _, err := rand.Read(buf); err != nil {
		log.Fatal(err)
	}
	a := &app{csrf: hex.EncodeToString(buf), endpoints: *endpoints, kubeconfig: *kubeconfig, promService: *promService, helper: "/usr/local/sbin/homelab-control-helper", started: time.Now()}
	mux := http.NewServeMux()
	mux.HandleFunc("/healthz", a.health)
	mux.HandleFunc("/", a.index)
	mux.HandleFunc("/cluster", a.cluster)
	log.Printf("homelab-control listening on %s", *listen)
	log.Fatal(http.ListenAndServe(*listen, a.secure(mux)))
}
func (a *app) secure(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("X-Content-Type-Options", "nosniff")
		w.Header().Set("X-Frame-Options", "DENY")
		w.Header().Set("Referrer-Policy", "same-origin")
		w.Header().Set("Content-Security-Policy", "default-src 'self'; style-src 'unsafe-inline'")
		next.ServeHTTP(w, r)
	})
}
func (a *app) health(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "GET required", http.StatusMethodNotAllowed)
		return
	}
	w.WriteHeader(http.StatusOK)
	_, _ = w.Write([]byte("ok\n"))
}
func (a *app) index(w http.ResponseWriter, r *http.Request) {
	if r.URL.Path != "/" {
		http.NotFound(w, r)
		return
	}
	if err := page.Execute(w, a.snapshot()); err != nil {
		log.Printf("render dashboard: %v", err)
	}
}
func (a *app) cluster(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "POST required", http.StatusMethodNotAllowed)
		return
	}
	if r.FormValue("csrf") != a.csrf {
		log.Printf("csrf rejection path=%s", r.URL.Path)
		http.Error(w, "invalid CSRF token", http.StatusForbidden)
		return
	}
	action := r.FormValue("action")
	allowed := map[string]bool{"status": true, "start": true, "stop": true, "restart": true, "autostart-enable": true, "autostart-disable": true}
	if !allowed[action] {
		log.Printf("invalid helper request action=%q", action)
		http.Error(w, "operation not allowed", http.StatusBadRequest)
		return
	}
	if (action == "stop" || action == "restart") && r.FormValue("confirm") != "yes" {
		http.Error(w, "confirmation required", http.StatusBadRequest)
		return
	}
	ctx, cancel := context.WithTimeout(r.Context(), 20*time.Second)
	defer cancel()
	out, err := exec.CommandContext(ctx, "sudo", "-n", a.helper, action).CombinedOutput()
	result := strings.TrimSpace(string(out))
	if err != nil {
		result = "FAILED: " + result + " (" + err.Error() + ")"
	}
	a.mu.Lock()
	a.lastAction = action + ": " + result
	a.cacheValid = false
	a.mu.Unlock()
	log.Printf("cluster action=%s result=%q err=%v", action, result, err)
	http.Redirect(w, r, "/", http.StatusSeeOther)
}
func (a *app) snapshot() dashboard {
	a.mu.RLock()
	if a.cacheValid && time.Since(a.cacheAt) < 10*time.Second {
		cached := a.cache
		a.mu.RUnlock()
		return cached
	}
	a.mu.RUnlock()
	h := collectHost(a.started, a.helper)
	k := collectKubernetes(a.kubeconfig)
	o := collectObservability(a.kubeconfig, a.promService, k.ServiceClusterIP, h)
	e := loadEndpoints(a.endpoints)
	for i := range e {
		e[i].State = endpointState(e[i])
	}
	a.mu.RLock()
	last := a.lastAction
	a.mu.RUnlock()
	active, enabled := k3sState()
	d := dashboard{CSRF: a.csrf, LastAction: last, Host: h, Cluster: k, Observability: o, Endpoints: e, Backups: collectBackups(), K3sActive: active, K3sEnabled: enabled}
	a.mu.Lock()
	a.cache, a.cacheAt, a.cacheValid = d, time.Now(), true
	a.mu.Unlock()
	return d
}

func command(ctx context.Context, name string, args ...string) string {
	out, err := exec.CommandContext(ctx, name, args...).Output()
	if err != nil {
		return ""
	}
	return strings.TrimSpace(string(out))
}
func read(path string) string { b, _ := os.ReadFile(path); return strings.TrimSpace(string(b)) }
func collectHost(start time.Time, helper string) hostStatus {
	h := hostStatus{Hostname: read("/etc/hostname"), OS: parseOS(), Kernel: command(context.Background(), "uname", "-r"), CPUs: strconv.Itoa(runtime.NumCPU()), ServiceUptime: time.Since(start).Round(time.Second).String(), State: "OK"}
	h.Uptime = formatSeconds(readFloat("/proc/uptime"))
	h.Load = first(read("/proc/loadavg"), "unknown")
	h.CPUModel = firstField(read("/proc/cpuinfo"), "model name")
	h.RAMTotal, h.RAMUsed, h.RAMAvailable, h.RAMPercent = memoryInfo()
	h.ZRAMSize = humanBytes(readIntFile("/sys/block/zram0/disksize"))
	h.ZRAMUsed = swapUsed("/dev/zram0")
	h.ZRAMState = "ACTIVE"
	if h.ZRAMSize == "0 B" {
		h.ZRAMState = "DISABLED"
	}
	h.Root = filesystem("/")
	h.Homelab = filesystem("/srv/homelab")
	h.Backups = filesystem("/srv/homelab/backups")
	h.Data = filesystem("/srv/homelab/data")
	h.Route, h.IPv4 = networkInfo()
	h.UFW = first(helperOutput(helper, "ufw-status"), "UNKNOWN")
	h.FailedUnits = strconv.Itoa(countLines(command(context.Background(), "systemctl", "--failed", "--no-legend")))
	h.SMART = first(helperOutput(helper, "smart-status"), "UNAVAILABLE")
	if strings.Contains(h.UFW, "inactive") || h.FailedUnits != "0" {
		h.State = "WARN"
	}
	return h
}
func parseOS() string {
	for _, line := range strings.Split(read("/etc/os-release"), "\n") {
		if strings.HasPrefix(line, "PRETTY_NAME=") {
			return strings.Trim(strings.TrimPrefix(line, "PRETTY_NAME="), `"`)
		}
	}
	return "unknown"
}
func first(v, fallback string) string {
	if v == "" {
		return fallback
	}
	return v
}
func firstField(s, key string) string {
	for _, line := range strings.Split(s, "\n") {
		if strings.HasPrefix(strings.TrimSpace(line), key) {
			parts := strings.SplitN(line, ":", 2)
			if len(parts) == 2 {
				return strings.TrimSpace(parts[1])
			}
		}
	}
	return "unknown"
}

func helperOutput(helper, action string) string {
	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
	defer cancel()
	out, err := exec.CommandContext(ctx, "sudo", "-n", helper, action).Output()
	if err != nil {
		return ""
	}
	return strings.TrimSpace(string(out))
}
func readFloat(path string) float64 {
	fields := strings.Fields(read(path))
	if len(fields) == 0 {
		return 0
	}
	f, _ := strconv.ParseFloat(fields[0], 64)
	return f
}
func readIntFile(path string) int64 {
	v, _ := strconv.ParseInt(strings.TrimSpace(read(path)), 10, 64)
	return v
}
func formatSeconds(v float64) string {
	if v <= 0 {
		return "unknown"
	}
	return (time.Duration(v) * time.Second).Round(time.Second).String()
}
func humanBytes(v int64) string {
	if v <= 0 {
		return "0 B"
	}
	units := []string{"B", "KiB", "MiB", "GiB", "TiB"}
	n := float64(v)
	i := 0
	for n >= 1024 && i < len(units)-1 {
		n /= 1024
		i++
	}
	return fmt.Sprintf("%.1f %s", n, units[i])
}
func memoryInfo() (string, string, string, string) {
	var total, avail int64
	for _, line := range strings.Split(read("/proc/meminfo"), "\n") {
		f := strings.Fields(line)
		if len(f) < 2 {
			continue
		}
		v, _ := strconv.ParseInt(f[1], 10, 64)
		if f[0] == "MemTotal:" {
			total = v * 1024
		}
		if f[0] == "MemAvailable:" {
			avail = v * 1024
		}
	}
	used := total - avail
	p := 0.0
	if total > 0 {
		p = float64(used) * 100 / float64(total)
	}
	return humanBytes(total), humanBytes(used), humanBytes(avail), fmt.Sprintf("%.1f%%", p)
}
func filesystem(path string) string {
	var st syscall.Statfs_t
	if err := syscall.Statfs(path, &st); err != nil {
		return "UNAVAILABLE"
	}
	total := int64(st.Blocks) * int64(st.Bsize)
	avail := int64(st.Bavail) * int64(st.Bsize)
	used := total - int64(st.Bfree)*int64(st.Bsize)
	p := 0.0
	if total > 0 {
		p = float64(used) * 100 / float64(total)
	}
	return fmt.Sprintf("%s used / %s free (%.1f%%)", humanBytes(used), humanBytes(avail), p)
}
func swapUsed(name string) string {
	for _, line := range strings.Split(read("/proc/swaps"), "\n") {
		f := strings.Fields(line)
		if len(f) >= 4 && f[0] == name {
			v, _ := strconv.ParseInt(f[3], 10, 64)
			return humanBytes(v * 1024)
		}
	}
	return "0 B"
}
func networkInfo() (string, string) {
	route := command(context.Background(), "ip", "route", "show", "default")
	ip := command(context.Background(), "bash", "-c", "ip -4 route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if ($i==\"src\") print $(i+1)}'")
	return first(route, "UNKNOWN"), first(ip, "UNKNOWN")
}
func countLines(s string) int {
	if strings.TrimSpace(s) == "" {
		return 0
	}
	return len(strings.Split(strings.TrimSpace(s), "\n"))
}
func k3sState() (bool, bool) {
	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
	defer cancel()
	return command(ctx, "systemctl", "is-active", "k3s") == "active", command(ctx, "systemctl", "is-enabled", "k3s") == "enabled"
}

func kubectl(ctx context.Context, kubeconfig string, args ...string) []byte {
	full := append([]string{"--kubeconfig", kubeconfig}, args...)
	out, err := exec.CommandContext(ctx, "/usr/local/bin/kubectl", full...).Output()
	if err != nil {
		return nil
	}
	return out
}
func list(ctx context.Context, kubeconfig, resource string, allNamespaces bool) []map[string]interface{} {
	args := []string{"get", resource}
	if allNamespaces {
		args = append(args, "-A")
	}
	args = append(args, "-o", "json")
	b := kubectl(ctx, kubeconfig, args...)
	var v struct {
		Items []map[string]interface{} `json:"items"`
	}
	if json.Unmarshal(b, &v) != nil {
		return nil
	}
	return v.Items
}
func meta(item map[string]interface{}) (string, string) {
	m, _ := item["metadata"].(map[string]interface{})
	ns, _ := m["namespace"].(string)
	name, _ := m["name"].(string)
	return ns, name
}
func condition(item map[string]interface{}, typ string) string {
	s, _ := item["status"].(map[string]interface{})
	cs, _ := s["conditions"].([]interface{})
	for _, c := range cs {
		x, _ := c.(map[string]interface{})
		if x["type"] == typ {
			v, _ := x["status"].(string)
			return v
		}
	}
	return ""
}
func intValue(v interface{}) int {
	if x, ok := v.(float64); ok {
		return int(x)
	}
	return 0
}
func appendUnhealthy(out []unhealthy, u unhealthy) []unhealthy {
	if len(out) < 10 {
		return append(out, u)
	}
	return out
}
func collectKubernetes(kubeconfig string) kubeStatus {
	k := kubeStatus{State: "OFFLINE"}
	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()
	nodes := list(ctx, kubeconfig, "nodes", false)
	if nodes == nil {
		k.Error = "read-only Kubernetes adapter unavailable"
		return k
	}
	k.Available = true
	k.State = "OK"
	if len(nodes) > 0 {
		_, k.Node = meta(nodes[0])
		s, _ := nodes[0]["status"].(map[string]interface{})
		ni, _ := s["nodeInfo"].(map[string]interface{})
		k.Version, _ = ni["kubeletVersion"].(string)
		if condition(nodes[0], "Ready") != "True" {
			k.State = "DEGRADED"
		}
	}
	k.Namespaces = len(list(ctx, kubeconfig, "namespaces", false))
	pods := list(ctx, kubeconfig, "pods", true)
	k.Pods = len(pods)
	for _, p := range pods {
		phase := ""
		if s, ok := p["status"].(map[string]interface{}); ok {
			phase, _ = s["phase"].(string)
		}
		if phase == "Running" {
			k.Running++
		}
		if phase == "Pending" {
			k.Pending++
		}
		if phase == "Failed" {
			k.Failed++
		}
		if phase != "Running" && phase != "Succeeded" {
			k.NonReady++
			ns, name := meta(p)
			k.Unhealthy = appendUnhealthy(k.Unhealthy, unhealthy{"Pod", ns, name, phase})
		}
	}
	specs := []struct {
		resource, kind, ready, total string
		dst                          *workloadSummary
	}{{"deployments", "Deployment", "readyReplicas", "replicas", &k.Deployments}, {"daemonsets", "DaemonSet", "numberReady", "desiredNumberScheduled", &k.DaemonSets}, {"statefulsets", "StatefulSet", "readyReplicas", "currentReplicas", &k.StatefulSets}}
	for _, x := range specs {
		for _, item := range list(ctx, kubeconfig, x.resource, true) {
			s, _ := item["status"].(map[string]interface{})
			ready, total := intValue(s[x.ready]), intValue(s[x.total])
			x.dst.Total++
			if ready == total && total > 0 {
				x.dst.Ready++
			} else {
				ns, name := meta(item)
				k.Unhealthy = appendUnhealthy(k.Unhealthy, unhealthy{x.kind, ns, name, fmt.Sprintf("%d/%d ready", ready, total)})
			}
		}
	}
	k.PVCs.Total = len(list(ctx, kubeconfig, "persistentvolumeclaims", true))
	for _, item := range list(ctx, kubeconfig, "kustomizations.kustomize.toolkit.fluxcd.io", true) {
		k.Flux.Total++
		if condition(item, "Ready") == "True" {
			k.Flux.Ready++
		}
	}
	for _, item := range list(ctx, kubeconfig, "helmreleases.helm.toolkit.fluxcd.io", true) {
		k.Helm.Total++
		if condition(item, "Ready") == "True" {
			k.Helm.Ready++
		}
	}
	if k.NonReady > 0 || k.Deployments.Ready != k.Deployments.Total || k.DaemonSets.Ready != k.DaemonSets.Total || k.StatefulSets.Ready != k.StatefulSets.Total || k.Flux.Ready != k.Flux.Total || k.Helm.Ready != k.Helm.Total {
		k.State = "DEGRADED"
	}
	if b := kubectl(ctx, kubeconfig, "get", "service", "observability-kube-prometh-prometheus", "-n", "observability", "-o", "json"); b != nil {
		var s struct {
			Spec struct {
				ClusterIP string `json:"clusterIP"`
			} `json:"spec"`
		}
		if json.Unmarshal(b, &s) == nil {
			k.ServiceClusterIP = s.Spec.ClusterIP
		}
	}
	return k
}

func collectObservability(kubeconfig, service, clusterIP string, h hostStatus) observabilityStatus {
	o := observabilityStatus{State: "UNKNOWN", Prometheus: "UNAVAILABLE", Grafana: "UNKNOWN", NodeExporter: "UNKNOWN", KubeStateMetrics: "UNKNOWN", CPU: h.Load, Memory: h.RAMPercent, Root: h.Root, Homelab: h.Homelab}
	if clusterIP == "" {
		return o
	}
	base := "http://" + clusterIP + ":9090"
	client := &http.Client{Timeout: 1500 * time.Millisecond}
	query := func(q string) string {
		resp, err := client.Get(base + "/api/v1/query?query=" + url.QueryEscape(q))
		if err != nil {
			return ""
		}
		defer resp.Body.Close()
		b, _ := io.ReadAll(io.LimitReader(resp.Body, 128*1024))
		var v struct {
			Data struct {
				Result []struct {
					Value []interface{} `json:"value"`
				} `json:"result"`
			} `json:"data"`
		}
		if json.Unmarshal(b, &v) != nil || len(v.Data.Result) == 0 || len(v.Data.Result[0].Value) < 2 {
			return "0"
		}
		return fmt.Sprint(v.Data.Result[0].Value[1])
	}
	o.Prometheus = "AVAILABLE"
	if grafanaIP := serviceIP(kubeconfig, "observability-grafana", "observability"); grafanaIP != "" {
		resp, err := (&http.Client{Timeout: 1500 * time.Millisecond}).Get("http://" + grafanaIP + "/api/health")
		if err == nil {
			resp.Body.Close()
			if resp.StatusCode >= 200 && resp.StatusCode < 300 {
				o.Grafana = "AVAILABLE"
			} else {
				o.Grafana = "ERROR"
			}
		} else {
			o.Grafana = "OFFLINE"
		}
	}
	o.Targets = query("count(up)")
	o.DownTargets = query("count(up == 0)")
	o.NodeExporter = upState(query(`min(up{job=~".*node-exporter.*"})`))
	o.KubeStateMetrics = upState(query(`min(up{job=~".*kube-state-metrics.*"})`))
	o.NodeReady = upState(query(`min(kube_node_status_condition{condition="Ready",status="true"})`))
	o.Firing = query(`count(ALERTS{alertstate="firing"})`)
	o.Pending = query(`count(ALERTS{alertstate="pending"})`)
	o.Alerts = prometheusAlerts(client, base)
	if o.DownTargets != "0" || o.NodeExporter == "DOWN" || o.KubeStateMetrics == "DOWN" {
		o.State = "DEGRADED"
	} else {
		o.State = "OK"
	}
	return o
}

func serviceIP(kubeconfig, name, namespace string) string {
	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
	defer cancel()
	b := kubectl(ctx, kubeconfig, "get", "service", name, "-n", namespace, "-o", "json")
	var service struct {
		Spec struct {
			ClusterIP string `json:"clusterIP"`
		} `json:"spec"`
	}
	if json.Unmarshal(b, &service) != nil {
		return ""
	}
	return service.Spec.ClusterIP
}

func collectBackups() backupStatus {
	b := backupStatus{State: "NOT CONFIGURED", LastBackup: "NOT RUN", LastVerification: "NOT RUN", Snapshot: "NOT FOUND", Repository: "UNKNOWN", LastError: "NONE", NextRun: "UNKNOWN"}
	for _, line := range strings.Split(read("/var/lib/homelab-backup/status.env"), "\n") {
		parts := strings.SplitN(line, "=", 2)
		if len(parts) != 2 {
			continue
		}
		value := strings.TrimSpace(parts[1])
		switch parts[0] {
		case "STATE":
			b.State = value
		case "LAST_BACKUP":
			b.LastBackup = value
		case "LAST_VERIFICATION":
			b.LastVerification = value
		case "LATEST_K3S_SNAPSHOT":
			b.Snapshot = value
		case "REPOSITORY":
			b.Repository = value
		case "LAST_ERROR":
			b.LastError = value
		case "NEXT_RUN":
			b.NextRun = value
		}
	}
	return b
}
func upState(v string) string {
	if v == "1" {
		return "UP"
	}
	if v == "0" {
		return "DOWN"
	}
	return "UNKNOWN"
}

func prometheusAlerts(client *http.Client, base string) []alert {
	resp, err := client.Get(base + "/api/v1/alerts")
	if err != nil {
		return nil
	}
	defer resp.Body.Close()
	var payload struct {
		Data struct {
			Alerts []struct {
				Labels      map[string]string `json:"labels"`
				Annotations map[string]string `json:"annotations"`
				State       string            `json:"state"`
			} `json:"alerts"`
		} `json:"data"`
	}
	if json.NewDecoder(io.LimitReader(resp.Body, 256*1024)).Decode(&payload) != nil {
		return nil
	}
	result := make([]alert, 0, 10)
	for _, item := range payload.Data.Alerts {
		if item.State != "firing" || len(result) >= 10 {
			continue
		}
		result = append(result, alert{Name: item.Labels["alertname"], Severity: first(item.Labels["severity"], "unknown"), Description: first(item.Annotations["description"], item.Annotations["summary"])})
	}
	return result
}
func loadEndpoints(path string) []endpoint {
	b, err := os.ReadFile(filepath.Clean(path))
	if err != nil {
		return nil
	}
	var out []endpoint
	var cur *endpoint
	for _, raw := range strings.Split(string(b), "\n") {
		line := strings.TrimSpace(raw)
		if line == "-" || strings.HasPrefix(line, "- name:") {
			if cur != nil {
				out = append(out, *cur)
			}
			cur = &endpoint{}
			line = strings.TrimSpace(strings.TrimPrefix(line, "- "))
		}
		if cur == nil || !strings.Contains(line, ":") {
			continue
		}
		p := strings.SplitN(line, ":", 2)
		key, value := strings.TrimSpace(p[0]), strings.Trim(strings.TrimSpace(p[1]), `"'`)
		switch key {
		case "name":
			cur.Name = value
		case "category":
			cur.Category = value
		case "namespace":
			cur.Namespace = value
		case "exposure":
			cur.Exposure = value
		case "private_url":
			cur.PrivateURL = value
		case "public_url":
			cur.PublicURL = value
		case "health_path":
			cur.HealthPath = value
		case "documentation":
			cur.Documentation = value
		case "enabled":
			cur.Enabled = value == "true"
		}
	}
	if cur != nil {
		out = append(out, *cur)
	}
	return out
}
func endpointState(e endpoint) string {
	if !e.Enabled {
		return "DISABLED"
	}
	u, err := url.Parse(e.PrivateURL)
	if err != nil || (u.Scheme != "http" && u.Scheme != "https") {
		return "UNKNOWN"
	}
	c := &http.Client{Timeout: 800 * time.Millisecond}
	req, _ := http.NewRequest(http.MethodGet, e.PrivateURL+e.HealthPath, nil)
	resp, err := c.Do(req)
	if err != nil {
		return "OFFLINE"
	}
	resp.Body.Close()
	if resp.StatusCode >= 200 && resp.StatusCode < 500 {
		return "OK"
	}
	return "ERROR"
}
