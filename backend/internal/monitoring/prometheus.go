package monitoring

import (
	"github.com/gin-gonic/gin"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

// PrometheusHandler returns a Gin handler for Prometheus metrics
func PrometheusHandler() gin.HandlerFunc {
	h := promhttp.Handler()
	return func(c *gin.Context) {
		h.ServeHTTP(c.Writer, c.Request)
	}
}

// MetricsMiddleware returns middleware that collects Prometheus metrics
func (m *Monitor) MetricsMiddleware() gin.HandlerFunc {
	return m.Middleware()
}
