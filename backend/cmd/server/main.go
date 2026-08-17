package main

import (
	"log"

	"github.com/EthioClass/backend/internal/auth"
	"github.com/EthioClass/backend/internal/config"
	"github.com/EthioClass/backend/internal/database"
	"github.com/EthioClass/backend/internal/routes"
	"github.com/EthioClass/backend/internal/storage"
	"github.com/gin-gonic/gin"
)

func main() {
	log.Println("=== EthioClass Backend Starting ===")

	// --- Load configuration ---
	cfg, err := config.Load()
	if err != nil {
		log.Fatalf("[CONFIG] Fatal: %v", err)
	}
	log.Printf("[CONFIG] Loaded. Port: %s", cfg.Port)

	// --- Supabase DB connection (non-fatal) ---
	db, err := database.Connect(cfg.SupabaseDBURL)
	if err != nil {
		log.Printf("[DB] Warning (non-fatal): %v", err)
	} else {
		database.CheckConnection(db)
		defer db.Close()
	}

	// --- Supabase Auth Client ---
	auth.InitSupabaseAuth()

	// --- Cloudflare R2 (non-fatal) ---
	r2, err := storage.New(cfg.R2AccountID, cfg.R2AccessKey, cfg.R2SecretKey, cfg.R2BucketName)
	if err != nil {
		log.Printf("[R2] Warning (non-fatal): %v", err)
	} else {
		r2.Ping() // minimal connectivity check, does not block startup
	}

	// --- HTTP Server ---
	gin.SetMode(gin.ReleaseMode)
	router := gin.New()
	routes.Register(router, db, r2)

	addr := ":" + cfg.Port
	log.Printf("[SERVER] Listening on %s", addr)
	if err := router.Run(addr); err != nil {
		log.Fatalf("[SERVER] Fatal: %v", err)
	}
}
