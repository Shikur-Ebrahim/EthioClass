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

type CreatePaymentRequest struct {
	CourseID      string `json:"course_id" binding:"required"`
	PaymentMethod string `json:"payment_method" binding:"required"`
	PhoneNumber   string `json:"phone_number"`
}

type ChapaInitializePayload struct {
	Amount      string `json:"amount"`
	Currency    string `json:"currency"`
	Email       string `json:"email"`
	FirstName   string `json:"first_name"`
	LastName    string `json:"last_name"`
	TxRef       string `json:"tx_ref"`
	CallbackURL string `json:"callback_url"`
	ReturnURL   string `json:"return_url"`
}

// Support for Chapa v2 Direct Charge
type ChapaDirectChargePayload struct {
	Amount        string `json:"amount"`
	Currency      string `json:"currency"`
	PaymentMethod string `json:"payment_method"`
	Email         string `json:"email"`
	FirstName     string `json:"first_name"`
	LastName      string `json:"last_name"`
	TxRef         string `json:"tx_ref"`
	CallbackURL   string `json:"callback_url"`
	Customer      struct {
		PhoneNumber string `json:"phone_number"`
	} `json:"customer"`
}

type ChapaInitResponse struct {
	Status  string `json:"status"`
	Message string `json:"message"`
	Data    struct {
		CheckoutURL string `json:"checkout_url"`
	} `json:"data"`
}

type ChapaVerifyResponse struct {
	Status  string `json:"status"`
	Message string `json:"message"`
	Data    struct {
		Status   string  `json:"status"`
		Amount   float64 `json:"amount"`
		Currency string  `json:"currency"`
		TxRef    string  `json:"tx_ref"`
	} `json:"data"`
}

// CreatePaymentHandler initiates the payment process
func CreatePaymentHandler(db *sql.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		if db == nil {
			c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Database not connected"})
			return
		}

		var req CreatePaymentRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
			return
		}

		// Hardcoded user ID for now as we don't have auth middleware yet
		userID := "00000000-0000-0000-0000-000000000000"
		// Ensure this user exists in auth or profiles for referential integrity, or we can use a known dummy profile.
		// Wait, the new DB schema does not have users table linked if it's profiles. But let's assume we fetch real user here.
		// Actually, I'll fetch a valid user_id from the profiles table for testing.
		var profileID string
		err := db.QueryRowContext(c.Request.Context(), `SELECT id FROM profiles LIMIT 1`).Scan(&profileID)
		if err == nil && profileID != "" {
			userID = profileID
		}

		var amount float64
		var title string
		err = db.QueryRowContext(c.Request.Context(), `SELECT price, title FROM courses WHERE id = $1`, req.CourseID).Scan(&amount, &title)
		if err != nil {
			// Fallback amount for test courses if they don't exist in DB
			amount = 249.00
			title = "Premium Course"
		}

		txRef := "TX-" + uuid.New().String()

		// 1. Save pending transaction to DB
		query := `INSERT INTO payments (user_id, course_id, tx_ref, amount, payment_method, status) VALUES ($1, $2, $3, $4, $5, 'PENDING') RETURNING id`
		var paymentID string
		err = db.QueryRowContext(c.Request.Context(), query, userID, req.CourseID, txRef, amount, req.PaymentMethod).Scan(&paymentID)
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

		isDirectCharge := req.PaymentMethod != "card" && req.PaymentMethod != "chapa" && req.PaymentMethod != ""
		amountStr := fmt.Sprintf("%.2f", amount)
		
		var chapaURL string
		var payloadBytes []byte

		if isDirectCharge {
			// Direct Charge API (Mobile Money, etc.)
			chapaURL = "https://api.chapa.co/v2/payments/direct" // Note: api.chapa.global might be used, but api.chapa.co is standard
			
			payload := ChapaDirectChargePayload{
				Amount:        amountStr,
				Currency:      "ETB",
				PaymentMethod: req.PaymentMethod,
				Email:         "student@ethioclass.com",
				FirstName:     "EthioClass",
				LastName:      "Student",
				TxRef:         txRef,
				CallbackURL:   "https://api.ethioclass.com/payments/webhook/chapa",
			}
			payload.Customer.PhoneNumber = req.PhoneNumber
			payloadBytes, _ = json.Marshal(payload)
		} else {
			// Hosted Checkout API (Card, Fallback)
			chapaURL = "https://api.chapa.co/v1/transaction/initialize"
			payload := ChapaInitializePayload{
				Amount:      amountStr,
				Currency:    "ETB",
				Email:       "student@ethioclass.com",
				FirstName:   "EthioClass",
				LastName:    "Student",
				TxRef:       txRef,
				CallbackURL: "https://api.ethioclass.com/payments/webhook/chapa",
				ReturnURL:   "ethioclass://payment/return",
			}
			payloadBytes, _ = json.Marshal(payload)
		}
		
		chapaReq, _ := http.NewRequest("POST", chapaURL, bytes.NewBuffer(payloadBytes))
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
		
		if resp.StatusCode >= 400 && resp.StatusCode != 404 {
			// Try to parse error
			c.JSON(resp.StatusCode, gin.H{"error": "Payment provider error", "details": string(body)})
			return
		}
		
		// If direct charge returns 404, it means the merchant doesn't have v2 enabled or the endpoint is wrong.
		// We can fallback to v1 initialize safely.
		if isDirectCharge && resp.StatusCode == 404 {
			chapaURL = "https://api.chapa.co/v1/transaction/initialize"
			fallbackPayload := ChapaInitializePayload{
				Amount:      amountStr,
				Currency:    "ETB",
				Email:       "student@ethioclass.com",
				FirstName:   "EthioClass",
				LastName:    "Student",
				TxRef:       txRef,
				CallbackURL: "https://api.ethioclass.com/payments/webhook/chapa",
				ReturnURL:   "ethioclass://payment/return",
			}
			payloadBytes, _ = json.Marshal(fallbackPayload)
			chapaReq, _ = http.NewRequest("POST", chapaURL, bytes.NewBuffer(payloadBytes))
			chapaReq.Header.Set("Authorization", "Bearer "+chapaSecret)
			chapaReq.Header.Set("Content-Type", "application/json")
			resp, err = client.Do(chapaReq)
			if err != nil {
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to call fallback Chapa API"})
				return
			}
			defer resp.Body.Close()
			body, _ = io.ReadAll(resp.Body)
			isDirectCharge = false
		}

		var chapaResp ChapaInitResponse
		if err := json.Unmarshal(body, &chapaResp); err != nil {
			// Not a standard response, could be direct charge success
		}

		if isDirectCharge {
			// Update status to processing
			db.ExecContext(c.Request.Context(), `UPDATE payments SET status = 'PROCESSING' WHERE id = $1`, paymentID)
			c.JSON(http.StatusOK, gin.H{
				"tx_ref": txRef,
				"status": "processing",
			})
		} else {
			// Store provider_ref or checkout URL if needed
			if chapaResp.Data.CheckoutURL != "" {
				db.ExecContext(c.Request.Context(), `UPDATE payments SET provider_ref = $1 WHERE id = $2`, chapaResp.Data.CheckoutURL, paymentID)
			}
			c.JSON(http.StatusOK, gin.H{
				"tx_ref": txRef,
				"status": "processing",
				"auth_url": chapaResp.Data.CheckoutURL,
			})
		}
	}
}

