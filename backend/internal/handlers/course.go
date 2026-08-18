package handlers

import (
	"database/sql"
	"fmt"
	"net/http"
	"path/filepath"
	"strings"

	"github.com/EthioClass/backend/internal/storage"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// GetCategoriesHandler fetches all categories from the Supabase Postgres database.
func GetCategoriesHandler(db *sql.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		if db == nil {
			c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Database not connected"})
			return
		}

		rows, err := db.QueryContext(c.Request.Context(),
			`SELECT id, name, description, image_url, created_at FROM categories ORDER BY created_at ASC`)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch categories: " + err.Error()})
			return
		}
		defer rows.Close()

		type Category struct {
			ID          string  `json:"id"`
			Name        string  `json:"name"`
			Description string  `json:"description"`
			ImageURL    *string `json:"image_url"`
			CreatedAt   *string `json:"created_at"`
		}

		var categories []Category
		for rows.Next() {
			var cat Category
			var createdAt *string
			if err := rows.Scan(&cat.ID, &cat.Name, &cat.Description, &cat.ImageURL, &createdAt); err != nil {
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to parse category: " + err.Error()})
				return
			}
			if createdAt != nil {
				cat.CreatedAt = createdAt
			}
			categories = append(categories, cat)
		}

		if categories == nil {
			categories = []Category{}
		}

		c.JSON(http.StatusOK, categories)
	}
}

// GetCategoryStatsHandler returns course count, video count, quiz count, student count for a category
func GetCategoryStatsHandler(db *sql.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		if db == nil {
			c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Database not connected"})
			return
		}

		categoryID := c.Query("category_id")
		if categoryID == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "category_id is required"})
			return
		}

		type Stats struct {
			CourseCount  int `json:"course_count"`
			VideoCount   int `json:"video_count"`
			QuizCount    int `json:"quiz_count"`
			StudentCount int `json:"student_count"`
		}

		var stats Stats

		// Count courses in this category
		err := db.QueryRowContext(c.Request.Context(),
			`SELECT COUNT(*) FROM courses WHERE category_id = $1`, categoryID).Scan(&stats.CourseCount)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to count courses: " + err.Error()})
			return
		}

		// Count videos (lessons with a video_url) under courses in this category
		err = db.QueryRowContext(c.Request.Context(),
			`SELECT COUNT(l.id) FROM lessons l
			 JOIN chapters ch ON l.chapter_id = ch.id
			 JOIN courses co ON ch.course_id = co.id
			 WHERE co.category_id = $1 AND l.video_url IS NOT NULL AND l.video_url != ''`, categoryID).Scan(&stats.VideoCount)
		if err != nil {
			stats.VideoCount = 0
		}

		// Count quiz questions under courses in this category
		err = db.QueryRowContext(c.Request.Context(),
			`SELECT COUNT(q.id) FROM quizzes q
			 JOIN lessons l ON q.lesson_id = l.id
			 JOIN chapters ch ON l.chapter_id = ch.id
			 JOIN courses co ON ch.course_id = co.id
			 WHERE co.category_id = $1`, categoryID).Scan(&stats.QuizCount)
		if err != nil {
			stats.QuizCount = 0
		}

		// Count enrolled students (users who have enrolled in courses in this category)
		err = db.QueryRowContext(c.Request.Context(),
			`SELECT COUNT(DISTINCT u.id) FROM users u
			 JOIN payments p ON p.user_id = u.id
			 JOIN courses co ON p.course_id = co.id
			 WHERE co.category_id = $1 AND p.status = 'success'`, categoryID).Scan(&stats.StudentCount)
		if err != nil {
			stats.StudentCount = 0
		}

		c.JSON(http.StatusOK, stats)
	}
}

