package routes

import (
	"database/sql"

	"github.com/EthioClass/backend/internal/handlers"
	"github.com/EthioClass/backend/internal/middleware"
	"github.com/EthioClass/backend/internal/storage"
	"github.com/gin-gonic/gin"
)

// Register sets up all API routes on the given gin engine.
func Register(r *gin.Engine, db *sql.DB, r2 *storage.R2Client) {
	r.Use(middleware.Logger())
	r.Use(middleware.CORS())

	// Health check — unauthenticated, no rate limit needed
	r.GET("/health", handlers.Health)

	authGroup := r.Group("/auth")
	{
		authGroup.POST("/signup", handlers.SignupHandler(db))
		authGroup.POST("/login", handlers.LoginHandler(db))
		authGroup.POST("/reset-password", handlers.ResetPasswordHandler)
		authGroup.PUT("/update-password", handlers.UpdatePasswordHandler)
		authGroup.PUT("/update-profile", handlers.UpdateProfileHandler(db))
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

	// Admin Routes
	adminGroup := r.Group("/admin")
	// TODO: Add auth middleware to require admin role
	{
		adminGroup.POST("/categories", handlers.CreateCategoryHandler(db, r2))
		adminGroup.PUT("/categories/:id", handlers.UpdateCategoryHandler(db, r2))
		adminGroup.DELETE("/categories/:id", handlers.DeleteCategoryHandler(db))
	}

	// Payment Routes
	paymentGroup := r.Group("/payments")
	{
		paymentGroup.POST("/initialize", handlers.InitializePaymentHandler(db))
		paymentGroup.GET("/verify/:tx_ref", handlers.VerifyPaymentHandler(db))
	}
}
