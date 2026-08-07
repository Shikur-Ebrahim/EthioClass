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

	// Initialize Supabase Auth client
	supaClient, err := auth.ConnectSupabaseAuth(cfg.SupabaseURL, cfg.SupabaseKey)
	if err != nil || supaClient == nil {
		log.Fatalf("Failed to initialize Supabase Auth: %v\n", err)
	}

	// Initialize Supabase Database Connection
	dbPool, err := database.ConnectSupabase(cfg.SupabaseDBURL)
	if err != nil || dbPool == nil {
		log.Fatalf("Failed to connect to Database: %v\n", err)
	}
	defer dbPool.Close()

	// Initialize Cloudflare R2 Storage
	_, err = storage.ConnectCloudflareR2(cfg.R2AccountID, cfg.R2AccessKey, cfg.R2SecretKey, cfg.R2BucketName)
	if err != nil {
		log.Printf("Warning: Failed to initialize Cloudflare R2: %v\n", err)
	}

	// Setup Router with dependencies
	router := api.SetupRouter(dbPool, supaClient.Client)

	// Start Server
	log.Printf("Starting EthioClass API server on port %s...\n", cfg.Port)
	if err := router.Run(":" + cfg.Port); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}
