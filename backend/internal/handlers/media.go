package handlers

import (
	"fmt"
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

		// Handle HEAD requests specifically to just return headers
		if c.Request.Method == http.MethodHead {
			contentType, size, err := r2.HeadObject(c.Request.Context(), key)
			if err != nil {
				c.Status(http.StatusNotFound)
				return
			}
			c.Header("Cache-Control", "public, max-age=31536000")
			c.Header("Content-Type", contentType)
			if size >= 0 {
				c.Header("Content-Length", fmt.Sprintf("%d", size))
			}
			c.Status(http.StatusOK)
			return
		}

		// For GET requests, generate a presigned URL and redirect the client directly to R2
		// This bypasses the Cloudflare proxy limit and natively supports Range requests (pausing/resuming).
		presignedURL, err := r2.GeneratePresignedGetURL(c.Request.Context(), key, 4*60*60*1000000000) // 4 hours valid
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to generate download link: " + err.Error()})
			return
		}

		c.Redirect(http.StatusFound, presignedURL)
	}
}