// CreateCategoryHandler handles POST requests to create a new category with an image upload.
func CreateCategoryHandler(db *sql.DB, r2 *storage.R2Client) gin.HandlerFunc {
	return func(c *gin.Context) {
		if db == nil {
			c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Database not connected"})
			return
		}

		// Require multipart form processing
		if err := c.Request.ParseMultipartForm(10 << 20); err != nil { // 10 MB limit
			c.JSON(http.StatusBadRequest, gin.H{"error": "Failed to parse multipart form"})
			return
		}

		name := c.Request.FormValue("name")
		description := c.Request.FormValue("description")

		if strings.TrimSpace(name) == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Category name is required"})
			return
		}

		file, header, err := c.Request.FormFile("image")
		var imageURL *string

		// Handle optional image upload
		if err == nil {
			defer file.Close()
			
			if r2 == nil {
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Cloudflare R2 is not configured"})
				return
			}

			// Generate a unique object key for R2
			ext := filepath.Ext(header.Filename)
			if ext == "" {
				ext = ".png" // Fallback extension
			}
			key := fmt.Sprintf("categories/%s%s", uuid.New().String(), ext)
			contentType := header.Header.Get("Content-Type")

			// Upload to R2
			uploadedKey, uploadErr := r2.UploadFile(c.Request.Context(), file, key, contentType)
			if uploadErr != nil {
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to upload image: " + uploadErr.Error()})
				return
			}
			
			imageURL = &uploadedKey
		} else if err != http.ErrMissingFile {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Error reading image file: " + err.Error()})
			return
		}

		// Insert into the database
		var categoryID string
		err = db.QueryRowContext(c.Request.Context(),
			`INSERT INTO categories (name, description, image_url) VALUES ($1, $2, $3) RETURNING id`,
			name, description, imageURL,
		).Scan(&categoryID)
		
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to save category to database: " + err.Error()})
			return
		}

		c.JSON(http.StatusCreated, gin.H{
			"message": "Category created successfully",
			"id": categoryID,
			"image_url": imageURL,
		})
	}
}

// UpdateCategoryHandler handles PUT requests to update an existing category.
func UpdateCategoryHandler(db *sql.DB, r2 *storage.R2Client) gin.HandlerFunc {
	return func(c *gin.Context) {
		if db == nil {
			c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Database not connected"})
			return
		}

		categoryID := c.Param("id")
		if categoryID == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Category ID is required"})
			return
		}

		// Parse multipart form
		if err := c.Request.ParseMultipartForm(10 << 20); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Failed to parse multipart form"})
			return
		}

		name := c.Request.FormValue("name")
		description := c.Request.FormValue("description")

		if strings.TrimSpace(name) == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Category name is required"})
			return
		}

		// Check if a new image was uploaded
		file, header, err := c.Request.FormFile("image")
		var newImageURL *string

		if err == nil {
			defer file.Close()
			if r2 == nil {
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Cloudflare R2 is not configured"})
				return
			}

			ext := filepath.Ext(header.Filename)
			if ext == "" {
				ext = ".png"
			}
			key := fmt.Sprintf("categories/%s%s", uuid.New().String(), ext)
			contentType := header.Header.Get("Content-Type")

			uploadedKey, uploadErr := r2.UploadFile(c.Request.Context(), file, key, contentType)
			if uploadErr != nil {
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to upload new image: " + uploadErr.Error()})
				return
			}
			newImageURL = &uploadedKey
		} else if err != http.ErrMissingFile {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Error reading image file: " + err.Error()})
			return
		}

		// Update database
		if newImageURL != nil {
			_, err = db.ExecContext(c.Request.Context(),
				`UPDATE categories SET name = $1, description = $2, image_url = $3 WHERE id = $4`,
				name, description, newImageURL, categoryID,
			)
		} else {
			_, err = db.ExecContext(c.Request.Context(),
				`UPDATE categories SET name = $1, description = $2 WHERE id = $3`,
				name, description, categoryID,
			)
		}

		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update category: " + err.Error()})
			return
		}

		c.JSON(http.StatusOK, gin.H{
			"message": "Category updated successfully",
			"image_url": newImageURL,
		})
	}
}

// DeleteCategoryHandler handles DELETE requests to remove a category.
func DeleteCategoryHandler(db *sql.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		if db == nil {
			c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Database not connected"})
			return
		}

		categoryID := c.Param("id")
		if categoryID == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Category ID is required"})
			return
		}

		_, err := db.ExecContext(c.Request.Context(), `DELETE FROM categories WHERE id = $1`, categoryID)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete category: " + err.Error()})
			return
		}

		c.JSON(http.StatusOK, gin.H{"message": "Category deleted successfully"})
	}
}

