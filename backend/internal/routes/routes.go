package routes

import (
	"github.com/EthioClass/backend/internal/handlers"
	"github.com/EthioClass/backend/internal/middleware"
	"github.com/gin-gonic/gin"
)

// Register sets up all API routes on the given gin engine.
func Register(r *gin.Engine) {
	r.Use(middleware.Logger())
	r.Use(middleware.CORS())

	// Health check — unauthenticated, no rate limit needed
	r.GET("/health", handlers.Health)

	// Future API groups will be registered here:
	// v1 := r.Group("/api/v1")
	// v1.Use(middleware.Auth())
	// {
	//     v1.GET("/...", handlers....)
	// }
}
