package handlers

import (
	"database/sql"
	"fmt"
	"net/http"
	"path/filepath"
	"strconv"

	"github.com/EthioClass/backend/internal/models"
	"github.com/EthioClass/backend/internal/storage"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
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

// CreateGuidanceVideoHandler adds a new guidance video with multipart file uploads
func CreateGuidanceVideoHandler(db *sql.DB, r2 *storage.R2Client) gin.HandlerFunc {
	return func(c *gin.Context) {
		title := c.PostForm("title")
		description := c.PostForm("description")
		orderIndex, _ := strconv.Atoi(c.PostForm("order_index"))

		if title == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "title is required"})
			return
		}

		var thumbnailURL, videoURL *string

		// Upload video
		if file, header, err := c.Request.FormFile("video"); err == nil {
			defer file.Close()
			ext := filepath.Ext(header.Filename)
			if ext == "" {
				ext = ".mp4"
			}
			key := fmt.Sprintf("guidance/videos/%s%s", uuid.New().String(), ext)
			uploaded, err := r2.UploadFile(c.Request.Context(), file, key, header.Header.Get("Content-Type"))
			if err == nil {
				videoURL = &uploaded
			} else {
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to upload video: " + err.Error()})
				return
			}
		} else {
			c.JSON(http.StatusBadRequest, gin.H{"error": "video file is required"})
			return
		}

		// Upload thumbnail
		if file, header, err := c.Request.FormFile("thumbnail"); err == nil {
			defer file.Close()
			ext := filepath.Ext(header.Filename)
			if ext == "" {
				ext = ".jpg"
			}
			key := fmt.Sprintf("guidance/thumbnails/%s%s", uuid.New().String(), ext)
			uploaded, err := r2.UploadFile(c.Request.Context(), file, key, header.Header.Get("Content-Type"))
			if err == nil {
				thumbnailURL = &uploaded
			}
		}

		query := `INSERT INTO guidance_videos (title, description, video_url, thumbnail_url, order_index) VALUES ($1, $2, $3, $4, $5) RETURNING id`
		var id string
		err := db.QueryRow(query, title, description, videoURL, thumbnailURL, orderIndex).Scan(&id)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create video"})
			return
		}

		c.JSON(http.StatusCreated, gin.H{"message": "Video created", "id": id})
	}
}

// UpdateGuidanceVideoHandler updates a guidance video
func UpdateGuidanceVideoHandler(db *sql.DB, r2 *storage.R2Client) gin.HandlerFunc {
	return func(c *gin.Context) {
		id := c.Param("id")
		title := c.PostForm("title")
		description := c.PostForm("description")
		orderIndex, _ := strconv.Atoi(c.PostForm("order_index"))

		if title == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "title is required"})
			return
		}

		var thumbnailURL, videoURL *string

		if file, header, err := c.Request.FormFile("video"); err == nil {
			defer file.Close()
			ext := filepath.Ext(header.Filename)
			if ext == "" {
				ext = ".mp4"
			}
			key := fmt.Sprintf("guidance/videos/%s%s", uuid.New().String(), ext)
			uploaded, err := r2.UploadFile(c.Request.Context(), file, key, header.Header.Get("Content-Type"))
			if err == nil {
				videoURL = &uploaded
			}
		}

		if file, header, err := c.Request.FormFile("thumbnail"); err == nil {
			defer file.Close()
			ext := filepath.Ext(header.Filename)
			if ext == "" {
				ext = ".jpg"
			}
			key := fmt.Sprintf("guidance/thumbnails/%s%s", uuid.New().String(), ext)
			uploaded, err := r2.UploadFile(c.Request.Context(), file, key, header.Header.Get("Content-Type"))
			if err == nil {
				thumbnailURL = &uploaded
			}
		}

		var query string
		var err error

		if videoURL != nil && thumbnailURL != nil {
			query = `UPDATE guidance_videos SET title=$1, description=$2, order_index=$3, video_url=$4, thumbnail_url=$5 WHERE id=$6`
			_, err = db.Exec(query, title, description, orderIndex, videoURL, thumbnailURL, id)
		} else if videoURL != nil {
			query = `UPDATE guidance_videos SET title=$1, description=$2, order_index=$3, video_url=$4 WHERE id=$5`
			_, err = db.Exec(query, title, description, orderIndex, videoURL, id)
		} else if thumbnailURL != nil {
			query = `UPDATE guidance_videos SET title=$1, description=$2, order_index=$3, thumbnail_url=$4 WHERE id=$5`
			_, err = db.Exec(query, title, description, orderIndex, thumbnailURL, id)
		} else {
			query = `UPDATE guidance_videos SET title=$1, description=$2, order_index=$3 WHERE id=$4`
			_, err = db.Exec(query, title, description, orderIndex, id)
		}

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
