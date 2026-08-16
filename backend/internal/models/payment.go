package models

import (
	"time"
)

// Transaction represents a payment transaction in the database
type Transaction struct {
	ID          string    `json:"id"`
	UserID      string    `json:"user_id"` // Assuming we pass this or it's hardcoded for now
	CourseID    string    `json:"course_id"`
	TxRef       string    `json:"tx_ref"`
	Amount      float64   `json:"amount"`
	Status      string    `json:"status"` // pending, success, failed
	CheckoutURL string    `json:"checkout_url,omitempty"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
}

// ChapaInitializeRequest represents the payload sent to Chapa
type ChapaInitializeRequest struct {
	Amount        string            `json:"amount"`
	Currency      string            `json:"currency"`
	Email         string            `json:"email"`
	FirstName     string            `json:"first_name"`
	LastName      string            `json:"last_name"`
	PhoneNumber   string            `json:"phone_number,omitempty"`
	TxRef         string            `json:"tx_ref"`
	CallbackURL   string            `json:"callback_url"`
	ReturnURL     string            `json:"return_url"`
	Customization map[string]string `json:"customization"`
}

// ChapaInitializeResponse represents the response from Chapa initialize endpoint
type ChapaInitializeResponse struct {
	Message string `json:"message"`
	Status  string `json:"status"`
	Data    struct {
		CheckoutURL string `json:"checkout_url"`
	} `json:"data"`
}

// ChapaVerifyResponse represents the response from Chapa verify endpoint
type ChapaVerifyResponse struct {
	Message string `json:"message"`
	Status  string `json:"status"`
	Data    struct {
		TxRef  string  `json:"tx_ref"`
		Status string  `json:"status"`
		Amount float64 `json:"amount"`
	} `json:"data"`
}
