package handlers

import (
	"database/sql"
	"net/http"

	"github.com/gin-gonic/gin"
)

// GetQuizzesHandler fetches quiz questions for a specific lesson
func GetQuizzesHandler(db *sql.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		if db == nil {
			c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Database not connected"})
			return
		}

		lessonId := c.Query("lesson_id")
		if lessonId == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "lesson_id is required"})
			return
		}

		rows, err := db.QueryContext(c.Request.Context(),
			`SELECT id, lesson_id, question, option_a, option_b, option_c, option_d, correct_answer, created_at
			 FROM quizzes WHERE lesson_id = $1 ORDER BY created_at ASC`, lessonId)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch quizzes: " + err.Error()})
			return
		}
		defer rows.Close()

		type QuizRow struct {
			ID            string  `json:"id"`
			LessonID      string  `json:"lesson_id"`
			Question      string  `json:"question"`
			OptionA       string  `json:"option_a"`
			OptionB       string  `json:"option_b"`
			OptionC       string  `json:"option_c"`
			OptionD       string  `json:"option_d"`
			CorrectAnswer string  `json:"correct_answer"`
			CreatedAt     *string `json:"created_at"`
		}

		var quizzes []QuizRow
		for rows.Next() {
			var q QuizRow
			if err := rows.Scan(&q.ID, &q.LessonID, &q.Question, &q.OptionA, &q.OptionB, &q.OptionC, &q.OptionD, &q.CorrectAnswer, &q.CreatedAt); err != nil {
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Parse error: " + err.Error()})
				return
			}
			quizzes = append(quizzes, q)
		}
		if quizzes == nil {
			quizzes = []QuizRow{}
		}
		c.JSON(http.StatusOK, quizzes)
	}
}
