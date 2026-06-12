# DevOps Runbook — LactoSync Admin Panel

> Author: DevOps / Release Engineer · Story: T1-20 · Date: 2026-06-06
> Subdomain: `superadmin.lactosync.com` · VPS: Hostinger · Decision: OQ-7

---

## Files produced by this story

| File | Purpose |
|------|---------|
| `admin-web/nginx.conf` | Nginx server block for the admin SPA |
| `admin-web/.env.production` | Vite build-time environment variables |
| `admin-web/deploy.sh` | One-command build + rsync deploy script |

---

## First-time setup (one-time, on the VPS)

Run these steps once when deploying to a new server. Replace `<VPS_IP>` with the actual IP address of the Hostinger VPS.

### 1. SSH into the VPS

```bash
ssh root@<VPS_IP>
```

### 2. Create the web root directory

```bash
mkdir -p /var/www/lactosync-admin/dist
```

### 3. Copy the Nginx config

From your local machine:

```bash
scp admin-web/nginx.conf root@<VPS_IP>:/etc/nginx/sites-available/lactosync-admin
```

Or paste the contents directly on the VPS into `/etc/nginx/sites-available/lactosync-admin`.

### 4. Enable the site

```bash
ln -s /etc/nginx/sites-available/lactosync-admin /etc/nginx/sites-enabled/lactosync-admin
```

### 5. Test Nginx configuration

```bash
nginx -t
```

Fix any errors before proceeding.

### 6. Add DNS A record

In your DNS provider panel (Hostinger DNS zone editor):

| Type | Name | Value | TTL |
|------|------|-------|-----|
| A | superadmin | `<VPS_IP>` | 300 |

Hostinger DNS changes typically propagate within 5 minutes.

### 7. Reload Nginx (HTTP-only, before TLS)

```bash
systemctl reload nginx
```

Verify `http://superadmin.lactosync.com` responds (it will redirect to HTTPS and fail — that is expected at this point, confirming DNS is live).

### 8. Obtain TLS certificate via Certbot

```bash
certbot --nginx -d superadmin.lactosync.com
```

Certbot will automatically update the Nginx config with the certificate paths and reload the service. If Certbot is not installed:

```bash
apt install certbot python3-certbot-nginx -y
```

### 9. Reload Nginx (with TLS active)

```bash
systemctl reload nginx
```

At this point `https://superadmin.lactosync.com` should serve a blank page or a 404 (no `dist/` content yet).

### 10. Run Laravel migrations (one-time)

```bash
cd /path/to/laravel
php artisan migrate
```

### 11. Seed the admin user

```bash
php artisan db:seed --class=AdminUserSeeder
```

This creates the single super-admin account. Confirm the PIN is stored as a bcrypt hash — never in plain text.

### 12. Configure `.env.production` on your local machine

Edit `admin-web/.env.production`:

```
VITE_API_BASE_URL=https://<your-laravel-domain>
```

Replace `<your-laravel-domain>` with the actual domain or IP serving the Laravel API (e.g. `lactosync.com` or `api.lactosync.com`).

### 13. Run the first deploy

```bash
cd admin-web
chmod +x deploy.sh
./deploy.sh
```

The script builds the React SPA (`npm run build`) and rsyncs `dist/` to `/var/www/lactosync-admin/dist/` on the VPS.

### 14. Verify

Open `https://superadmin.lactosync.com` in a browser. The login page should load. Navigate to a deep route like `https://superadmin.lactosync.com/dashboard` directly — it must return the SPA shell, not a 404 (confirms the `try_files` rewrite is working).

---

## Subsequent deploys (after any React change)

```bash
cd admin-web
./deploy.sh
```

This is the only command needed after any change to the React source. The script:
1. Runs `npm run build` to produce a fresh `dist/`
2. Uses `rsync --delete` to sync only changed files, removing stale ones

No Nginx reload is required — static files are served directly from disk.

**Override VPS connection details if needed:**

```bash
VPS_USER=ubuntu VPS_HOST=<VPS_IP> ./deploy.sh
```

---

## Laravel changes (migrations and new seeders)

```bash
ssh root@<VPS_IP>
cd /path/to/laravel
php artisan migrate
```

If queue workers are running (e.g. for job dispatch):

```bash
php artisan queue:restart
```

---

## Laravel CORS configuration

The admin SPA makes API calls from `https://superadmin.lactosync.com` to the Laravel API domain. Ensure the following on the VPS Laravel `.env`:

```
SANCTUM_STATEFUL_DOMAINS=superadmin.lactosync.com
SESSION_DOMAIN=.lactosync.com
```

Also verify `config/cors.php` includes the admin domain in `allowed_origins`:

```php
'allowed_origins' => [
    'https://superadmin.lactosync.com',
    // existing origins...
],
```

If the Laravel API is served from the same VPS under a different domain, ensure `Access-Control-Allow-Origin: https://superadmin.lactosync.com` is returned on all admin API responses.

---

## Route isolation note

The admin SPA (`superadmin.lactosync.com`) and the existing Flutter API (`lactosync.com` or its domain) are served by separate Nginx server blocks. There is no overlap in location blocks. The admin Nginx config in `admin-web/nginx.conf` only handles static file serving — it does not proxy any Laravel routes. Laravel routes remain exclusively on the existing server block for the main domain.

---

## Certificate renewal

Certbot auto-renews certificates via a systemd timer or cron job installed at setup time. No manual action is needed. To verify the renewal timer is active:

```bash
systemctl status certbot.timer
```

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| `https://superadmin.lactosync.com` shows "connection refused" | Nginx not running or port 443 blocked | `systemctl start nginx`; check firewall allows 443 |
| Deep route (e.g. `/dashboard`) returns Nginx 404 | `try_files` not in Nginx config | Confirm the `location /` block contains `try_files $uri $uri/ /index.html` |
| Blank page with console CORS errors | `SANCTUM_STATEFUL_DOMAINS` not set | Add `superadmin.lactosync.com` to Laravel `.env` and `config/cors.php` |
| `certbot --nginx` fails with "Could not bind to port 80" | Another process on port 80 | `systemctl stop apache2` (if installed); then retry |
| Assets load but API calls return 401 | Token not being sent | Confirm Axios/fetch sends `Authorization: Bearer <token>` header; check Sanctum guard config |