// GetDivisionsHandler fetches divisions, optionally filtered by category_id
func GetDivisionsHandler(db *sql.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		if db == nil {
			c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Database not connected"})
			return
		}

		categoryId := c.Query("category_id")
		var rows *sql.Rows
		var err error

		if categoryId != "" {
			rows, err = db.QueryContext(c.Request.Context(),
				`SELECT id, category_id, name, image_url, created_at FROM divisions WHERE category_id = $1 ORDER BY created_at ASC`, categoryId)
		} else {
			rows, err = db.QueryContext(c.Request.Context(),
				`SELECT id, category_id, name, image_url, created_at FROM divisions ORDER BY created_at ASC`)
		}

		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch divisions: " + err.Error()})
			return
		}
		defer rows.Close()

		type Division struct {
			ID         string  `json:"id"`
			CategoryID string  `json:"category_id"`
			Name       string  `json:"name"`
			ImageURL   *string `json:"image_url"`
			CreatedAt  *string `json:"created_at"`
		}

		var divisions []Division
		for rows.Next() {
			var div Division
			if err := rows.Scan(&div.ID, &div.CategoryID, &div.Name, &div.ImageURL, &div.CreatedAt); err != nil {
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to parse division: " + err.Error()})
				return
			}
			divisions = append(divisions, div)
		}

		if divisions == nil {
			divisions = []Division{}
		}

		c.JSON(http.StatusOK, divisions)
	}
}

// GetCoursesHandler fetches courses, optionally filtered by category_id
func GetCoursesHandler(db *sql.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		if db == nil {
			c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Database not connected"})
			return
		}

		categoryId := c.Query("category_id")
		var rows *sql.Rows
		var err error



		if categoryId != "" {
			rows, err = db.QueryContext(c.Request.Context(), `
				SELECT 
					c.id, c.category_id, cat.name as category_name, c.title, c.description, 
					c.about_text, c.about_bullets, c.instructor_name, c.instructor_phone, c.thumbnail_url, c.created_at,
					COALESCE((SELECT COUNT(*) FROM lessons l JOIN chapters ch ON l.chapter_id = ch.id WHERE ch.course_id = c.id), 0) as lesson_count,
					COALESCE((SELECT SUM(l.duration_minutes) FROM lessons l JOIN chapters ch ON l.chapter_id = ch.id WHERE ch.course_id = c.id), 0) as duration_minutes,
					0 as student_count
				FROM courses c
				LEFT JOIN categories cat ON c.category_id = cat.id
				WHERE c.category_id = $1 ORDER BY c.created_at DESC`, categoryId)
		} else {
			rows, err = db.QueryContext(c.Request.Context(), `
				SELECT 
					c.id, c.category_id, cat.name as category_name, c.title, c.description, 
					c.about_text, c.about_bullets, c.instructor_name, c.instructor_phone, c.thumbnail_url, c.created_at,
					COALESCE((SELECT COUNT(*) FROM lessons l JOIN chapters ch ON l.chapter_id = ch.id WHERE ch.course_id = c.id), 0) as lesson_count,
					COALESCE((SELECT SUM(l.duration_minutes) FROM lessons l JOIN chapters ch ON l.chapter_id = ch.id WHERE ch.course_id = c.id), 0) as duration_minutes,
					0 as student_count
				FROM courses c
				LEFT JOIN categories cat ON c.category_id = cat.id
				ORDER BY c.created_at DESC`)
		}

		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch courses: " + err.Error()})
			return
		}
		defer rows.Close()

		type Course struct {
			ID              string  `json:"id"`
			CategoryID      *string `json:"category_id"`
			CategoryName    *string `json:"category_name"`
			Title           string  `json:"title"`
			Description     string  `json:"description"`
			AboutText       *string `json:"about_text"`
			AboutBullets    *string `json:"about_bullets"` // JSON string
			InstructorName  *string `json:"instructor_name"`
			InstructorPhone *string `json:"instructor_phone"`
			ThumbnailURL    *string `json:"thumbnail_url"`
			CreatedAt       *string `json:"created_at"`
			LessonCount     int     `json:"lesson_count"`
			DurationMinutes int     `json:"duration_minutes"`
			StudentCount    int     `json:"student_count"`
		}

		var courses []Course
		for rows.Next() {
			var course Course
			if err := rows.Scan(
				&course.ID, &course.CategoryID, &course.CategoryName, &course.Title, &course.Description, 
				&course.AboutText, &course.AboutBullets, &course.InstructorName, &course.InstructorPhone, &course.ThumbnailURL, &course.CreatedAt,
				&course.LessonCount, &course.DurationMinutes, &course.StudentCount,
			); err != nil {
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to parse course: " + err.Error()})
				return
			}
			courses = append(courses, course)
		}

		if courses == nil {
			courses = []Course{}
		}

		c.JSON(http.StatusOK, courses)
	}
}



