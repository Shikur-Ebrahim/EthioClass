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

func ExplainExamAnswerHandler() gin.HandlerFunc {
	return func(c *gin.Context) {
		var req ExplainRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
			return
		}

		apiKey := os.Getenv("GEMINI_API_KEY")
		if apiKey == "" {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "GEMINI_API_KEY not configured"})
			return
		}

		prompt := fmt.Sprintf("You are an expert, friendly Ethiopian high school teacher. A student asked this question: \"%s\". The correct answer is \"%s\". Please explain WHY this is the correct answer in simple terms for a high school student. Make the explanation clear, encouraging, and no longer than 3 short paragraphs.", req.Question, req.Answer)

		payload := map[string]interface{}{
			"contents": []map[string]interface{}{
				{
					"parts": []map[string]interface{}{
						{
							"text": prompt,
						},
					},
				},
			},
		}

		payloadBytes, _ := json.Marshal(payload)
		url := "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent"

		httpReq, err := http.NewRequest("POST", url, bytes.NewBuffer(payloadBytes))
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create request"})
			return
		}
		httpReq.Header.Set("Content-Type", "application/json")
		httpReq.Header.Set("x-goog-api-key", apiKey)

		client := &http.Client{}
		resp, err := client.Do(httpReq)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to connect to AI"})
			return
		}
		defer resp.Body.Close()

		body, _ := io.ReadAll(resp.Body)

		// Log for debugging
		fmt.Printf("[GEMINI] Status: %d Body: %s\n", resp.StatusCode, string(body))

		var geminiResp map[string]interface{}
		if err := json.Unmarshal(body, &geminiResp); err != nil {
			// Always return 200 so Cloudflare doesn't intercept
			c.JSON(http.StatusOK, gin.H{"error": "Failed to parse AI response", "raw": string(body)})
			return
		}

		// Check if Gemini returned an error (e.g. invalid API key, quota exceeded)
		if errObj, hasErr := geminiResp["error"]; hasErr {
			if errMap, ok := errObj.(map[string]interface{}); ok {
				msg, _ := errMap["message"].(string)
				status, _ := errMap["status"].(string)
				if status == "RESOURCE_EXHAUSTED" {
					c.JSON(http.StatusOK, gin.H{"error": "daily_limit_reached"})
				} else {
					c.JSON(http.StatusOK, gin.H{"error": msg})
				}
			} else {
				c.JSON(http.StatusOK, gin.H{"error": "AI service error"})
			}
			return
		}

		candidates, ok := geminiResp["candidates"].([]interface{})
		if !ok || len(candidates) == 0 {
			c.JSON(http.StatusOK, gin.H{"error": "No response from AI"})
			return
		}
		firstCandidate, _ := candidates[0].(map[string]interface{})
		content, _ := firstCandidate["content"].(map[string]interface{})
		parts, _ := content["parts"].([]interface{})
		if len(parts) == 0 {
			c.JSON(http.StatusOK, gin.H{"error": "Empty AI response"})
			return
		}
		firstPart, _ := parts[0].(map[string]interface{})
		explanation, _ := firstPart["text"].(string)

		c.JSON(http.StatusOK, gin.H{"explanation": explanation})
	}
}
