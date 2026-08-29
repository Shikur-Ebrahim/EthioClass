package handlers

import (
	"bytes"
	"database/sql"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"

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
		rows, err := db.QueryContext(c.Request.Context(), "SELECT id, chapter_id, question_text, option_a, option_b, option_c, option_d, correct_option, time_limit_seconds, created_at FROM exam_questions WHERE chapter_id = $1 ORDER BY created_at ASC", chapterID)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		defer rows.Close()
		var questions []ExamQuestion
		for rows.Next() {
			var q ExamQuestion
			if err := rows.Scan(&q.ID, &q.ChapterID, &q.QuestionText, &q.OptionA, &q.OptionB, &q.OptionC, &q.OptionD, &q.CorrectOption, &q.TimeLimitSeconds, &q.CreatedAt); err != nil {
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
			"INSERT INTO exam_questions (chapter_id, question_text, option_a, option_b, option_c, option_d, correct_option, time_limit_seconds) VALUES ($1, $2, $3, $4, $5, $6, $7, $8) RETURNING id, created_at",
			chapterID, q.QuestionText, q.OptionA, q.OptionB, q.OptionC, q.OptionD, q.CorrectOption, q.TimeLimitSeconds,
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
			"UPDATE exam_questions SET question_text = $1, option_a = $2, option_b = $3, option_c = $4, option_d = $5, correct_option = $6, time_limit_seconds = $7 WHERE id = $8",
			q.QuestionText, q.OptionA, q.OptionB, q.OptionC, q.OptionD, q.CorrectOption, q.TimeLimitSeconds, id,
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
type ExplainRequest struct {
	Question string `json:"question"`
	Answer   string `json:"answer"`
}

func ExplainExamAnswerHandler(db *sql.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		var req ExplainRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
			return
		}

		if db != nil {
			// Ensure explanation column exists in exam_questions table
			_, err := db.ExecContext(c.Request.Context(), `
				ALTER TABLE exam_questions ADD COLUMN IF NOT EXISTS explanation TEXT;
			`)
			if err == nil {
				// Check Cache
				var cached sql.NullString
				err := db.QueryRowContext(c.Request.Context(), "SELECT explanation FROM exam_questions WHERE question_text = $1 LIMIT 1", req.Question).Scan(&cached)
				if err == nil && cached.Valid && cached.String != "" {
					fmt.Println("[CACHE HIT] Served explanation from exam_questions table!")
					c.JSON(http.StatusOK, gin.H{"explanation": cached.String})
					return
				}
			}
		}

		apiKey := os.Getenv("GROQ_API_KEY")
		if apiKey == "" {
			c.JSON(http.StatusOK, gin.H{"error": "GROQ_API_KEY not configured"})
			return
		}

		prompt := fmt.Sprintf("You are an expert, friendly Ethiopian high school teacher. A student asked this question: \"%s\". The correct answer is \"%s\". Please explain WHY this is the correct answer in simple terms for a high school student. Make the explanation clear, encouraging, and no longer than 3 short paragraphs.", req.Question, req.Answer)

		payload := map[string]interface{}{
			"model": "openai/gpt-oss-120b",
			"messages": []map[string]interface{}{
				{"role": "user", "content": prompt},
			},
			"temperature": 0.5,
		}

		payloadBytes, _ := json.Marshal(payload)
		url := "https://api.groq.com/openai/v1/chat/completions"

		httpReq, err := http.NewRequest("POST", url, bytes.NewBuffer(payloadBytes))
		if err != nil {
			c.JSON(http.StatusOK, gin.H{"error": "Failed to create request"})
			return
		}
		httpReq.Header.Set("Content-Type", "application/json")
		httpReq.Header.Set("Authorization", "Bearer "+apiKey)

		client := &http.Client{}
		resp, err := client.Do(httpReq)
		if err != nil {
			c.JSON(http.StatusOK, gin.H{"error": "Failed to connect to AI"})
			return
		}
		defer resp.Body.Close()

		body, _ := io.ReadAll(resp.Body)

		var groqResp map[string]interface{}
		if err := json.Unmarshal(body, &groqResp); err != nil {
			c.JSON(http.StatusOK, gin.H{"error": "Failed to parse AI response"})
			return
		}

		if errObj, hasErr := groqResp["error"]; hasErr {
			if errMap, ok := errObj.(map[string]interface{}); ok {
				msg, _ := errMap["message"].(string)
				c.JSON(http.StatusOK, gin.H{"error": msg})
			} else {
				c.JSON(http.StatusOK, gin.H{"error": "AI service error"})
			}
			return
		}

		// Parse the OpenAI-compatible response from Groq
		choices, ok := groqResp["choices"].([]interface{})
		if !ok || len(choices) == 0 {
			c.JSON(http.StatusOK, gin.H{"error": "Empty response from AI"})
			return
		}

		choice := choices[0].(map[string]interface{})
		message := choice["message"].(map[string]interface{})
		explanation := message["content"].(string)

		// Save to cache
		if db != nil {
			_, err := db.ExecContext(c.Request.Context(), 
				"UPDATE exam_questions SET explanation = $1 WHERE question_text = $2", 
				explanation, req.Question)
			if err != nil {
				fmt.Printf("[CACHE ERROR] Failed to save to database: %v\n", err)
			} else {
				fmt.Println("[CACHE MISS] Saved new explanation to exam_questions table!")
			}
		}

		c.JSON(http.StatusOK, gin.H{"explanation": explanation})
	}
}
