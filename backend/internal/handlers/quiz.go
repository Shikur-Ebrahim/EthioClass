package handlers

import (
	"database/sql"
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type QuizRow struct {
	ID            string  `json:"id"`
	LessonID      string  `json:"lesson_id"`
	Question      string  `json:"question"`
	OptionA       string  `json:"option_a"`
	OptionB       string  `json:"option_b"`
	OptionC       string  `json:"option_c"`
	OptionD       string  `json:"option_d"`
	CorrectAnswer string  `json:"correct_answer"`
	Explanation   *string `json:"explanation"`
	CreatedAt     *string `json:"created_at"`
}

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
			`SELECT id, lesson_id, question, option_a, option_b, option_c, option_d, correct_answer, explanation, created_at
			 FROM quizzes WHERE lesson_id = $1 ORDER BY created_at ASC`, lessonId)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch quizzes: " + err.Error()})
			return
		}
		defer rows.Close()

		var quizzes []QuizRow
		for rows.Next() {
			var q QuizRow
			if err := rows.Scan(&q.ID, &q.LessonID, &q.Question, &q.OptionA, &q.OptionB, &q.OptionC, &q.OptionD, &q.CorrectAnswer, &q.Explanation, &q.CreatedAt); err != nil {
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

// CreateQuizHandler handles POST /admin/quizzes
func CreateQuizHandler(db *sql.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		if db == nil {
			c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Database not connected"})
			return
		}

		var body struct {
			LessonID      string `json:"lesson_id"`
			Question      string `json:"question"`
			OptionA       string `json:"option_a"`
			OptionB       string `json:"option_b"`
			OptionC       string `json:"option_c"`
			OptionD       string `json:"option_d"`
			CorrectAnswer string `json:"correct_answer"`
			Explanation   string `json:"explanation"`
		}

		if err := c.ShouldBindJSON(&body); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request"})
			return
		}

		body.LessonID = strings.TrimSpace(body.LessonID)
		body.Question = strings.TrimSpace(body.Question)
		body.CorrectAnswer = strings.TrimSpace(body.CorrectAnswer)

		if body.LessonID == "" || body.Question == "" || body.CorrectAnswer == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "lesson_id, question, and correct_answer are required"})
			return
		}

		id := uuid.New().String()
		var explanation *string
		if body.Explanation != "" {
			explanation = &body.Explanation
		}

		_, err := db.ExecContext(c.Request.Context(),
			`INSERT INTO quizzes (id, lesson_id, question, option_a, option_b, option_c, option_d, correct_answer, explanation)
			 VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)`,
			id, body.LessonID, body.Question, body.OptionA, body.OptionB, body.OptionC, body.OptionD, body.CorrectAnswer, explanation,
		)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create quiz: " + err.Error()})
			return
		}
		c.JSON(http.StatusCreated, gin.H{"message": "Quiz created", "id": id})
	}
}

// UpdateQuizHandler handles PUT /admin/quizzes/:id
func UpdateQuizHandler(db *sql.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		if db == nil {
			c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Database not connected"})
			return
		}

		quizID := c.Param("id")

		var body struct {
			Question      string `json:"question"`
			OptionA       string `json:"option_a"`
			OptionB       string `json:"option_b"`
			OptionC       string `json:"option_c"`
			OptionD       string `json:"option_d"`
			CorrectAnswer string `json:"correct_answer"`
			Explanation   string `json:"explanation"`
		}

		if err := c.ShouldBindJSON(&body); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request"})
			return
		}

		var explanation *string
		if body.Explanation != "" {
			explanation = &body.Explanation
		}

		_, err := db.ExecContext(c.Request.Context(),
			`UPDATE quizzes SET question=$1, option_a=$2, option_b=$3, option_c=$4, option_d=$5, correct_answer=$6, explanation=$7 WHERE id=$8`,
			body.Question, body.OptionA, body.OptionB, body.OptionC, body.OptionD, body.CorrectAnswer, explanation, quizID,
		)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update quiz: " + err.Error()})
			return
		}
		c.JSON(http.StatusOK, gin.H{"message": "Quiz updated"})
	}
}

// DeleteQuizHandler handles DELETE /admin/quizzes/:id
func DeleteQuizHandler(db *sql.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		if db == nil {
			c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Database not connected"})
			return
		}
		quizID := c.Param("id")
		_, err := db.ExecContext(c.Request.Context(), `DELETE FROM quizzes WHERE id = $1`, quizID)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete quiz: " + err.Error()})
			return
		}
		c.JSON(http.StatusOK, gin.H{"message": "Quiz deleted"})
	}
}
