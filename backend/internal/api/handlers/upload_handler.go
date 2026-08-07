package handlers

import (
	"context"
	"fmt"
	"net/http"
	"path/filepath"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/EthioClass/backend/internal/infrastructure/storage"
)

type UploadHandler struct {
	R2Service *storage.R2Service
}

// UploadFile handles multipart form uploads to R2 (e.g. videos, pdfs, images)
func (h *UploadHandler) UploadFile(c *gin.Context) {
	// 1. Check if user is admin (Assuming AuthMiddleware sets "user_role")
	role, exists := c.Get("user_role")
	if !exists || role != "admin" {
		c.JSON(http.StatusForbidden, gin.H{"error": "Only admins can upload files"})
		return
	}

	// 2. Parse file from request
	file, header, err := c.Request.FormFile("file")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Failed to get file from request"})
		return
	}
	defer file.Close()

	// 3. Determine file type & generate object key
	ext := strings.ToLower(filepath.Ext(header.Filename))
	var folder string
	if ext == ".mp4" || ext == ".mov" || ext == ".avi" {
		folder = "videos"
	} else if ext == ".pdf" {
		folder = "documents"
	} else if ext == ".jpg" || ext == ".jpeg" || ext == ".png" {
		folder = "images"
	} else {
		folder = "others"
	}

	objectKey := fmt.Sprintf("%s/%s%s", folder, uuid.New().String(), ext)
	contentType := header.Header.Get("Content-Type")
	if contentType == "" {
		contentType = "application/octet-stream"
	}

	// 4. Upload to R2
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Minute) // Videos can be large
	defer cancel()

	err = h.R2Service.UploadFile(ctx, file, objectKey, contentType)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to upload file to R2: " + err.Error()})
		return
	}

	// Return the object key (which will be stored in the database)
	c.JSON(http.StatusOK, gin.H{
		"message":    "File uploaded successfully",
		"object_key": objectKey,
	})
}

// GetPresignedURL generates a temporary read URL for a given object key
func (h *UploadHandler) GetPresignedURL(c *gin.Context) {
	objectKey := c.Query("key")
	if objectKey == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "object key is required"})
		return
	}

	// Give a 2-hour expiration
	url, err := h.R2Service.GeneratePresignedURL(context.Background(), objectKey, 2*time.Hour)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to generate presigned URL: " + err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"url": url})
}
