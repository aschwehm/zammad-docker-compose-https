#!/bin/bash
# Ensure SSL directory exists
mkdir -p /etc/nginx/ssl

# Start the original zammad-nginx command
exec /docker-entrypoint.sh zammad-nginx
