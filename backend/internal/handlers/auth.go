package handlers

import (
	"net/http"

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

	// Sign up user via Supabase Go client
	// The client handles password hashing and email verification logic based on your Supabase project settings
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

	// Log in via Supabase
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

	err := auth.Client.Auth.ResetPasswordForEmail(req.Email)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to send reset email: " + err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Password reset link sent",
	})
}
