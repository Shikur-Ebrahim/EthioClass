package main

import (
	"log"

	"github.com/EthioClass/backend/internal/api"
	"github.com/EthioClass/backend/internal/config"
	"github.com/EthioClass/backend/internal/infrastructure/auth"
	"github.com/EthioClass/backend/internal/infrastructure/database"
	"github.com/EthioClass/backend/internal/infrastructure/storage"
)

func main() {
	// Load Configuration
	cfg := config.LoadConfig()

	// Initialize Supabase Database Connection
	dbPool, err := database.ConnectSupabase(cfg.SupabaseDBURL)
	if err != nil {
		log.Printf("Failed to connect to Database: %v\n", err)
	}
	if dbPool != nil {
		defer dbPool.Close()
	}

	// Initialize Supabase Auth
	_, err = auth.ConnectSupabaseAuth(cfg.SupabaseURL, cfg.SupabaseKey)
	if err != nil {
		log.Printf("Failed to initialize Supabase Auth: %v\n", err)
	}

	// Initialize Cloudflare R2 Storage
	_, err = storage.ConnectCloudflareR2(cfg.R2AccountID, cfg.R2AccessKey, cfg.R2SecretKey, cfg.R2BucketName)
	if err != nil {
		log.Printf("Failed to initialize Cloudflare R2: %v\n", err)
	}

	// Setup Router
	router := api.SetupRouter()

	// Start Server
	log.Printf("Starting EthioClass API server on port %s...\n", cfg.Port)
	if err := router.Run(":" + cfg.Port); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}
