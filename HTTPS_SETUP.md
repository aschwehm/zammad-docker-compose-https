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

- `docker-compose.yml` - Updated zammad-nginx service with embedded SSL config and certificate generation
- `.env` - Environment variables
- `certs/` - Directory (certificates now generated inside container)
- `zammad_ssl.conf` - Reference SSL configuration (not used, embedded in docker-compose)

## Technical Details

**Certificate Generation**: Self-signed certificates are generated inside the Linux container to avoid Windows-to-Linux file mounting issues:

```bash
openssl req -newkey rsa:4096 -nodes -x509 -days 1825 -subj "/CN=zammad.local" \
  -keyout /etc/nginx/ssl/zammad.key -out /etc/nginx/ssl/zammad.crt
```

**Configuration Management**: Complete nginx configuration management to avoid conflicts:

```yaml
command: 
  - sh
  - -c
  - |
    mkdir -p /etc/nginx/ssl /etc/nginx/sites-enabled /etc/nginx/sites-available
    # Generate certificate inside container
    openssl req -newkey rsa:4096 -nodes -x509 -days 1825 -subj "/CN=zammad.local" \
      -keyout /etc/nginx/ssl/zammad.key -out /etc/nginx/ssl/zammad.crt
    # Remove conflicting configurations
    rm -f /etc/nginx/sites-enabled/*
    rm -f /etc/nginx/sites-available/*
    # Create our SSL configuration
    cat > /etc/nginx/sites-available/zammad.conf << 'EOF'
    [server blocks]
    EOF
    # Enable our configuration properly
    ln -s /etc/nginx/sites-available/zammad.conf /etc/nginx/sites-enabled/zammad.conf
    exec /docker-entrypoint.sh zammad-nginx
```

**Key advantages:**
1. **No file mounting issues**: Everything created inside the Linux container
2. **Clean slate approach**: Removes all existing nginx configurations that might conflict
3. **Proper nginx site management**: Uses standard sites-available/sites-enabled pattern
4. **Self-contained**: No external dependencies on Windows certificate files
5. **Fresh certificates**: New certificate generated on each container start
6. **No SSL conflicts**: Eliminates default SSL configurations that lack certificates

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
