package api

import (
	"github.com/gin-gonic/gin"
)

func SetupRouter() *gin.Engine {
	r := gin.Default()

	// Simple health check endpoint
	r.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"status":  "ok",
			"service": "EthioClass API",
		})
	})

	// API group
	// api := r.Group("/api")
	// {
	// 	// Register routes here
	// }

	return r
}
