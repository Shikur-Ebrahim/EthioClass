package api

import (
	"github.com/EthioClass/backend/internal/api/handlers"
	"github.com/EthioClass/backend/internal/api/middleware"
	"github.com/EthioClass/backend/internal/infrastructure/storage"
	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5/pgxpool"
	supa "github.com/supabase-community/supabase-go"
)

func SetupRouter(db *pgxpool.Pool, supaClient *supa.Client, r2Svc *storage.R2Service) *gin.Engine {
	r := gin.Default()

	// Health check endpoint
	r.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"status":  "ok",
			"service": "EthioClass API",
		})
	})

	// API v1 group
	api := r.Group("/api/v1")
	{
		// Protected routes — require a valid Supabase JWT
		protected := api.Group("/")
		protected.Use(middleware.AuthMiddleware(supaClient))
		{
			userHandler := handlers.NewUserHandler(db)
			protected.GET("/users/profile", userHandler.GetProfile)

			// Course routes
			courseHandler := handlers.NewCourseHandler(db)
			protected.GET("/courses", courseHandler.GetCourses)
			protected.GET("/courses/:id/modules", courseHandler.GetCourseModules)
			protected.POST("/courses", courseHandler.CreateCourse) // Admin only

			// Cloudflare R2 Upload routes
			if r2Svc != nil {
				uploadHandler := &handlers.UploadHandler{R2Service: r2Svc}
				// Admin route for uploading files
				protected.POST("/upload", uploadHandler.UploadFile)
				// Route to get presigned URL for viewing secure files
				protected.GET("/presigned-url", uploadHandler.GetPresignedURL)
			}
		}
	}

	return r
}
