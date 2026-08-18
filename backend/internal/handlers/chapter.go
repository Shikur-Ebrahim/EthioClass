package handlers

import (
	"database/sql"
	"fmt"
	"net/http"
	"path/filepath"
	"strconv"
	"strings"

	"github.com/EthioClass/backend/internal/storage"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// GetChaptersHandler fetches chapters for a specific course
func GetChaptersHandler(db *sql.DB) gin.HandlerFunc {
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
			`SELECT id, course_id, title, description, thumbnail_url, chapter_number, is_free, created_at FROM chapters WHERE course_id = $1 ORDER BY chapter_number ASC, created_at ASC`, courseId)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch chapters: " + err.Error()})
			return
		}
		defer rows.Close()

		type Chapter struct {
			ID            string  `json:"id"`
			CourseID      string  `json:"course_id"`
			Title         string  `json:"title"`
			Description   *string `json:"description"`
			ThumbnailURL  *string `json:"thumbnail_url"`
			ChapterNumber int     `json:"chapter_number"`
			IsFree        bool    `json:"is_free"`
			CreatedAt     *string `json:"created_at"`
		}

		var chapters []Chapter
		for rows.Next() {
			var chapter Chapter
			if err := rows.Scan(&chapter.ID, &chapter.CourseID, &chapter.Title, &chapter.Description, &chapter.ThumbnailURL, &chapter.ChapterNumber, &chapter.IsFree, &chapter.CreatedAt); err != nil {
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to parse chapter: " + err.Error()})
				return
			}
			chapters = append(chapters, chapter)
		}

		if chapters == nil {
			chapters = []Chapter{}
		}

		c.JSON(http.StatusOK, chapters)
	}
}

// CreateChapterHandler handles POST requests to create a new chapter.
func CreateChapterHandler(db *sql.DB, r2 *storage.R2Client) gin.HandlerFunc {
	return func(c *gin.Context) {
		if db == nil {
			c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Database not connected"})
			return
		}

		if err := c.Request.ParseMultipartForm(10 << 20); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Failed to parse form"})
			return
		}

		courseID := c.Request.FormValue("course_id")
		title := c.Request.FormValue("title")
		description := c.Request.FormValue("description")
		
		chapterNumber, _ := strconv.Atoi(c.Request.FormValue("chapter_number"))
		if chapterNumber == 0 {
			chapterNumber = 1
		}
		
		isFree := c.Request.FormValue("is_free") == "true"

		if strings.TrimSpace(title) == "" || strings.TrimSpace(courseID) == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Course ID and Title are required"})
			return
		}

		file, header, err := c.Request.FormFile("image")
		var thumbnailURL *string

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
			key := fmt.Sprintf("chapters/%s%s", uuid.New().String(), ext)
			contentType := header.Header.Get("Content-Type")

			uploadedKey, uploadErr := r2.UploadFile(c.Request.Context(), file, key, contentType)
			if uploadErr != nil {
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to upload image: " + uploadErr.Error()})
				return
			}
			thumbnailURL = &uploadedKey
		}

		var chapterID string
		err = db.QueryRowContext(c.Request.Context(),
			`INSERT INTO chapters (course_id, title, description, thumbnail_url, chapter_number, is_free) 
			 VALUES ($1, $2, $3, $4, $5, $6) RETURNING id`,
			courseID, title, description, thumbnailURL, chapterNumber, isFree,
		).Scan(&chapterID)
		
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to save chapter: " + err.Error()})
			return
		}

		c.JSON(http.StatusCreated, gin.H{
			"message": "Chapter created successfully",
			"id": chapterID,
			"thumbnail_url": thumbnailURL,
		})
	}
}

// UpdateChapterHandler handles PUT requests to update a chapter.
func UpdateChapterHandler(db *sql.DB, r2 *storage.R2Client) gin.HandlerFunc {
	return func(c *gin.Context) {
		if db == nil {
			c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Database not connected"})
			return
		}

		chapterID := c.Param("id")
		if chapterID == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Chapter ID is required"})
			return
		}

		if err := c.Request.ParseMultipartForm(10 << 20); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Failed to parse form"})
			return
		}

		courseID := c.Request.FormValue("course_id")
		title := c.Request.FormValue("title")
		description := c.Request.FormValue("description")
		
		chapterNumber, _ := strconv.Atoi(c.Request.FormValue("chapter_number"))
		isFree := c.Request.FormValue("is_free") == "true"

		if strings.TrimSpace(title) == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Title is required"})
			return
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
			key := fmt.Sprintf("chapters/%s%s", uuid.New().String(), ext)
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
				`UPDATE chapters SET course_id = $1, title = $2, description = $3, thumbnail_url = $4, chapter_number = $5, is_free = $6 WHERE id = $7`,
				courseID, title, description, newThumbnailURL, chapterNumber, isFree, chapterID,
			)
		} else {
			_, err = db.ExecContext(c.Request.Context(),
				`UPDATE chapters SET course_id = $1, title = $2, description = $3, chapter_number = $4, is_free = $5 WHERE id = $6`,
				courseID, title, description, chapterNumber, isFree, chapterID,
			)
		}

		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update chapter: " + err.Error()})
			return
		}

		c.JSON(http.StatusOK, gin.H{"message": "Chapter updated successfully", "thumbnail_url": newThumbnailURL})
	}
}

// DeleteChapterHandler handles DELETE requests to remove a chapter.
func DeleteChapterHandler(db *sql.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		if db == nil {
			c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Database not connected"})
			return
		}

		chapterID := c.Param("id")
		if chapterID == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Chapter ID is required"})
			return
		}

		_, err := db.ExecContext(c.Request.Context(), `DELETE FROM chapters WHERE id = $1`, chapterID)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete chapter: " + err.Error()})
			return
		}

		c.JSON(http.StatusOK, gin.H{"message": "Chapter deleted successfully"})
	}
}
