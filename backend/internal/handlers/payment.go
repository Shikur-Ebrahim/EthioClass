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
	"github.com/google/uuid"
)

type InitializePaymentRequest struct {
	CourseID string `json:"course_id" binding:"required"`
}

type ChapaInitPayload struct {
	Amount      string `json:"amount"`
	Currency    string `json:"currency"`
	Email       string `json:"email"`
	FirstName   string `json:"first_name"`
	LastName    string `json:"last_name"`
	TxRef       string `json:"tx_ref"`
	CallbackURL string `json:"callback_url"`
	ReturnURL   string `json:"return_url"`
}

type ChapaInitResponse struct {
	Status  string `json:"status"`
	Message string `json:"message"`
	Data    struct {
		CheckoutURL string `json:"checkout_url"`
	} `json:"data"`
}

// InitializePaymentHandler starts the payment process
func InitializePaymentHandler(db *sql.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		if db == nil {
			c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Database not connected"})
			return
		}

		var req InitializePaymentRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
			return
		}

		// Hardcoded user ID for now as we don't have auth middleware yet
		userID := "00000000-0000-0000-0000-000000000000"
		amount := 249.00
		txRef := "TX-" + uuid.New().String()

		// 1. Save pending transaction to DB
		query := `INSERT INTO transactions (user_id, course_id, tx_ref, amount, status) VALUES ($1, $2, $3, $4, 'pending') RETURNING id`
		var txID string
		err := db.QueryRowContext(c.Request.Context(), query, userID, req.CourseID, txRef, amount).Scan(&txID)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create transaction: " + err.Error()})
			return
		}

		// 2. Call Chapa API
		chapaSecret := os.Getenv("CHAPA_SECRET_KEY")
		if chapaSecret == "" {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Chapa secret key not configured"})
			return
		}

		payload := ChapaInitPayload{
			Amount:      "249",
			Currency:    "ETB",
			Email:       "test@ethioclass.com",
			FirstName:   "Test",
			LastName:    "User",
			TxRef:       txRef,
			CallbackURL: "https://webhook.site/", // Change in production
			ReturnURL:   "https://chapa.co",      // Standard return URL
		}

		payloadBytes, _ := json.Marshal(payload)

		chapaReq, _ := http.NewRequest("POST", "https://api.chapa.co/v1/transaction/initialize", bytes.NewBuffer(payloadBytes))
		chapaReq.Header.Set("Authorization", "Bearer "+chapaSecret)
		chapaReq.Header.Set("Content-Type", "application/json")

		client := &http.Client{}
		resp, err := client.Do(chapaReq)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to call Chapa API"})
			return
		}
		defer resp.Body.Close()

		body, _ := io.ReadAll(resp.Body)
		var chapaResp ChapaInitResponse
		if err := json.Unmarshal(body, &chapaResp); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to parse Chapa response"})
			return
		}

		if chapaResp.Status != "success" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Chapa error: " + chapaResp.Message, "details": string(body)})
			return
		}

		// 3. Update DB with checkout URL
		_, err = db.ExecContext(c.Request.Context(), `UPDATE transactions SET checkout_url = $1 WHERE tx_ref = $2`, chapaResp.Data.CheckoutURL, txRef)
		if err != nil {
			fmt.Println("Warning: Failed to save checkout_url to db:", err)
		}

		c.JSON(http.StatusOK, gin.H{
			"tx_ref":       txRef,
			"checkout_url": chapaResp.Data.CheckoutURL,
		})
	}
}

// VerifyPaymentHandler verifies payment status
func VerifyPaymentHandler(db *sql.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		if db == nil {
			c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Database not connected"})
			return
		}

		txRef := c.Param("tx_ref")
		if txRef == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "tx_ref is required"})
			return
		}

		chapaSecret := os.Getenv("CHAPA_SECRET_KEY")

		req, _ := http.NewRequest("GET", "https://api.chapa.co/v1/transaction/verify/"+txRef, nil)
		req.Header.Set("Authorization", "Bearer "+chapaSecret)

		client := &http.Client{}
		resp, err := client.Do(req)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to verify transaction"})
			return
		}
		defer resp.Body.Close()

		body, _ := io.ReadAll(resp.Body)
		var verifyResp struct {
			Status string `json:"status"`
			Data   struct {
				Status string `json:"status"` // "success" or "failed" or "pending"
			} `json:"data"`
		}
		json.Unmarshal(body, &verifyResp)

		if verifyResp.Status == "success" && verifyResp.Data.Status == "success" {
			// Update transaction to success
			_, err = db.ExecContext(c.Request.Context(), `UPDATE transactions SET status = 'success' WHERE tx_ref = $1`, txRef)

			// Unlock the course for the user
			var userID, courseID string
			err = db.QueryRowContext(c.Request.Context(), `SELECT user_id, course_id FROM transactions WHERE tx_ref = $1`, txRef).Scan(&userID, &courseID)
			if err == nil {
				_, _ = db.ExecContext(c.Request.Context(), `
					INSERT INTO user_courses (user_id, course_id, transaction_id)
					SELECT t.user_id, t.course_id, t.id
					FROM transactions t WHERE t.tx_ref = $1
					ON CONFLICT (user_id, course_id) DO NOTHING
				`, txRef)
			}

			c.JSON(http.StatusOK, gin.H{"status": "success"})
		} else {
			c.JSON(http.StatusOK, gin.H{"status": verifyResp.Data.Status})
		}
	}
}
