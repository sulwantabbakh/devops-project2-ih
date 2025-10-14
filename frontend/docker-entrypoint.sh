#!/bin/sh
set -e

# Runtime injection for API base URL into built assets
# Build-time placeholder must be __API_BASE_URL__

TARGET_DIR="/usr/share/nginx/html"
PLACEHOLDER="__API_BASE_URL__"

if [ -n "$VITE_API_BASE_URL" ]; then
  echo "[entrypoint] Injecting VITE_API_BASE_URL=$VITE_API_BASE_URL"
  # Replace in all js, css, html files
  grep -RIl "$PLACEHOLDER" "$TARGET_DIR" | while read -r file; do
    sed -i "s|$PLACEHOLDER|$VITE_API_BASE_URL|g" "$file"
  done
else
  echo "[entrypoint] VITE_API_BASE_URL not set; using built-in placeholder/default"
fi

exec nginx -g "daemon off;"

