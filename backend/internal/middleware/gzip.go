package middleware

import (
	"bufio"
	"compress/gzip"
	"net"
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
)

const (
	BestCompression    = gzip.BestCompression
	BestSpeed          = gzip.BestSpeed
	DefaultCompression = gzip.DefaultCompression
	NoCompression      = gzip.NoCompression
)

// GzipConfig represents the configuration for gzip middleware
type GzipConfig struct {
	Level int
	// Minimum size in bytes to enable compression
	MinSize int
	// List of MIME types to compress
	MimeTypes []string
	// List of paths to exclude from compression
	ExcludePaths []string
}

// DefaultGzipConfig returns a default gzip configuration
func DefaultGzipConfig() GzipConfig {
	return GzipConfig{
		Level:   DefaultCompression,
		MinSize: 1024, // 1KB minimum
		MimeTypes: []string{
			"application/json",
			"application/javascript",
			"application/xml",
			"text/css",
			"text/html",
			"text/plain",
			"text/xml",
		},
		ExcludePaths: []string{
			"/api/v1/health", // Health checks don't need compression
		},
	}
}

// Gzip returns a gin.HandlerFunc for gzip compression
func Gzip(config ...GzipConfig) gin.HandlerFunc {
	var cfg GzipConfig
	if len(config) > 0 {
		cfg = config[0]
	} else {
		cfg = DefaultGzipConfig()
	}

	return gin.HandlerFunc(func(c *gin.Context) {
		// Skip compression for excluded paths
		for _, path := range cfg.ExcludePaths {
			if strings.HasPrefix(c.Request.URL.Path, path) {
				c.Next()
				return
			}
		}

		// Check if client accepts gzip
		if !strings.Contains(c.Request.Header.Get("Accept-Encoding"), "gzip") {
			c.Next()
			return
		}

		// Set gzip headers
		c.Header("Content-Encoding", "gzip")
		c.Header("Vary", "Accept-Encoding")

		// Create gzip writer
		gz, err := gzip.NewWriterLevel(c.Writer, cfg.Level)
		if err != nil {
			c.Next()
			return
		}
		defer gz.Close()
		// Wrap the response writer
		c.Writer = &gzipWriter{
			ResponseWriter: c.Writer,
			writer:         gz,
			config:         cfg,
			written:        false,
		}
		c.Next()
	})
}

type gzipWriter struct {
	gin.ResponseWriter
	writer  *gzip.Writer
	config  GzipConfig
	written bool
}

func (g *gzipWriter) WriteString(s string) (int, error) {
	return g.Write([]byte(s))
}

func (g *gzipWriter) Write(data []byte) (int, error) {
	if !g.written {
		g.written = true

		// Check content type
		contentType := g.Header().Get("Content-Type")
		if contentType == "" {
			contentType = http.DetectContentType(data)
			g.Header().Set("Content-Type", contentType)
		}

		// Check if we should compress this content type
		shouldCompress := false
		for _, mimeType := range g.config.MimeTypes {
			if strings.Contains(contentType, mimeType) {
				shouldCompress = true
				break
			}
		}

		// Check minimum size
		if len(data) < g.config.MinSize {
			shouldCompress = false
		}

		// If we shouldn't compress, write directly to the original writer
		if !shouldCompress {
			g.Header().Del("Content-Encoding")
			g.Header().Del("Vary")
			return g.ResponseWriter.Write(data)
		}
	}

	return g.writer.Write(data)
}

func (g *gzipWriter) WriteHeader(code int) {
	g.Header().Del("Content-Length")
	g.ResponseWriter.WriteHeader(code)
}

func (g *gzipWriter) Flush() {
	g.writer.Flush()
	if f, ok := g.ResponseWriter.(http.Flusher); ok {
		f.Flush()
	}
}

func (g *gzipWriter) Status() int {
	return g.ResponseWriter.Status()
}

func (g *gzipWriter) Size() int {
	return g.ResponseWriter.Size()
}

func (g *gzipWriter) Written() bool {
	return g.ResponseWriter.Written()
}

func (g *gzipWriter) Hijack() (net.Conn, *bufio.ReadWriter, error) {
	if hj, ok := g.ResponseWriter.(http.Hijacker); ok {
		return hj.Hijack()
	}
	return nil, nil, nil
}

func (g *gzipWriter) Pusher() http.Pusher {
	if p, ok := g.ResponseWriter.(http.Pusher); ok {
		return p
	}
	return nil
}
