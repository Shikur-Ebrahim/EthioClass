package handlers

import (
	"database/sql"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/EthioClass/backend/internal/models"
)

type SettingsRequest struct {
	UserID string `json:"user_id" binding:"required"`
}

func GetSettingsHandler(db *sql.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		userId := c.Query("user_id")
		if userId == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "user_id is required"})
			return
		}

		var settings models.UserSettings
		query := `SELECT theme, download_quality, push_notifications, email_notifications, language FROM user_settings WHERE user_id = $1`
		err := db.QueryRow(query, userId).Scan(
			&settings.Theme,
			&settings.DownloadQuality,
			&settings.PushNotifications,
			&settings.EmailNotifications,
			&settings.Language,
		)

		if err == sql.ErrNoRows {
			// Return defaults
			settings = models.UserSettings{
				Theme:              "system",
				DownloadQuality:    "720p",
				PushNotifications:  true,
				EmailNotifications: true,
				Language:           "en",
			}
			c.JSON(http.StatusOK, settings)
			return
		} else if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch settings"})
			return
		}

		c.JSON(http.StatusOK, settings)
	}
}

type UpdateSettingsRequest struct {
	UserID             string `json:"user_id" binding:"required"`
	Theme              string `json:"theme"`
	DownloadQuality    string `json:"downloadQuality"`
	PushNotifications  bool   `json:"pushNotifications"`
	EmailNotifications bool   `json:"emailNotifications"`
	Language           string `json:"language"`
}

func UpdateSettingsHandler(db *sql.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		var req UpdateSettingsRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}

		query := `
			INSERT INTO user_settings (user_id, theme, download_quality, push_notifications, email_notifications, language, updated_at)
			VALUES ($1, $2, $3, $4, $5, $6, now())
			ON CONFLICT (user_id) DO UPDATE SET
				theme = EXCLUDED.theme,
				download_quality = EXCLUDED.download_quality,
				push_notifications = EXCLUDED.push_notifications,
				email_notifications = EXCLUDED.email_notifications,
				language = EXCLUDED.language,
				updated_at = now();
		`

		_, err := db.Exec(query, req.UserID, req.Theme, req.DownloadQuality, req.PushNotifications, req.EmailNotifications, req.Language)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update settings"})
			return
		}

		c.JSON(http.StatusOK, gin.H{"message": "Settings updated successfully"})
	}
}
