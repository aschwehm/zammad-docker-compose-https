# Zammad Docker Compose HTTPS Setup

This configuration runs Zammad with HTTPS enabled using self-signed certificates.

## Configuration Changes Made

1. **Port Configuration:**
   - HTTPS: Port 12349 (mapped from container port 443)
   - HTTP: Port 12399 (mapped from container port 80, redirects to HTTPS)

2. **SSL Certificate:**
   - Self-signed certificate generated in `certs/` directory
   - Valid for 5 years
   - Common Name: `zammad.local`

3. **Environment Variables:**
   - `NGINX_PORT=443` - Internal HTTPS port
   - `NGINX_SERVER_SCHEME=https` - Forces HTTPS scheme
   - `NGINX_SERVER_NAME=_` - Accept any hostname

## Files Added/Modified

- `docker-compose.yml` - Updated zammad-nginx service configuration
- `certs/zammad.crt` - Self-signed SSL certificate
- `certs/zammad.key` - SSL private key
- `zammad_ssl.conf` - Nginx SSL configuration
- `.env` - Environment variables

## Technical Details

The configuration uses an inline command to create the necessary directories and copy the configuration file:
```bash
sh -c "mkdir -p /etc/nginx/ssl /etc/nginx/sites-enabled && cp /tmp/zammad_ssl.conf /etc/nginx/sites-enabled/zammad.conf && exec /docker-entrypoint.sh zammad-nginx"
```

This approach:
1. Creates the SSL directory for certificates
2. Creates the sites-enabled directory for nginx configuration
3. Copies our SSL configuration from `/tmp` to the proper location
4. Starts the original Zammad nginx service

The configuration file is mounted to `/tmp/zammad_ssl.conf` to avoid Docker volume mounting issues with non-existent directories.

## Usage

1. Deploy the stack:
   ```bash
   docker compose up -d
   ```

2. Access Zammad:
   - HTTPS: `https://your-host:12349`
   - HTTP (redirects): `http://your-host:12399`

## Caddy Reverse Proxy Integration

To use with Caddy as a reverse proxy, configure Caddy to proxy to:
- `https://your-docker-host:12349`

Since this uses a self-signed certificate, you may need to configure Caddy to skip certificate verification:
```caddyfile
your.domain.com {
    reverse_proxy https://your-docker-host:12349 {
        transport http {
            tls_insecure_skip_verify
        }
    }
}
```

## Security Notes

- The self-signed certificate will show browser warnings when accessed directly
- For production use, consider using proper certificates or configure Caddy to handle SSL termination
- The configuration forces HTTPS scheme to prevent CSRF token issues

## Regenerating Certificates

To regenerate the self-signed certificate:
```bash
openssl req -newkey rsa:4096 -nodes -x509 -days 1825 -subj "/CN=your.domain.com" \
  -keyout certs/zammad.key -out certs/zammad.crt
```
