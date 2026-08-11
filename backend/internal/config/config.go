package config

import (
	"fmt"
	"os"

	"github.com/joho/godotenv"
)

// Config holds all application configuration loaded from environment variables.
type Config struct {
	Port          string
	SupabaseURL   string
	SupabaseKey   string
	SupabaseDBURL string
	R2AccountID   string
	R2AccessKey   string
	R2SecretKey   string
	R2BucketName  string
}

// Load reads .env (if present) then environment variables.
// Returns an error if required variables are missing.
func Load() (*Config, error) {
	// Load .env file if present (in production, env is injected via docker-compose)
	_ = godotenv.Load()

	cfg := &Config{
		Port:          getEnv("PORT", "8080"),
		SupabaseURL:   os.Getenv("SUPABASE_URL"),
		SupabaseKey:   os.Getenv("SUPABASE_KEY"),
		SupabaseDBURL: os.Getenv("SUPABASE_DB_URL"),
		R2AccountID:   os.Getenv("R2_ACCOUNT_ID"),
		R2AccessKey:   os.Getenv("R2_ACCESS_KEY"),
		R2SecretKey:   os.Getenv("R2_SECRET_KEY"),
		R2BucketName:  os.Getenv("R2_BUCKET_NAME"),
	}

	if cfg.SupabaseURL == "" {
		return nil, fmt.Errorf("SUPABASE_URL is required")
	}
	if cfg.SupabaseKey == "" {
		return nil, fmt.Errorf("SUPABASE_KEY is required")
	}

	return cfg, nil
}

func getEnv(key, defaultVal string) string {
	if val := os.Getenv(key); val != "" {
		return val
	}
	return defaultVal
}
