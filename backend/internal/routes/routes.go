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

	authGroup := r.Group("/auth")
	{
		authGroup.POST("/signup", handlers.SignupHandler)
		authGroup.POST("/login", handlers.LoginHandler)
		authGroup.POST("/reset-password", handlers.ResetPasswordHandler)
		authGroup.PUT("/update-password", handlers.UpdatePasswordHandler)
		// Supabase password-reset redirect target. Reads the #access_token fragment
		// via JavaScript and redirects to ethioclass:// deep link as a query param.
		authGroup.GET("/callback", handlers.AuthCallbackHandler)
	}

	// Future API groups will be registered here:
	// v1 := r.Group("/api/v1")
	// v1.Use(middleware.Auth())
	// {
	//     v1.GET("/...", handlers....)
	// }
}
