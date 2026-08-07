package handlers

import (
	"context"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5/pgxpool"
)

type CourseHandler struct {
	DB *pgxpool.Pool
}

func NewCourseHandler(db *pgxpool.Pool) *CourseHandler {
	return &CourseHandler{DB: db}
}

// CreateCourseRequest - body sent by admin after uploading files to R2
type CreateCourseRequest struct {
	Title         string        `json:"title" binding:"required"`
	Description   string        `json:"description"`
	InstructorID  string        `json:"instructor_id" binding:"required"`
	Category      string        `json:"category" binding:"required"`
	ThumbnailKey  string        `json:"thumbnail_key"` // R2 object key
	Modules       []ModuleInput `json:"modules"`
}

type ModuleInput struct {
	Title    string `json:"title" binding:"required"`
	VideoKey string `json:"video_key"`  // R2 object key for video
	PDFKey   string `json:"pdf_key"`    // R2 object key for PDF notes
	Order    int    `json:"order"`
}

// CreateCourse - saves course metadata + R2 keys to Supabase DB
func (h *CourseHandler) CreateCourse(c *gin.Context) {
	role, exists := c.Get("user_role")
	if !exists || role != "admin" {
		c.JSON(http.StatusForbidden, gin.H{"error": "Only admins can create courses"})
		return
	}

	var req CreateCourseRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	// Insert course into Supabase (postgres)
	var courseID string
	err := h.DB.QueryRow(ctx,
		`INSERT INTO courses (title, description, instructor_id, category, thumbnail_key, created_at)
		 VALUES ($1, $2, $3, $4, $5, NOW())
		 RETURNING id`,
		req.Title, req.Description, req.InstructorID, req.Category, req.ThumbnailKey,
	).Scan(&courseID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create course: " + err.Error()})
		return
	}

	// Insert modules (videos + pdf notes)
	for i, mod := range req.Modules {
		order := mod.Order
		if order == 0 {
			order = i + 1
		}
		_, err := h.DB.Exec(ctx,
			`INSERT INTO course_modules (course_id, title, video_key, pdf_key, sort_order, created_at)
			 VALUES ($1, $2, $3, $4, $5, NOW())`,
			courseID, mod.Title, mod.VideoKey, mod.PDFKey, order,
		)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to add module: " + err.Error()})
			return
		}
	}

	c.JSON(http.StatusCreated, gin.H{
		"message":   "Course created successfully",
		"course_id": courseID,
	})
}

// GetCourses - returns all courses (for student home screen)
func (h *CourseHandler) GetCourses(c *gin.Context) {
	category := c.Query("category")

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	var query string
	var args []interface{}

	if category != "" {
		query = `SELECT id, title, description, category, thumbnail_key, created_at 
		          FROM courses WHERE category = $1 ORDER BY created_at DESC`
		args = append(args, category)
	} else {
		query = `SELECT id, title, description, category, thumbnail_key, created_at 
		          FROM courses ORDER BY created_at DESC`
	}

	rows, err := h.DB.Query(ctx, query, args...)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch courses: " + err.Error()})
		return
	}
	defer rows.Close()

	type Course struct {
		ID           string    `json:"id"`
		Title        string    `json:"title"`
		Description  string    `json:"description"`
		Category     string    `json:"category"`
		ThumbnailKey string    `json:"thumbnail_key"`
		CreatedAt    time.Time `json:"created_at"`
	}

	var courses []Course
	for rows.Next() {
		var course Course
		if err := rows.Scan(&course.ID, &course.Title, &course.Description, &course.Category, &course.ThumbnailKey, &course.CreatedAt); err != nil {
			continue
		}
		courses = append(courses, course)
	}

	c.JSON(http.StatusOK, gin.H{"courses": courses})
}

// GetCourseModules - returns all video modules for a course (for video player)
func (h *CourseHandler) GetCourseModules(c *gin.Context) {
	courseID := c.Param("id")
	if courseID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "course id is required"})
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	rows, err := h.DB.Query(ctx,
		`SELECT id, title, video_key, pdf_key, sort_order FROM course_modules
		 WHERE course_id = $1 ORDER BY sort_order ASC`,
		courseID,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch modules: " + err.Error()})
		return
	}
	defer rows.Close()

	type Module struct {
		ID       string `json:"id"`
		Title    string `json:"title"`
		VideoKey string `json:"video_key"`
		PDFKey   string `json:"pdf_key"`
		Order    int    `json:"sort_order"`
	}

	var modules []Module
	for rows.Next() {
		var m Module
		if err := rows.Scan(&m.ID, &m.Title, &m.VideoKey, &m.PDFKey, &m.Order); err != nil {
			continue
		}
		modules = append(modules, m)
	}

	c.JSON(http.StatusOK, gin.H{"modules": modules})
}
