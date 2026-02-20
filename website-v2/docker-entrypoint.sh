#!/bin/sh
# Configure frame policy based on ALLOWED_FRAME_ORIGINS env var.
# If set, replace X-Frame-Options with CSP frame-ancestors to allow
# embedding in the kombify Cloud portal.

CONF="/etc/nginx/conf.d/default.conf"

if [ -n "$ALLOWED_FRAME_ORIGINS" ]; then
  sed -i \
    's|add_header X-Frame-Options "SAMEORIGIN" always;|add_header Content-Security-Policy "frame-ancestors '"'"'self'"'"' '"$ALLOWED_FRAME_ORIGINS"'" always;|' \
    "$CONF"
fi

exec nginx -g 'daemon off;'
