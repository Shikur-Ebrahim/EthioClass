package main

import (
	"database/sql"
	"fmt"
	"os"

	_ "github.com/lib/pq"
)

func main() {
	dbURL := "postgresql://postgres.ogbwhbzptrzjdetyygxt:shikur%403828%40@aws-1-eu-west-1.pooler.supabase.com:5432/postgres"
	db, err := sql.Open("postgres", dbURL)
	if err != nil {
		panic(err)
	}
	defer db.Close()

	schema, err := os.ReadFile("../db_payments.sql")
	if err != nil {
		panic(err)
	}

	_, err = db.Exec(string(schema))
	if err != nil {
		panic(err)
	}

	fmt.Println("Schema migration successful!")
}
