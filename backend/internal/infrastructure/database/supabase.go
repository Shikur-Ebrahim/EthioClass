package database

import (
	"context"
	"log"

	"github.com/jackc/pgx/v5/pgxpool"
)

func ConnectSupabase(dbUrl string) (*pgxpool.Pool, error) {
	if dbUrl == "" {
		log.Println("SUPABASE_DB_URL is not set")
		return nil, nil
	}
	
	pool, err := pgxpool.New(context.Background(), dbUrl)
	if err != nil {
		return nil, err
	}

	// Test connection
	err = pool.Ping(context.Background())
	if err != nil {
		return nil, err
	}

	log.Println("Successfully connected to Supabase PostgreSQL")
	return pool, nil
}