// GetLessonMaterialsHandler fetches materials for a specific lesson
func GetLessonMaterialsHandler(db *sql.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		if db == nil {
			c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Database not connected"})
			return
		}

		lessonId := c.Query("lesson_id")
		if lessonId == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "lesson_id query parameter is required"})
			return
		}

		rows, err := db.QueryContext(c.Request.Context(),
			`SELECT id, lesson_id, video_url, video_thumbnail_url, notes_content, notes_thumbnail_url, created_at FROM lesson_materials WHERE lesson_id = $1 ORDER BY created_at ASC`, lessonId)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch lesson materials: " + err.Error()})
			return
		}
		defer rows.Close()

		type LessonMaterial struct {
			ID                string  `json:"id"`
			LessonID          string  `json:"lesson_id"`
			VideoURL          *string `json:"video_url"`
			VideoThumbnailURL *string `json:"video_thumbnail_url"`
			NotesContent      *string `json:"notes_content"`
			NotesThumbnailURL *string `json:"notes_thumbnail_url"`
			CreatedAt         *string `json:"created_at"`
		}

		var materials []LessonMaterial
		for rows.Next() {
			var mat LessonMaterial
			if err := rows.Scan(&mat.ID, &mat.LessonID, &mat.VideoURL, &mat.VideoThumbnailURL, &mat.NotesContent, &mat.NotesThumbnailURL, &mat.CreatedAt); err != nil {
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to parse lesson material: " + err.Error()})
				return
			}
			materials = append(materials, mat)
		}

		if materials == nil {
			materials = []LessonMaterial{}
		}

		c.JSON(http.StatusOK, materials)
	}
}

// GetQuestionsHandler fetches questions for a specific lesson
func GetQuestionsHandler(db *sql.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		if db == nil {
			c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Database not connected"})
			return
		}

		lessonId := c.Query("lesson_id")
		if lessonId == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "lesson_id query parameter is required"})
			return
		}

		rows, err := db.QueryContext(c.Request.Context(),
			`SELECT id, lesson_id, question_text, question_image_url, options, correct_option_index, explanation, created_at FROM questions WHERE lesson_id = $1 ORDER BY created_at ASC`, lessonId)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch questions: " + err.Error()})
			return
		}
		defer rows.Close()

		type Question struct {
			ID                 string  `json:"id"`
			LessonID           string  `json:"lesson_id"`
			QuestionText       string  `json:"question_text"`
			QuestionImageURL   *string `json:"question_image_url"`
			Options            string  `json:"options"` // JSONB from postgres maps to string
			CorrectOptionIndex int     `json:"correct_option_index"`
			Explanation        *string `json:"explanation"`
			CreatedAt          *string `json:"created_at"`
		}

		var questions []Question
		for rows.Next() {
			var q Question
			if err := rows.Scan(&q.ID, &q.LessonID, &q.QuestionText, &q.QuestionImageURL, &q.Options, &q.CorrectOptionIndex, &q.Explanation, &q.CreatedAt); err != nil {
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to parse question: " + err.Error()})
				return
			}
			questions = append(questions, q)
		}

		if questions == nil {
			questions = []Question{}
		}

		c.JSON(http.StatusOK, questions)
	}
}

// CreateCourseHandler handles POST requests to create a new course.
func CreateCourseHandler(db *sql.DB, r2 *storage.R2Client) gin.HandlerFunc {
	return func(c *gin.Context) {
		if db == nil {
			c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Database not connected"})
			return
		}

		if err := c.Request.ParseMultipartForm(10 << 20); err != nil { // 10 MB limit
			c.JSON(http.StatusBadRequest, gin.H{"error": "Failed to parse multipart form"})
			return
		}

		categoryID := c.Request.FormValue("category_id")
		title := c.Request.FormValue("title")
		description := c.Request.FormValue("description")
		aboutText := c.Request.FormValue("about_text")
		aboutBullets := c.Request.FormValue("about_bullets") // JSON array string
		instructorName := c.Request.FormValue("instructor_name")
		instructorPhone := c.Request.FormValue("instructor_phone")

		if strings.TrimSpace(title) == "" || strings.TrimSpace(categoryID) == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Category ID and Title are required"})
			return
		}

		if aboutBullets == "" {
			aboutBullets = "[]"
		}

		file, header, err := c.Request.FormFile("image")
		var thumbnailURL *string

		if err == nil {
			defer file.Close()
			if r2 == nil {
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Cloudflare R2 is not configured"})
				return
			}
			ext := filepath.Ext(header.Filename)
			if ext == "" {
				ext = ".png"
			}
			key := fmt.Sprintf("courses/%s%s", uuid.New().String(), ext)
			contentType := header.Header.Get("Content-Type")

			uploadedKey, uploadErr := r2.UploadFile(c.Request.Context(), file, key, contentType)
			if uploadErr != nil {
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to upload image: " + uploadErr.Error()})
				return
			}
			thumbnailURL = &uploadedKey
		} else if err != http.ErrMissingFile {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Error reading image file: " + err.Error()})
			return
		}

		var courseID string
		err = db.QueryRowContext(c.Request.Context(),
			`INSERT INTO courses (category_id, title, description, about_text, about_bullets, instructor_name, instructor_phone, thumbnail_url) 
			 VALUES ($1, $2, $3, $4, $5, $6, $7, $8) RETURNING id`,
			categoryID, title, description, aboutText, aboutBullets, instructorName, instructorPhone, thumbnailURL,
		).Scan(&courseID)
		
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to save course: " + err.Error()})
			return
		}

		c.JSON(http.StatusCreated, gin.H{
			"message": "Course created successfully",
			"id": courseID,
			"thumbnail_url": thumbnailURL,
		})
	}
}

