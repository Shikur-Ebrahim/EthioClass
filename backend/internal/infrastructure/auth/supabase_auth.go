package auth

import (
	"log"

	"github.com/supabase-community/supabase-go"
)

type SupabaseAuth struct {
	Client *supabase.Client
}

func ConnectSupabaseAuth(supabaseURL, supabaseKey string) (*SupabaseAuth, error) {
	if supabaseURL == "" || supabaseKey == "" {
		log.Println("Supabase credentials are not fully set")
		return nil, nil
	}

	client, err := supabase.NewClient(supabaseURL, supabaseKey, nil)
	if err != nil {
		return nil, err
	}

	log.Println("Successfully initialized Supabase Auth client")
	return &SupabaseAuth{Client: client}, nil
}
