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
	r2Svc, err := storage.NewR2Service(cfg)
	if err != nil {
		log.Printf("Warning: Failed to initialize Cloudflare R2: %v\n", err)
	}

	// Setup Router with dependencies
	router := api.SetupRouter(dbPool, supaClient.Client, r2Svc)

	// Start Server
	log.Printf("Starting EthioClass API server on port %s...\n", cfg.Port)
	if err := router.Run(":" + cfg.Port); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}
