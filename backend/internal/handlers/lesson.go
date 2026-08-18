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

type LessonRow struct {
	ID              string  `json:"id"`
	ChapterID       string  `json:"chapter_id"`
	CourseID        string  `json:"course_id"`
	Title           string  `json:"title"`
	ThumbnailURL    *string `json:"thumbnail_url"`
	VideoURL        *string `json:"video_url"`
	NotesURL        *string `json:"notes_url"`
	LessonNumber    int     `json:"lesson_number"`
	DurationMinutes int     `json:"duration_minutes"`
	IsFree          bool    `json:"is_free"`
	CreatedAt       *string `json:"created_at"`
}

// GetLessonsHandler fetches lessons for a specific chapter
func GetLessonsHandler(db *sql.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		if db == nil {
			c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Database not connected"})
			return
		}

		chapterId := c.Query("chapter_id")
		courseId := c.Query("course_id")

		var rows *sql.Rows
		var err error

		if chapterId != "" {
			rows, err = db.QueryContext(c.Request.Context(),
				`SELECT id, chapter_id, course_id, title, thumbnail_url, video_url, notes_url, lesson_number, duration_minutes, is_free, created_at 
				 FROM lessons WHERE chapter_id = $1 ORDER BY lesson_number ASC, created_at ASC`, chapterId)
		} else if courseId != "" {
			rows, err = db.QueryContext(c.Request.Context(),
				`SELECT id, chapter_id, course_id, title, thumbnail_url, video_url, notes_url, lesson_number, duration_minutes, is_free, created_at 
				 FROM lessons WHERE course_id = $1 ORDER BY lesson_number ASC`, courseId)
		} else {
			c.JSON(http.StatusBadRequest, gin.H{"error": "chapter_id or course_id is required"})
			return
		}

		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch lessons: " + err.Error()})
			return
		}
		defer rows.Close()

		var lessons []LessonRow
		for rows.Next() {
			var l LessonRow
			if err := rows.Scan(&l.ID, &l.ChapterID, &l.CourseID, &l.Title, &l.ThumbnailURL, &l.VideoURL, &l.NotesURL, &l.LessonNumber, &l.DurationMinutes, &l.IsFree, &l.CreatedAt); err != nil {
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Parse error: " + err.Error()})
				return
			}
			lessons = append(lessons, l)
		}
		if lessons == nil {
			lessons = []LessonRow{}
		}
		c.JSON(http.StatusOK, lessons)
	}
}

// CreateLessonHandler handles POST /admin/lessons
func CreateLessonHandler(db *sql.DB, r2 *storage.R2Client) gin.HandlerFunc {
	return func(c *gin.Context) {
		if db == nil {
			c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Database not connected"})
			return
		}
		if err := c.Request.ParseMultipartForm(100 << 20); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Failed to parse form"})
			return
		}

		chapterID := strings.TrimSpace(c.Request.FormValue("chapter_id"))
		courseID := strings.TrimSpace(c.Request.FormValue("course_id"))
		title := strings.TrimSpace(c.Request.FormValue("title"))
		lessonNumber, _ := strconv.Atoi(c.Request.FormValue("lesson_number"))
		durationMinutes, _ := strconv.Atoi(c.Request.FormValue("duration_minutes"))
		isFree := c.Request.FormValue("is_free") == "true"

		if chapterID == "" || courseID == "" || title == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "chapter_id, course_id, and title are required"})
			return
		}

		var thumbnailURL, videoURL, notesURL *string

		// Upload thumbnail
		if file, header, err := c.Request.FormFile("thumbnail"); err == nil {
			defer file.Close()
			ext := filepath.Ext(header.Filename)
			if ext == "" { ext = ".jpg" }
			key := fmt.Sprintf("lessons/thumbnails/%s%s", uuid.New().String(), ext)
			uploaded, err := r2.UploadFile(c.Request.Context(), file, key, header.Header.Get("Content-Type"))
			if err == nil {
				thumbnailURL = &uploaded
			}
		}

		// Upload video
		if file, header, err := c.Request.FormFile("video"); err == nil {
			defer file.Close()
			ext := filepath.Ext(header.Filename)
			if ext == "" { ext = ".mp4" }
			key := fmt.Sprintf("lessons/videos/%s%s", uuid.New().String(), ext)
			uploaded, err := r2.UploadFile(c.Request.Context(), file, key, header.Header.Get("Content-Type"))
			if err == nil {
				videoURL = &uploaded
			}
		}

		// Upload notes (PDF/PPT)
		if file, header, err := c.Request.FormFile("notes"); err == nil {
			defer file.Close()
			ext := filepath.Ext(header.Filename)
			if ext == "" { ext = ".pdf" }
			key := fmt.Sprintf("lessons/notes/%s%s", uuid.New().String(), ext)
			uploaded, err := r2.UploadFile(c.Request.Context(), file, key, header.Header.Get("Content-Type"))
			if err == nil {
				notesURL = &uploaded
			}
		}

		var lessonID string
		err := db.QueryRowContext(c.Request.Context(),
			`INSERT INTO lessons (chapter_id, course_id, title, thumbnail_url, video_url, notes_url, lesson_number, duration_minutes, is_free)
			 VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9) RETURNING id`,
			chapterID, courseID, title, thumbnailURL, videoURL, notesURL, lessonNumber, durationMinutes, isFree,
		).Scan(&lessonID)

		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to save lesson: " + err.Error()})
			return
		}
		c.JSON(http.StatusCreated, gin.H{"message": "Lesson created", "id": lessonID})
	}
}

