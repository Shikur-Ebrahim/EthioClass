package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

// Health handles GET /health
// Returns a simple status response to confirm the backend is running.
func Health(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"status": "ok",
	})
}
