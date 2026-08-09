# EthioClass Backend

Go backend for the EthioClass platform.

## Architecture

`
Flutter (Android / Windows Desktop)
    |
    | HTTPS
    v
https://api.ethioclass.com
    |
    v
Cloudflare (DNS + TLS — Full Strict)
    |
    v
Contabo VPS → Nginx → Go Backend Container
    |
    +-- Supabase (PostgreSQL + Auth)
    +-- Cloudflare R2 (Object Storage)
`

## Local Development

`ash
cp .env.example .env
# Fill in your .env values
go run ./cmd/server
`

Test the health endpoint:
`ash
curl http://localhost:8080/health
# Expected: {"status":"ok"}
`

## Environment Variables

See .env.example for all required variables.
**Never commit .env to Git.**

## Production Deployment

The backend runs inside Docker on the Contabo VPS.
See the root docker-compose.yml for the full stack.

Nginx certificates must exist at /etc/nginx/ssl/ on the VPS
(Cloudflare Origin Certificate — generate from CF dashboard).

`ash
# On VPS:
git pull origin main
docker compose up -d --build
docker compose exec backend wget -qO- http://localhost:8080/health
`
"@ | Set-Content -Encoding UTF8 C:\Users\hp\Desktop\EthioClass\backend\README.md

@"
# EthioClass

An educational platform for Ethiopian students.

## Project Structure

`
EthioClass/
├── flutter/     Flutter app (Android user + Windows admin)
├── backend/     Go REST API
├── docker/      Dockerfiles
├── nginx/       Nginx configuration
└── supabase/    Database migrations
`

## Architecture

`
Flutter → https://api.ethioclass.com → Cloudflare → Contabo VPS → Nginx → Go Backend
                                                                              |
                                                                    Supabase + Cloudflare R2
`

## Quick Start

See ackend/README.md and lutter/README.md for setup instructions.
