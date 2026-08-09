package auth

import (
	"log"
	"os"

	"github.com/supabase-community/supabase-go"
)

var Client *supabase.Client

func InitSupabaseAuth() {
	supabaseURL := os.Getenv("SUPABASE_URL")
	supabaseKey := os.Getenv("SUPABASE_KEY") // Typically service_role key for backend operations

	if supabaseURL == "" || supabaseKey == "" {
		log.Fatal("SUPABASE_URL or SUPABASE_KEY missing in environment variables")
	}

	client, err := supabase.NewClient(supabaseURL, supabaseKey, nil)
	if err != nil {
		log.Fatalf("cannot initialize Supabase client: %v", err)
	}

	Client = client
	log.Println("[Auth] Supabase client initialized")
}