// UpdateCourseHandler handles PUT requests to update a course.
func UpdateCourseHandler(db *sql.DB, r2 *storage.R2Client) gin.HandlerFunc {
	return func(c *gin.Context) {
		if db == nil {
			c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Database not connected"})
			return
		}

		courseID := c.Param("id")
		if courseID == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Course ID is required"})
			return
		}

		if err := c.Request.ParseMultipartForm(10 << 20); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Failed to parse form"})
			return
		}

		categoryID := c.Request.FormValue("category_id")
		title := c.Request.FormValue("title")
		description := c.Request.FormValue("description")
		aboutText := c.Request.FormValue("about_text")
		aboutBullets := c.Request.FormValue("about_bullets")
		instructorName := c.Request.FormValue("instructor_name")
		instructorPhone := c.Request.FormValue("instructor_phone")

		if strings.TrimSpace(title) == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Title is required"})
			return
		}

		if aboutBullets == "" {
			aboutBullets = "[]"
		}

		file, header, err := c.Request.FormFile("image")
		var newThumbnailURL *string

		if err == nil {
			defer file.Close()
			if r2 == nil {
				c.JSON(http.StatusInternalServerError, gin.H{"error": "R2 not configured"})
				return
			}
			ext := filepath.Ext(header.Filename)
			if ext == "" {
				ext = ".png"
			}
			key := fmt.Sprintf("courses/%s%s", uuid.New().String(), ext)
			contentType := header.Header.Get("Content-Type")

			uploadedKey, uploadErr := r2.UploadFile(c.Request.Context(), file, key, contentType)
			if uploadErr != nil {
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Upload failed: " + uploadErr.Error()})
				return
			}
			newThumbnailURL = &uploadedKey
		}

		if newThumbnailURL != nil {
			_, err = db.ExecContext(c.Request.Context(),
				`UPDATE courses SET category_id = $1, title = $2, description = $3, about_text = $4, about_bullets = $5, instructor_name = $6, instructor_phone = $7, thumbnail_url = $8 WHERE id = $9`,
				categoryID, title, description, aboutText, aboutBullets, instructorName, instructorPhone, newThumbnailURL, courseID,
			)
		} else {
			_, err = db.ExecContext(c.Request.Context(),
				`UPDATE courses SET category_id = $1, title = $2, description = $3, about_text = $4, about_bullets = $5, instructor_name = $6, instructor_phone = $7 WHERE id = $8`,
				categoryID, title, description, aboutText, aboutBullets, instructorName, instructorPhone, courseID,
			)
		}

		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update course: " + err.Error()})
			return
		}

		c.JSON(http.StatusOK, gin.H{"message": "Course updated successfully", "thumbnail_url": newThumbnailURL})
	}
}

// DeleteCourseHandler handles DELETE requests to remove a course.
func DeleteCourseHandler(db *sql.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		if db == nil {
			c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Database not connected"})
			return
		}

		courseID := c.Param("id")
		if courseID == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Course ID is required"})
			return
		}

		_, err := db.ExecContext(c.Request.Context(), `DELETE FROM courses WHERE id = $1`, courseID)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete course: " + err.Error()})
			return
		}

		c.JSON(http.StatusOK, gin.H{"message": "Course deleted successfully"})
	}
}
