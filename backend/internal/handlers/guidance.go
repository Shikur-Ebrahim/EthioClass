package handlers

import (
	"database/sql"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/EthioClass/backend/internal/models"
)

// GetGuidanceVideosHandler returns all guidance videos ordered by order_index
func GetGuidanceVideosHandler(db *sql.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		query := `SELECT id, title, description, video_url, thumbnail_url, order_index, created_at FROM guidance_videos ORDER BY order_index ASC`
		rows, err := db.Query(query)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch guidance videos"})
			return
		}
		defer rows.Close()

		var videos []models.GuidanceVideo
		for rows.Next() {
			var v models.GuidanceVideo
			var desc, thumb sql.NullString
			if err := rows.Scan(&v.ID, &v.Title, &desc, &v.VideoURL, &thumb, &v.OrderIndex, &v.CreatedAt); err != nil {
				continue
			}
			if desc.Valid {
				v.Description = desc.String
			}
			if thumb.Valid {
				v.ThumbnailURL = thumb.String
			}
			videos = append(videos, v)
		}

		c.JSON(http.StatusOK, videos)
	}
}

// CreateGuidanceVideoHandler adds a new guidance video (Admin)
func CreateGuidanceVideoHandler(db *sql.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		var req struct {
			Title        string `json:"title" binding:"required"`
			Description  string `json:"description"`
			VideoURL     string `json:"video_url" binding:"required"`
			ThumbnailURL string `json:"thumbnail_url"`
			OrderIndex   int    `json:"order_index"`
		}

		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}

		query := `INSERT INTO guidance_videos (title, description, video_url, thumbnail_url, order_index) VALUES ($1, $2, $3, $4, $5) RETURNING id`
		var id string
		err := db.QueryRow(query, req.Title, req.Description, req.VideoURL, req.ThumbnailURL, req.OrderIndex).Scan(&id)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create video"})
			return
		}

		c.JSON(http.StatusCreated, gin.H{"message": "Video created", "id": id})
	}
}

// UpdateGuidanceVideoHandler updates a guidance video (Admin)
func UpdateGuidanceVideoHandler(db *sql.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		id := c.Param("id")
		var req struct {
			Title        string `json:"title" binding:"required"`
			Description  string `json:"description"`
			VideoURL     string `json:"video_url" binding:"required"`
			ThumbnailURL string `json:"thumbnail_url"`
			OrderIndex   int    `json:"order_index"`
		}

		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}

		query := `UPDATE guidance_videos SET title=$1, description=$2, video_url=$3, thumbnail_url=$4, order_index=$5 WHERE id=$6`
		_, err := db.Exec(query, req.Title, req.Description, req.VideoURL, req.ThumbnailURL, req.OrderIndex, id)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update video"})
			return
		}

		c.JSON(http.StatusOK, gin.H{"message": "Video updated"})
	}
}

// DeleteGuidanceVideoHandler deletes a guidance video (Admin)
func DeleteGuidanceVideoHandler(db *sql.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		id := c.Param("id")
		query := `DELETE FROM guidance_videos WHERE id=$1`
		_, err := db.Exec(query, id)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete video"})
			return
		}

		c.JSON(http.StatusOK, gin.H{"message": "Video deleted"})
	}
}
