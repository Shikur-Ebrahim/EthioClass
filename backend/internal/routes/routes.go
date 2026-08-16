package routes

import (
	"database/sql"

	"github.com/EthioClass/backend/internal/handlers"
	"github.com/EthioClass/backend/internal/middleware"
	"github.com/gin-gonic/gin"
)

// Register sets up all API routes on the given gin engine.
func Register(r *gin.Engine, db *sql.DB) {
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

	// Course Content Routes
	r.GET("/categories", handlers.GetCategoriesHandler(db))
	r.GET("/divisions", handlers.GetDivisionsHandler(db))
	r.GET("/courses", handlers.GetCoursesHandler(db))
	r.GET("/lessons", handlers.GetLessonsHandler(db))
	r.GET("/lesson-materials", handlers.GetLessonMaterialsHandler(db))
	r.GET("/questions", handlers.GetQuestionsHandler(db))

	// Payment Routes
	paymentGroup := r.Group("/payments")
	{
		paymentGroup.POST("/create", handlers.CreatePaymentHandler(db))
		paymentGroup.GET("/:tx_ref/status", handlers.GetPaymentStatusHandler(db))
		paymentGroup.POST("/webhook/chapa", handlers.WebhookHandler(db))
	}
}
