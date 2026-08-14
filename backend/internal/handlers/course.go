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

// GetCoursesHandler fetches all courses from the Supabase Postgres database.
func GetCoursesHandler(db *sql.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		if db == nil {
			c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Database not connected"})
			return
		}

		rows, err := db.QueryContext(c.Request.Context(),
			`SELECT id, division_id, title, description, thumbnail_url, created_at FROM courses ORDER BY created_at DESC`)
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
