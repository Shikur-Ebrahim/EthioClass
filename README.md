# EthioClass

Production-ready enterprise infrastructure for EthioClass.

## Infrastructure
- **VPS**: Contabo VPS
- **Domain**: ethioclass.com (Proxy via Cloudflare)
- **Containerization**: Docker & Docker Compose
- **Reverse Proxy**: Nginx

## Tech Stack
- **Frontend**: Flutter, Riverpod, GoRouter, Dio
- **Backend**: Go (Gin Framework)
- **Database**: Supabase PostgreSQL
- **Authentication**: Supabase Auth
- **Storage**: Cloudflare R2 Object Storage (Videos & PDFs)

## Directory Structure
- `/frontend`: Flutter application (Clean Architecture).
- `/backend`: Go Gin API (Clean Architecture).
- `/docker`: Dockerfiles and container-related scripts.
- `/nginx`: Nginx reverse proxy configurations for SSL and routing.
- `docker-compose.yml`: Orchestration file for deployment.

## Deployment on VPS
1. Clone the repository on your Contabo VPS.
2. Ensure Docker and Docker Compose are installed.
3. Configure your Cloudflare Origin SSL certificates in `/nginx/ssl/` (or update `nginx/conf.d/ethioclass.com.conf` for Let's Encrypt / Certbot).
4. Create `.env` files in `backend/` and `frontend/` directories by copying from `.env.example`.
5. Run the deployment:
   ```bash
   docker-compose up -d --build
   ```