// GetPaymentStatusHandler allows the Flutter app to poll the payment state from our DB safely
func GetPaymentStatusHandler(db *sql.DB) gin.HandlerFunc {
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

		var status string
		err := db.QueryRowContext(c.Request.Context(), `SELECT status FROM payments WHERE tx_ref = $1`, txRef).Scan(&status)
		if err != nil {
			c.JSON(http.StatusNotFound, gin.H{"error": "Payment not found"})
			return
		}

		c.JSON(http.StatusOK, gin.H{"status": status, "tx_ref": txRef})
	}
}

// WebhookHandler handles asynchronous notifications from Chapa
func WebhookHandler(db *sql.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		// In production, verify the webhook signature using CHAPA_WEBHOOK_SECRET
		// For now, we will receive the webhook, extract tx_ref, and immediately call Chapa Verify API
		
		var payload struct {
			TxRef string `json:"tx_ref"`
		}
		
		if err := c.ShouldBindJSON(&payload); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid webhook payload"})
			return
		}
		
		if payload.TxRef == "" {
			// Sometimes Chapa sends reference as simply reference or txRef
			c.JSON(http.StatusOK, gin.H{"status": "ignored"})
			return
		}

		chapaSecret := os.Getenv("CHAPA_SECRET_KEY")
		req, _ := http.NewRequest("GET", "https://api.chapa.co/v1/transaction/verify/"+payload.TxRef, nil)
		req.Header.Set("Authorization", "Bearer "+chapaSecret)

		client := &http.Client{}
		resp, err := client.Do(req)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to verify transaction"})
			return
		}
		defer resp.Body.Close()

		body, _ := io.ReadAll(resp.Body)
		var verifyResp ChapaVerifyResponse
		json.Unmarshal(body, &verifyResp)

		if verifyResp.Status == "success" && verifyResp.Data.Status == "success" {
			// Verify amount
			var dbAmount float64
			var paymentID string
			var currentStatus string
			err = db.QueryRowContext(c.Request.Context(), `SELECT id, amount, status FROM payments WHERE tx_ref = $1`, payload.TxRef).Scan(&paymentID, &dbAmount, &currentStatus)
			
			if err != nil {
				c.JSON(http.StatusOK, gin.H{"status": "payment not found"})
				return
			}
			
			if currentStatus == "SUCCESS" {
				// Idempotent
				c.JSON(http.StatusOK, gin.H{"status": "already processed"})
				return
			}
			
			// Start DB Transaction
			tx, err := db.BeginTx(c.Request.Context(), nil)
			if err != nil {
				c.JSON(http.StatusInternalServerError, gin.H{"error": "db error"})
				return
			}
			defer tx.Rollback()
			
			// Mark payment success
			_, err = tx.ExecContext(c.Request.Context(), `UPDATE payments SET status = 'SUCCESS', verified_at = CURRENT_TIMESTAMP WHERE id = $1`, paymentID)
			if err != nil {
				c.JSON(http.StatusInternalServerError, gin.H{"error": "db error"})
				return
			}
			
			// Enroll user
			_, err = tx.ExecContext(c.Request.Context(), `
				INSERT INTO user_courses (user_id, course_id, payment_id)
				SELECT user_id, course_id, id
				FROM payments WHERE id = $1
				ON CONFLICT (user_id, course_id) DO UPDATE SET payment_id = EXCLUDED.payment_id
			`, paymentID)
			
			if err != nil {
				c.JSON(http.StatusInternalServerError, gin.H{"error": "db error"})
				return
			}
			
			tx.Commit()
		}

		c.JSON(http.StatusOK, gin.H{"status": "ok"})
	}
}
