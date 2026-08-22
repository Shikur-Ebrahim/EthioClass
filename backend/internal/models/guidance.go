package models

import (
	"time"
)

type GuidanceVideo struct {
	ID           string    `json:"id"`
	Title        string    `json:"title"`
	Description  string    `json:"description"`
	VideoURL     string    `json:"video_url"`
	ThumbnailURL string    `json:"thumbnail_url"`
	OrderIndex   int       `json:"order_index"`
	CreatedAt    time.Time `json:"created_at"`
}
