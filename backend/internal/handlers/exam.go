package handlers

import (
	"database/sql"
	"net/http"

	"github.com/gin-gonic/gin"
)

type ExamQuestion struct {
	ID               string `json:"id"`
	ChapterID        string `json:"chapter_id"`
	QuestionText     string `json:"question_text"`
	OptionA          string `json:"option_a"`
	OptionB          string `json:"option_b"`
	OptionC          string `json:"option_c"`
	OptionD          string `json:"option_d"`
	CorrectOption    string `json:"correct_option"`
	Explanation      string `json:"explanation"`
	TimeLimitSeconds int    `json:"time_limit_seconds"`
	CreatedAt        string `json:"created_at"`
}

func GetExamQuestionsHandler(db *sql.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		if db == nil {
			c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Database not connected"})
			return
		}
		chapterID := c.Param("id")
		rows, err := db.QueryContext(c.Request.Context(), "SELECT id, chapter_id, question_text, option_a, option_b, option_c, option_d, correct_option, COALESCE(explanation, ''), time_limit_seconds, created_at FROM exam_questions WHERE chapter_id = $1 ORDER BY created_at ASC", chapterID)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		defer rows.Close()
		var questions []ExamQuestion
		for rows.Next() {
			var q ExamQuestion
			if err := rows.Scan(&q.ID, &q.ChapterID, &q.QuestionText, &q.OptionA, &q.OptionB, &q.OptionC, &q.OptionD, &q.CorrectOption, &q.Explanation, &q.TimeLimitSeconds, &q.CreatedAt); err != nil {
				c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
				return
			}
			questions = append(questions, q)
		}
		if questions == nil {
			questions = []ExamQuestion{}
		}
		c.JSON(http.StatusOK, questions)
	}
}

func CreateExamQuestionHandler(db *sql.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		if db == nil {
			c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Database not connected"})
			return
		}
		var q ExamQuestion
		if err := c.ShouldBindJSON(&q); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}
		chapterID := c.Param("id")
		err := db.QueryRowContext(c.Request.Context(),
			"INSERT INTO exam_questions (chapter_id, question_text, option_a, option_b, option_c, option_d, correct_option, explanation, time_limit_seconds) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9) RETURNING id, created_at",
			chapterID, q.QuestionText, q.OptionA, q.OptionB, q.OptionC, q.OptionD, q.CorrectOption, q.Explanation, q.TimeLimitSeconds,
		).Scan(&q.ID, &q.CreatedAt)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		q.ChapterID = chapterID
		c.JSON(http.StatusCreated, q)
	}
}

func UpdateExamQuestionHandler(db *sql.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		if db == nil {
			c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Database not connected"})
			return
		}
		var q ExamQuestion
		if err := c.ShouldBindJSON(&q); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}
		id := c.Param("id")
		_, err := db.ExecContext(c.Request.Context(),
			"UPDATE exam_questions SET question_text = $1, option_a = $2, option_b = $3, option_c = $4, option_d = $5, correct_option = $6, explanation = $7, time_limit_seconds = $8 WHERE id = $9",
			q.QuestionText, q.OptionA, q.OptionB, q.OptionC, q.OptionD, q.CorrectOption, q.Explanation, q.TimeLimitSeconds, id,
		)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		c.JSON(http.StatusOK, gin.H{"message": "updated"})
	}
}

func DeleteExamQuestionHandler(db *sql.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		if db == nil {
			c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Database not connected"})
			return
		}
		id := c.Param("id")
		_, err := db.ExecContext(c.Request.Context(), "DELETE FROM exam_questions WHERE id = $1", id)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		c.JSON(http.StatusOK, gin.H{"message": "deleted"})
	}
}
