package handlers

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"
	"os"

	"github.com/EthioClass/backend/internal/auth"
	"github.com/EthioClass/backend/internal/models"
	"github.com/gin-gonic/gin"
	supa "github.com/supabase-community/gotrue-go/types"
)

func SignupHandler(c *gin.Context) {
	var req models.SignupRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	signupReq := supa.SignupRequest{
		Email:    req.Email,
		Password: req.Password,
		Data: map[string]interface{}{
			"full_name":    req.FullName,
			"phone_number": req.PhoneNumber,
		},
	}

	resp, err := auth.Client.Auth.Signup(signupReq)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Signup successful",
		"user":    resp.User,
	})
}

func LoginHandler(c *gin.Context) {
	var req models.LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	tokenReq := supa.TokenRequest{
		GrantType: "password",
		Email:     req.Email,
		Password:  req.Password,
	}

	resp, err := auth.Client.Auth.Token(tokenReq)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid email or password"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Login successful",
		"token":   resp.AccessToken,
		"user":    resp.User,
	})
}

func ResetPasswordHandler(c *gin.Context) {
	var req models.ResetPasswordRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	supabaseURL := os.Getenv("SUPABASE_URL")
	supabaseKey := os.Getenv("SUPABASE_KEY")

	payload := map[string]string{"email": req.Email}
	if req.RedirectTo != "" {
		// Pass the redirect URL if provided by the client (e.g. deep link)
		// Supabase will use this URL as the base for the recovery link in the email
		// Supabase requires this URL to be registered in the "Redirect URLs" in the dashboard.
	}
	body, _ := json.Marshal(payload)

	httpReq, err := http.NewRequest("POST",
		fmt.Sprintf("%s/auth/v1/recover", supabaseURL),
		bytes.NewBuffer(body),
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to build request"})
		return
	}
	httpReq.Header.Set("Content-Type", "application/json")
	httpReq.Header.Set("apikey", supabaseKey)
	// We MUST pass the redirect URL in the query param according to Supabase REST API docs
	if req.RedirectTo != "" {
		q := httpReq.URL.Query()
		q.Add("redirect_to", req.RedirectTo)
		httpReq.URL.RawQuery = q.Encode()
	}

	httpClient := &http.Client{}
	httpResp, err := httpClient.Do(httpReq)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to send reset email: network error"})
		return
	}
	defer httpResp.Body.Close()

	if httpResp.StatusCode >= 400 {
		var errorResponse map[string]interface{}
		json.NewDecoder(httpResp.Body).Decode(&errorResponse)
		errorMsg := "Unknown error"
		if msg, ok := errorResponse["msg"].(string); ok {
			errorMsg = msg
		} else if msg, ok := errorResponse["message"].(string); ok {
			errorMsg = msg
		} else if msg, ok := errorResponse["error_description"].(string); ok {
			errorMsg = msg
		}
		
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to send reset email: " + errorMsg})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Password reset link sent to your email"})
}

func UpdatePasswordHandler(c *gin.Context) {
	// Require the access token from the client in the Authorization header
	authHeader := c.GetHeader("Authorization")
	if authHeader == "" {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Missing Authorization header"})
		return
	}

	var req models.UpdatePasswordRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	supabaseURL := os.Getenv("SUPABASE_URL")
	supabaseKey := os.Getenv("SUPABASE_KEY")

	body, _ := json.Marshal(map[string]string{"password": req.Password})

	// Forward the update request to Supabase /auth/v1/user
	httpReq, err := http.NewRequest("PUT",
		fmt.Sprintf("%s/auth/v1/user", supabaseURL),
		bytes.NewBuffer(body),
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to build request"})
		return
	}
	httpReq.Header.Set("Content-Type", "application/json")
	httpReq.Header.Set("apikey", supabaseKey)
	httpReq.Header.Set("Authorization", authHeader)

	httpClient := &http.Client{}
	httpResp, err := httpClient.Do(httpReq)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update password: network error"})
		return
	}
	defer httpResp.Body.Close()

	if httpResp.StatusCode >= 400 {
		var errorResponse map[string]interface{}
		json.NewDecoder(httpResp.Body).Decode(&errorResponse)
		errorMsg := "Unknown error"
		if msg, ok := errorResponse["msg"].(string); ok {
			errorMsg = msg
		} else if msg, ok := errorResponse["message"].(string); ok {
			errorMsg = msg
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update password: " + errorMsg})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Password updated successfully"})
}
