package handlers

import (
	"database/sql"
	"net/http"

	"github.com/gin-gonic/gin"
)

// GetMyLearningHandler returns unlocked courses + bookmarked courses + real progress for a user
func GetMyLearningHandler(db *sql.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		if db == nil {
			c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Database not connected"})
			return
		}

		userID := c.Query("user_id")
		if userID == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "user_id is required"})
			return
		}

		// ─── In Progress + Completed (unlocked/paid courses only) ──────────
		enrolledRows, err := db.QueryContext(c.Request.Context(), `
			SELECT
				c.id,
				c.title,
				c.thumbnail_url,
				c.instructor_name,
				c.lesson_count,
				(
					SELECT COUNT(*) FROM lesson_progress lp
					WHERE lp.user_id = $1 AND lp.course_id = c.id AND lp.completed = true
				) AS completed_lessons,
				(
					SELECT MAX(lp.last_accessed_at) FROM lesson_progress lp
					WHERE lp.user_id = $1 AND lp.course_id = c.id
				) AS last_accessed_at,
				uc.unlocked_at::text
			FROM user_courses uc
			JOIN courses c ON c.id = uc.course_id
			WHERE uc.user_id = $1
			ORDER BY last_accessed_at DESC NULLS LAST
		`, userID)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch enrolled courses: " + err.Error()})
			return
		}
		defer enrolledRows.Close()

		type CourseProgress struct {
			ID               string   `json:"id"`
			Title            string   `json:"title"`
			ThumbnailURL     *string  `json:"thumbnail_url"`
			InstructorName   string   `json:"instructor_name"`
			TotalLessons     int      `json:"total_lessons"`
			CompletedLessons int      `json:"completed_lessons"`
			Progress         float64  `json:"progress"`
			LastAccessedAt   *string  `json:"last_accessed_at"`
			UnlockedAt       string   `json:"unlocked_at"`
			IsCompleted      bool     `json:"is_completed"`
		}

		var enrolled []CourseProgress
		for enrolledRows.Next() {
			var cp CourseProgress
			if err := enrolledRows.Scan(
				&cp.ID, &cp.Title, &cp.ThumbnailURL, &cp.InstructorName,
				&cp.TotalLessons, &cp.CompletedLessons, &cp.LastAccessedAt, &cp.UnlockedAt,
			); err != nil {
				continue
			}
			if cp.TotalLessons > 0 {
				cp.Progress = float64(cp.CompletedLessons) / float64(cp.TotalLessons)
				if cp.Progress > 1.0 {
					cp.Progress = 1.0
				}
			}
			cp.IsCompleted = cp.TotalLessons > 0 && cp.CompletedLessons >= cp.TotalLessons
			enrolled = append(enrolled, cp)
		}
		if enrolled == nil {
			enrolled = []CourseProgress{}
		}

		// --- Saved (bookmarked courses) -----------------------------------
		savedRows, err := db.QueryContext(c.Request.Context(), `
			SELECT
				c.id,
				c.title,
				c.thumbnail_url,
				c.instructor_name,
				c.lesson_count,
				(
					SELECT COUNT(*) FROM lesson_progress lp
					WHERE lp.user_id = $1 AND lp.course_id = c.id AND lp.completed = true
				) AS completed_lessons,
				(
					SELECT MAX(lp.last_accessed_at) FROM lesson_progress lp
					WHERE lp.user_id = $1 AND lp.course_id = c.id
				) AS last_accessed_at,
				bc.created_at
			FROM bookmarked_courses bc
			JOIN courses c ON c.id = bc.course_id
			WHERE bc.user_id = $1
			ORDER BY bc.created_at DESC
		`, userID)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch saved courses: " + err.Error()})
			return
		}
		defer savedRows.Close()

		var saved []CourseProgress
		for savedRows.Next() {
			var cp CourseProgress
			if err := savedRows.Scan(
				&cp.ID, &cp.Title, &cp.ThumbnailURL, &cp.InstructorName,
				&cp.TotalLessons, &cp.CompletedLessons, &cp.LastAccessedAt, &cp.UnlockedAt,
			); err != nil {
				continue
			}
			if cp.TotalLessons > 0 {
				cp.Progress = float64(cp.CompletedLessons) / float64(cp.TotalLessons)
			}
			cp.IsCompleted = cp.TotalLessons > 0 && cp.CompletedLessons >= cp.TotalLessons
			saved = append(saved, cp)
		}
		if saved == nil {
			saved = []CourseProgress{}
		}

		c.JSON(http.StatusOK, gin.H{
			"enrolled": enrolled,
			"saved":    saved,
		})
	}
}

// UpsertLessonProgressHandler marks a lesson as completed/accessed for a user
func UpsertLessonProgressHandler(db *sql.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		if db == nil {
			c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Database not connected"})
			return
		}

		var body struct {
			UserID    string `json:"user_id" binding:"required"`
			CourseID  string `json:"course_id" binding:"required"`
			LessonID  string `json:"lesson_id" binding:"required"`
			Completed bool   `json:"completed"`
		}
		if err := c.ShouldBindJSON(&body); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request: " + err.Error()})
			return
		}

		_, err := db.ExecContext(c.Request.Context(), `
			INSERT INTO lesson_progress (user_id, course_id, lesson_id, completed, last_accessed_at)
			VALUES ($1, $2, $3, $4, now())
			ON CONFLICT (user_id, lesson_id)
			DO UPDATE SET completed = $4, last_accessed_at = now()
		`, body.UserID, body.CourseID, body.LessonID, body.Completed)

		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update progress: " + err.Error()})
			return
		}

		c.JSON(http.StatusOK, gin.H{"message": "Progress updated"})
	}
}
