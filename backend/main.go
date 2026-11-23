// Minimal StartTech backend. Replace/merge with the real application code from the
// much-to-do repository (feature/full-stack) - keep: PORT 8080, env config, /api/v1/health, JSON logs.
package main

import (
	"context"
	"encoding/json"
	"log/slog"
	"net"
	"net/http"
	"os"
	"time"
)

type config struct {
	Port      string
	RedisHost string
	MongoURI  string
}

func loadConfig() config {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}
	return config{
		Port:      port,
		RedisHost: os.Getenv("REDIS_HOST"),
		MongoURI:  os.Getenv("MONGO_URI"),
	}
}

// redisReachable opens a TCP connection to REDIS_HOST (host or host:port).
func redisReachable(host string) bool {
	if host == "" {
		return false
	}
	if _, _, err := net.SplitHostPort(host); err != nil {
		host = net.JoinHostPort(host, "6379")
	}
	conn, err := net.DialTimeout("tcp", host, 2*time.Second)
	if err != nil {
		return false
	}
	_ = conn.Close()
	return true
}

func newMux(cfg config) *http.ServeMux {
	mux := http.NewServeMux()

	health := func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		_ = json.NewEncoder(w).Encode(map[string]any{
			"status":           "ok",
			"redis_configured": cfg.RedisHost != "",
			"redis_reachable":  redisReachable(cfg.RedisHost),
			"mongo_configured": cfg.MongoURI != "",
		})
	}
	mux.HandleFunc("/health", health)
	mux.HandleFunc("/api/v1/health", health)
	return mux
}

func logging(next http.Handler, logger *slog.Logger) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		next.ServeHTTP(w, r)
		logger.Info("request",
			"method", r.Method,
			"path", r.URL.Path,
			"duration_ms", time.Since(start).Milliseconds(),
		)
	})
}

func main() {
	// Structured JSON logs to stdout (picked up by Container Insights / FluentBit)
	logger := slog.New(slog.NewJSONHandler(os.Stdout, nil))
	slog.SetDefault(logger)

	cfg := loadConfig()
	srv := &http.Server{
		Addr:              ":" + cfg.Port,
		Handler:           logging(newMux(cfg), logger),
		ReadHeaderTimeout: 5 * time.Second,
	}

	logger.Info("starting server", "port", cfg.Port)
	if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
		logger.Error("server failed", "error", err.Error())
		os.Exit(1)
	}
	_ = context.Background()
}
