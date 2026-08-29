package handlers

import (
	"bytes"
	"database/sql"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"strings"
	"time"

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
			`SELECT id, lesson_id, question, option_a, option_b, option_c, option_d, correct_answer, explanation, created_at FROM quizzes WHERE lesson_id = $1 ORDER BY created_at ASC`, lessonId)
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
		_, err := db.ExecContext(c.Request.Context(),
			`INSERT INTO quizzes (id, lesson_id, question, option_a, option_b, option_c, option_d, correct_answer) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
			id, body.LessonID, body.Question, body.OptionA, body.OptionB, body.OptionC, body.OptionD, body.CorrectAnswer,
		)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create quiz: " + err.Error()})
			return
		}
		c.JSON(http.StatusCreated, gin.H{"message": "Quiz created", "id": id})
	}
}

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
		}
		if err := c.ShouldBindJSON(&body); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request"})
			return
		}
		_, err := db.ExecContext(c.Request.Context(),
			`UPDATE quizzes SET question=$1, option_a=$2, option_b=$3, option_c=$4, option_d=$5, correct_answer=$6 WHERE id=$7`,
			body.Question, body.OptionA, body.OptionB, body.OptionC, body.OptionD, body.CorrectAnswer, quizID,
		)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update quiz: " + err.Error()})
			return
		}
		c.JSON(http.StatusOK, gin.H{"message": "Quiz updated"})
	}
}

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

type ExplainQuizRequest struct {
	QuizID   string `json:"quiz_id"`
	Question string `json:"question"`
	Answer   string `json:"answer"`
}

func ExplainQuizAnswerHandler(db *sql.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		var req ExplainQuizRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusOK, gin.H{"error": "Invalid request body"})
			return
		}
		if db != nil && req.QuizID != "" {
			var cached sql.NullString
			err := db.QueryRowContext(c.Request.Context(), "SELECT explanation FROM quizzes WHERE id = $1 LIMIT 1", req.QuizID).Scan(&cached)
			if err == nil && cached.Valid && cached.String != "" {
				fmt.Println("[QUIZ CACHE HIT] Served explanation from quizzes table!")
				c.JSON(http.StatusOK, gin.H{"explanation": cached.String})
				return
			}
		}
		apiKey := os.Getenv("GROQ_API_KEY")
		if apiKey == "" {
			c.JSON(http.StatusOK, gin.H{"error": "GROQ_API_KEY not configured"})
			return
		}
		model := getBestGroqModel(apiKey)
		prompt := fmt.Sprintf("You are an expert, friendly Ethiopian high school teacher. A student answered this quiz question: \"%s\". The correct answer is \"%s\". Please explain WHY this is the correct answer in simple terms for a high school student. Make the explanation clear, encouraging, and no longer than 3 short paragraphs.", req.Question, req.Answer)
		payload := map[string]interface{}{
			"model": model,
			"messages": []map[string]interface{}{
				{"role": "user", "content": prompt},
			},
			"temperature": 0.5,
		}
		payloadBytes, _ := json.Marshal(payload)
		httpReq, err := http.NewRequest("POST", "https://api.groq.com/openai/v1/chat/completions", bytes.NewBuffer(payloadBytes))
		if err != nil {
			c.JSON(http.StatusOK, gin.H{"error": "Failed to create request"})
			return
		}
		httpReq.Header.Set("Content-Type", "application/json")
		httpReq.Header.Set("Authorization", "Bearer "+apiKey)
		httpClient := &http.Client{Timeout: 30 * time.Second}
		resp, err := httpClient.Do(httpReq)
		if err != nil {
			c.JSON(http.StatusOK, gin.H{"error": "Failed to reach AI service"})
			return
		}
		defer resp.Body.Close()
		bodyBytes, _ := io.ReadAll(resp.Body)
		var groqResp struct {
			Choices []struct {
				Message struct {
					Content string `json:"content"`
				} `json:"message"`
			} `json:"choices"`
			Error *struct {
				Message string `json:"message"`
			} `json:"error"`
		}
		if err := json.Unmarshal(bodyBytes, &groqResp); err != nil || groqResp.Error != nil {
			errMsg := "AI service error"
			if groqResp.Error != nil {
				errMsg = groqResp.Error.Message
			}
			c.JSON(http.StatusOK, gin.H{"error": errMsg})
			return
		}
		if len(groqResp.Choices) == 0 {
			c.JSON(http.StatusOK, gin.H{"error": "No response from AI"})
			return
		}
		explanation := groqResp.Choices[0].Message.Content
		if db != nil && req.QuizID != "" {
			_, err = db.ExecContext(c.Request.Context(), "UPDATE quizzes SET explanation = $1 WHERE id = $2", explanation, req.QuizID)
			if err != nil {
				fmt.Printf("[QUIZ CACHE ERROR] %v\n", err)
			} else {
				fmt.Println("[QUIZ CACHE MISS] Saved to quizzes table!")
			}
		}
		c.JSON(http.StatusOK, gin.H{"explanation": explanation})
	}
}
