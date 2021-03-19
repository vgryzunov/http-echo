package main

import (
	"fmt"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promhttp"
	"log"
	"net/http"
	"os"
	"strconv"
	"time"
)

var hostName string
var port string

var (
	histogram = prometheus.NewHistogramVec(prometheus.HistogramOpts{
		Subsystem: "http_server",
		Name:      "resp_time",
		Help:      "Request response time",
	}, []string{
		"host",
		"code",
		"method",
		"path",
	})
)

func main() {
	ParseArgs()
	InitVars()
	RunServer()
}

func InitVars() {
	var err error
	if hostName, err = os.Hostname(); err != nil {
		hostName = ""
	}
}

func ParseArgs() {
	if len(os.Args) == 1 {
		port = "8080"
	} else {
		port = os.Args[1]
		if len(os.Args) == 2 {
			if _, err := strconv.Atoi(port); err != nil {
				log.Fatalf("Invalid port: %s (%s)\n", port, err)
			}
		} else {
			log.Fatalf("Usage %s %s\n", os.Args[0], os.Args[1])
		}
	}
}

func RunServer() {
	mux := http.NewServeMux()
	mux.HandleFunc("/", EchoServer)
	mux.Handle("/metrics", prometheusHandler())
	log.Printf("Listening the port: %s", port)
	log.Fatal("ListenAndServe: ", http.ListenAndServe(":"+port, mux))
}

func EchoServer(w http.ResponseWriter, req *http.Request) {
	start := time.Now()
	defer func() { recordMetrics(start, req, http.StatusOK) }()

	log.Printf("%s request to %s\n", req.Method, req.RequestURI)

	_, _ = fmt.Fprintf(w, "Host = %q\n", req.Host)
	log.Printf("Host = %q\n", req.Host)

	_, _ = fmt.Fprintf(w, "RemoteAddr = %q\n", req.RemoteAddr)
	log.Printf("RemoteAddr = %q\n", req.RemoteAddr)

	_, _ = fmt.Fprintf(w, "%s %s %s\n", req.Method, req.URL, req.Proto)
	log.Printf("%s %s %s\n", req.Method, req.URL, req.Proto)

	for k, v := range req.Header {
		_, _ = fmt.Fprintf(w, "Header[%q] = %q\n", k, v)
		log.Printf("Header[%q] = %q\n", k, v)
	}
}

var prometheusHandler = func() http.Handler {
	return promhttp.Handler()
}

func recordMetrics(start time.Time, req *http.Request, code int) {
	duration := time.Since(start)
	histogram.With(
		prometheus.Labels{
			"host":   hostName,
			"code":   fmt.Sprintf("%d", code),
			"method": req.Method,
			"path":   req.URL.Path,
		},
	).Observe(duration.Seconds())
}
