# LactoSync Backend — Laravel API (Docker)

All backend infrastructure for LactoSync lives here — separate from the Flutter app (repo root) and **separate from other Docker projects** (GarageFlow, etc.).

## Why these containers?

| Container | Required? | Purpose |
|-----------|-----------|---------|
| **app** | Yes | Laravel PHP-FPM — runs the API code |
| **nginx** | Yes | Web server — Flutter calls `http://localhost:8080`; PHP-FPM does not serve HTTP by itself |
| **mysql** | Yes | Main database (customers, orders, bills) |
| **redis** | Yes | OTP cache, job queues, rate limits |
| **phpmyadmin** | Dev only | Browser UI for MySQL — optional in production |
| **scheduler** | When jobs go live | Runs morning/evening order log, billing, vacation expiry (cron) |
| **queue** | When jobs go live | Processes WhatsApp OTP, PDF generation, heavy async work |

Scheduler and queue use Docker profile `workers` so day-to-day API dev stays lean:

```bash
# API + DB only (default)
docker compose up -d

# Full stack including cron + background jobs
docker compose --profile workers up -d
```

## Quick start

```bash
cd lactosync
docker compose up -d --build
docker compose exec app php artisan migrate
```

| Service | URL |
|---------|-----|
| API | http://localhost:8080 |
| Health | http://localhost:8080/api/v1/health |
| phpMyAdmin | http://localhost:8081 |

Copy `src/.env.example` → `src/.env`. Set `WHATSAPP_ACCESS_TOKEN` and `WHATSAPP_PHONE_NUMBER_ID` — OTP sends only via real WhatsApp API.

Onboard via Flutter **Create account** or `POST /api/v1/auth/register`. No demo users are seeded.

## Layout

```
lactosync/           ← you are here (Docker + Laravel)
  docker-compose.yml
  Dockerfile
  docker/
  src/               Laravel application
lib/                 Flutter mobile app (repo root)
```

## Project isolation

`name: lactosync` in compose + `COMPOSE_PROJECT_NAME=lactosync` prevents collision with other apps that also use a folder named `api`.