// UpdateLessonHandler handles PUT /admin/lessons/:id
func UpdateLessonHandler(db *sql.DB, r2 *storage.R2Client) gin.HandlerFunc {
	return func(c *gin.Context) {
		if db == nil {
			c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Database not connected"})
			return
		}
		lessonID := c.Param("id")
		if err := c.Request.ParseMultipartForm(100 << 20); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Failed to parse form"})
			return
		}

		title := strings.TrimSpace(c.Request.FormValue("title"))
		lessonNumber, _ := strconv.Atoi(c.Request.FormValue("lesson_number"))
		durationMinutes, _ := strconv.Atoi(c.Request.FormValue("duration_minutes"))
		isFree := c.Request.FormValue("is_free") == "true"

		// Fetch existing URLs
		var existingThumb, existingVideo, existingNotes *string
		_ = db.QueryRowContext(c.Request.Context(),
			`SELECT thumbnail_url, video_url, notes_url FROM lessons WHERE id = $1`, lessonID,
		).Scan(&existingThumb, &existingVideo, &existingNotes)

		thumbnailURL := existingThumb
		videoURL := existingVideo
		notesURL := existingNotes

		// Upload new thumbnail if provided
		if file, header, err := c.Request.FormFile("thumbnail"); err == nil {
			defer file.Close()
			ext := filepath.Ext(header.Filename)
			if ext == "" { ext = ".jpg" }
			key := fmt.Sprintf("lessons/thumbnails/%s%s", uuid.New().String(), ext)
			uploaded, err := r2.UploadFile(c.Request.Context(), file, key, header.Header.Get("Content-Type"))
			if err == nil { thumbnailURL = &uploaded }
		}

		// Upload new video if provided
		if file, header, err := c.Request.FormFile("video"); err == nil {
			defer file.Close()
			ext := filepath.Ext(header.Filename)
			if ext == "" { ext = ".mp4" }
			key := fmt.Sprintf("lessons/videos/%s%s", uuid.New().String(), ext)
			uploaded, err := r2.UploadFile(c.Request.Context(), file, key, header.Header.Get("Content-Type"))
			if err == nil { videoURL = &uploaded }
		}

		// Upload new notes if provided
		if file, header, err := c.Request.FormFile("notes"); err == nil {
			defer file.Close()
			ext := filepath.Ext(header.Filename)
			if ext == "" { ext = ".pdf" }
			key := fmt.Sprintf("lessons/notes/%s%s", uuid.New().String(), ext)
			uploaded, err := r2.UploadFile(c.Request.Context(), file, key, header.Header.Get("Content-Type"))
			if err == nil { notesURL = &uploaded }
		}

		_, err := db.ExecContext(c.Request.Context(),
			`UPDATE lessons SET title = $1, thumbnail_url = $2, video_url = $3, notes_url = $4, lesson_number = $5, duration_minutes = $6, is_free = $7 WHERE id = $8`,
			title, thumbnailURL, videoURL, notesURL, lessonNumber, durationMinutes, isFree, lessonID,
		)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update: " + err.Error()})
			return
		}
		c.JSON(http.StatusOK, gin.H{"message": "Lesson updated"})
	}
}

// DeleteLessonHandler handles DELETE /admin/lessons/:id
func DeleteLessonHandler(db *sql.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		if db == nil {
			c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Database not connected"})
			return
		}
		lessonID := c.Param("id")
		_, err := db.ExecContext(c.Request.Context(), `DELETE FROM lessons WHERE id = $1`, lessonID)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete: " + err.Error()})
			return
		}
		c.JSON(http.StatusOK, gin.H{"message": "Lesson deleted"})
	}
}
