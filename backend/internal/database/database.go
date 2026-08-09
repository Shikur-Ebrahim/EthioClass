package database

import (
	"context"
	"database/sql"
	"fmt"
	"log"
	"time"

	_ "github.com/jackc/pgx/v5/stdlib"
)

// Connect opens a connection to the Supabase Postgres database.
// This is a NON-FATAL check — if it fails the server still starts.
func Connect(dbURL string) (*sql.DB, error) {
	if dbURL == "" {
		return nil, fmt.Errorf("SUPABASE_DB_URL not set — skipping direct DB connection")
	}

	db, err := sql.Open("pgx", dbURL)
	if err != nil {
		return nil, fmt.Errorf("failed to open DB: %w", err)
	}

	db.SetMaxOpenConns(10)
	db.SetMaxIdleConns(5)
	db.SetConnMaxLifetime(5 * time.Minute)

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := db.PingContext(ctx); err != nil {
		db.Close()
		return nil, fmt.Errorf("DB ping failed: %w", err)
	}

	return db, nil
}

// CheckConnection verifies the DB is still alive. Logs result. Non-fatal.
func CheckConnection(db *sql.DB) {
	if db == nil {
		log.Println("[DB] No database connection — skipping ping")
		return
	}
	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()
	if err := db.PingContext(ctx); err != nil {
		log.Printf("[DB] Ping failed: %v", err)
	} else {
		log.Println("[DB] Supabase connected ✓")
	}
}
