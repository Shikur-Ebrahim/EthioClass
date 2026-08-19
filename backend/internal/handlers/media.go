package handlers

import (
	"net/http"
	"strings"

	"github.com/EthioClass/backend/internal/storage"
	"github.com/gin-gonic/gin"
)

// MediaProxyHandler streams an R2 object directly to the client.
// Route: GET /media/*key
// Example: GET /media/categories/abc123.jpg
func MediaProxyHandler(r2 *storage.R2Client) gin.HandlerFunc {
	return func(c *gin.Context) {
		if r2 == nil {
			c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Storage not configured"})
			return
		}

		// Extract key from URL: /media/categories/abc.jpg -> categories/abc.jpg
		key := c.Param("key")
		key = strings.TrimPrefix(key, "/")

		if key == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Missing file key"})
			return
		}

		body, contentType, size, err := r2.GetObject(c.Request.Context(), key)
		if err != nil {
			c.JSON(http.StatusNotFound, gin.H{"error": "File not found: " + err.Error()})
			return
		}
		defer body.Close()

		// Stream the object to the client
		c.Header("Cache-Control", "public, max-age=31536000") // cache for 1 year
		c.DataFromReader(http.StatusOK, size, contentType, body, nil)
	}
}
