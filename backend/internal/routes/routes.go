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
	r.GET("/category-stats", handlers.GetCategoryStatsHandler(db))
	r.GET("/divisions", handlers.GetDivisionsHandler(db))
	r.GET("/courses", handlers.GetCoursesHandler(db))
	r.GET("/lessons", handlers.GetLessonsHandler(db))
	r.GET("/chapters", handlers.GetChaptersHandler(db))
	r.GET("/lesson-materials", handlers.GetLessonMaterialsHandler(db))
	r.GET("/questions", handlers.GetQuestionsHandler(db))
	r.GET("/quizzes", handlers.GetQuizzesHandler(db))

	// Media proxy — serves R2 objects through the API
	r.GET("/media/*key", handlers.MediaProxyHandler(r2))

	// Bookmarks
	r.POST("/bookmarks/lessons", handlers.AddLessonBookmarkHandler(db))
	r.DELETE("/bookmarks/lessons/:id", handlers.RemoveLessonBookmarkHandler(db))
	r.POST("/bookmarks/courses", handlers.AddCourseBookmarkHandler(db))
	r.DELETE("/bookmarks/courses/:id", handlers.RemoveCourseBookmarkHandler(db))
	r.GET("/bookmarks", handlers.GetBookmarksHandler(db))

	// Settings
	r.GET("/settings", handlers.GetSettingsHandler(db))
	r.PUT("/settings", handlers.UpdateSettingsHandler(db))

	// Admin Routes
	adminGroup := r.Group("/admin")
	// TODO: Add auth middleware to require admin role
	{
		adminGroup.POST("/categories", handlers.CreateCategoryHandler(db, r2))
		adminGroup.PUT("/categories/:id", handlers.UpdateCategoryHandler(db, r2))
		adminGroup.DELETE("/categories/:id", handlers.DeleteCategoryHandler(db))
		
		adminGroup.POST("/courses", handlers.CreateCourseHandler(db, r2))
		adminGroup.PUT("/courses/:id", handlers.UpdateCourseHandler(db, r2))
		adminGroup.DELETE("/courses/:id", handlers.DeleteCourseHandler(db))

		adminGroup.POST("/chapters", handlers.CreateChapterHandler(db, r2))
		adminGroup.PUT("/chapters/:id", handlers.UpdateChapterHandler(db, r2))
		adminGroup.DELETE("/chapters/:id", handlers.DeleteChapterHandler(db))

		adminGroup.POST("/lessons", handlers.CreateLessonHandler(db, r2))
		adminGroup.PUT("/lessons/:id", handlers.UpdateLessonHandler(db, r2))
		adminGroup.DELETE("/lessons/:id", handlers.DeleteLessonHandler(db))

		adminGroup.POST("/quizzes", handlers.CreateQuizHandler(db))
		adminGroup.PUT("/quizzes/:id", handlers.UpdateQuizHandler(db))
		adminGroup.DELETE("/quizzes/:id", handlers.DeleteQuizHandler(db))
	}

	// Payment Routes
	paymentGroup := r.Group("/payments")
	{
		paymentGroup.POST("/initialize", handlers.InitializePaymentHandler(db))
		paymentGroup.GET("/verify/:tx_ref", handlers.VerifyPaymentHandler(db))
	}
}
