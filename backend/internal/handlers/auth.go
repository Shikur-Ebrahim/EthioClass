package handlers

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"strings"

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
		Phone:    req.PhoneNumber,
		Password: req.Password,
		Data: map[string]interface{}{
			"full_name":    req.FullName,
			"phone_number": req.PhoneNumber,
			"device_id":    req.DeviceId,
		},
	}

	resp, err := auth.Client.Auth.Signup(signupReq)
	if err != nil {
		if strings.Contains(err.Error(), "user_already_exists") {
			c.JSON(http.StatusBadRequest, gin.H{"error": "This email is already registered"})
			return
		}
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
		Password:  req.Password,
	}

	// Check if the input is a phone number (e.g., starts with +, or only contains digits)
	isPhone := true
	for _, c := range req.Email {
		if c != '+' && (c < '0' || c > '9') {
			isPhone = false
			break
		}
	}

	if isPhone && len(req.Email) > 0 {
		tokenReq.Phone = req.Email
	} else {
		tokenReq.Email = req.Email
	}

	resp, err := auth.Client.Auth.Token(tokenReq)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid email or password"})
		return
	}

	// 1-Device Security Check
	if req.DeviceId != "" {
		registeredDeviceID, ok := resp.User.UserMetadata["device_id"].(string)
		
		if ok && registeredDeviceID != "" {
			if registeredDeviceID != req.DeviceId {
				c.JSON(http.StatusForbidden, gin.H{"error": "This account is already registered to another device. You cannot log in from a different device."})
				return
			}
		} else {
			// Device ID not set yet, bind it now!
			err = updateSupabaseUserMetadata(resp.AccessToken, map[string]interface{}{
				"device_id": req.DeviceId,
			})
			if err != nil {
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to bind device to account"})
				return
			}
			// Update the local struct so it reflects what we just did
			resp.User.UserMetadata["device_id"] = req.DeviceId
		}
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Login successful",
		"token":   resp.AccessToken,
		"user":    resp.User,
	})
}

func updateSupabaseUserMetadata(accessToken string, data map[string]interface{}) error {
	supabaseURL := os.Getenv("SUPABASE_URL")
	supabaseKey := os.Getenv("SUPABASE_KEY")

	payload := map[string]interface{}{
		"data": data,
	}
	body, _ := json.Marshal(payload)

	httpReq, err := http.NewRequest("PUT",
		fmt.Sprintf("%s/auth/v1/user", supabaseURL),
		bytes.NewBuffer(body),
	)
	if err != nil {
		return err
	}
	httpReq.Header.Set("Content-Type", "application/json")
	httpReq.Header.Set("apikey", supabaseKey)
	httpReq.Header.Set("Authorization", "Bearer "+accessToken)

	httpClient := &http.Client{}
	httpResp, err := httpClient.Do(httpReq)
	if err != nil {
		return err
	}
	defer httpResp.Body.Close()

	if httpResp.StatusCode >= 400 {
		return fmt.Errorf("failed to update user metadata, status: %d", httpResp.StatusCode)
	}
	return nil
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
		}
		
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to send reset email: " + errorMsg})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Password reset link sent to your email"})
}

func UpdatePasswordHandler(c *gin.Context) {
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
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update password: " + errorMsg})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Password updated successfully"})
}

func UpdateProfileHandler(c *gin.Context) {
	authHeader := c.GetHeader("Authorization")
	if authHeader == "" {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Missing Authorization header"})
		return
	}

	var req models.UpdateProfileRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	supabaseURL := os.Getenv("SUPABASE_URL")
	supabaseKey := os.Getenv("SUPABASE_KEY")

	payload := map[string]interface{}{
		"data": map[string]string{
			"full_name":    req.FullName,
			"phone_number": req.PhoneNumber,
		},
	}
	body, _ := json.Marshal(payload)

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
	httpReq.Header.Set("Authorization", authHeader) // Includes "Bearer ..." from client

	httpClient := &http.Client{}
	httpResp, err := httpClient.Do(httpReq)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update profile: network error"})
		return
	}
	defer httpResp.Body.Close()

	if httpResp.StatusCode >= 400 {
		var errorResponse map[string]interface{}
		json.NewDecoder(httpResp.Body).Decode(&errorResponse)
		errorMsg := "Unknown error"
		if msg, ok := errorResponse["msg"].(string); ok {
			errorMsg = msg
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update profile: " + errorMsg})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Profile updated successfully"})
}
