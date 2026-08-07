package config

import (
	"log"
	"os"

	"github.com/joho/godotenv"
)

type Config struct {
	Port           string
	SupabaseURL    string
	SupabaseKey    string
	SupabaseDBURL  string
	R2AccountID    string
	R2AccessKey    string
	R2SecretKey    string
	R2BucketName   string
}

func LoadConfig() *Config {
	err := godotenv.Load()
	if err != nil {
		log.Println("No .env file found, relying on environment variables")
	}

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	return &Config{
		Port:           port,
		SupabaseURL:    os.Getenv("SUPABASE_URL"),
		SupabaseKey:    os.Getenv("SUPABASE_KEY"),
		SupabaseDBURL:  os.Getenv("SUPABASE_DB_URL"),
		R2AccountID:    os.Getenv("R2_ACCOUNT_ID"),
		R2AccessKey:    os.Getenv("R2_ACCESS_KEY"),
		R2SecretKey:    os.Getenv("R2_SECRET_KEY"),
		R2BucketName:   os.Getenv("R2_BUCKET_NAME"),
	}
}
