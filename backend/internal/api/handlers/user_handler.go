package handlers

import (
	"context"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5/pgxpool"
)

type UserHandler struct {
	DB *pgxpool.Pool
}

func NewUserHandler(db *pgxpool.Pool) *UserHandler {
	return &UserHandler{DB: db}
}

type Profile struct {
	ID          string `json:"id"`
	FullName    string `json:"full_name"`
	PhoneNumber string `json:"phone_number"`
	AvatarURL   string `json:"avatar_url"`
	Role        string `json:"role"`
	CreatedAt   string `json:"created_at"`
}

func (h *UserHandler) GetProfile(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "User not authenticated"})
		return
	}

	var profile Profile
	err := h.DB.QueryRow(
		context.Background(),
		"SELECT id, full_name, COALESCE(phone_number, ''), COALESCE(avatar_url, ''), COALESCE(role, 'student'), created_at FROM public.profiles WHERE id = $1",
		userID,
	).Scan(&profile.ID, &profile.FullName, &profile.PhoneNumber, &profile.AvatarURL, &profile.Role, &profile.CreatedAt)

	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Profile not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"data": profile})
}
