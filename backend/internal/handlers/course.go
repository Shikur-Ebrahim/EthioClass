package handlers

import (
	"database/sql"
	"net/http"

	"github.com/gin-gonic/gin"
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

// GetCoursesHandler fetches courses, optionally filtered by division_id
func GetCoursesHandler(db *sql.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		if db == nil {
			c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Database not connected"})
			return
		}

		divisionId := c.Query("division_id")
		var rows *sql.Rows
		var err error

		if divisionId != "" {
			rows, err = db.QueryContext(c.Request.Context(),
				`SELECT id, division_id, title, description, thumbnail_url, created_at FROM courses WHERE division_id = $1 ORDER BY created_at DESC`, divisionId)
		} else {
			rows, err = db.QueryContext(c.Request.Context(),
				`SELECT id, division_id, title, description, thumbnail_url, created_at FROM courses ORDER BY created_at DESC`)
		}

		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch courses: " + err.Error()})
			return
		}
		defer rows.Close()

		type Course struct {
			ID           string  `json:"id"`
			DivisionID   *string `json:"division_id"`
			Title        string  `json:"title"`
			Description  string  `json:"description"`
			ThumbnailURL *string `json:"thumbnail_url"`
			CreatedAt    *string `json:"created_at"`
		}

		var courses []Course
		for rows.Next() {
			var course Course
			if err := rows.Scan(&course.ID, &course.DivisionID, &course.Title, &course.Description, &course.ThumbnailURL, &course.CreatedAt); err != nil {
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

// GetLessonsHandler fetches lessons for a specific course
func GetLessonsHandler(db *sql.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		if db == nil {
			c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Database not connected"})
			return
		}

		courseId := c.Query("course_id")
		if courseId == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "course_id query parameter is required"})
			return
		}

		rows, err := db.QueryContext(c.Request.Context(),
			`SELECT id, course_id, title, thumbnail_url, order_index, created_at FROM lessons WHERE course_id = $1 ORDER BY order_index ASC`, courseId)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch lessons: " + err.Error()})
			return
		}
		defer rows.Close()

		type Lesson struct {
			ID           string  `json:"id"`
			CourseID     string  `json:"course_id"`
			Title        string  `json:"title"`
			ThumbnailURL *string `json:"thumbnail_url"`
			OrderIndex   int     `json:"order_index"`
			CreatedAt    *string `json:"created_at"`
		}

		var lessons []Lesson
		for rows.Next() {
			var lesson Lesson
			if err := rows.Scan(&lesson.ID, &lesson.CourseID, &lesson.Title, &lesson.ThumbnailURL, &lesson.OrderIndex, &lesson.CreatedAt); err != nil {
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to parse lesson: " + err.Error()})
				return
			}
			lessons = append(lessons, lesson)
		}

		if lessons == nil {
			lessons = []Lesson{}
		}

		c.JSON(http.StatusOK, lessons)
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
