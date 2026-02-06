#!/bin/sh

CERT_DIR="/etc/nginx/certs"
KEY_FILE="$CERT_DIR/iscpp.local.key"
CRT_FILE="$CERT_DIR/iscpp.local.crt"

if [ ! -f "$CRT_FILE" ] || [ ! -f "$KEY_FILE" ]; then
  echo "Generate Self signed certificate for iscpp.local"

  mkdir -p "$CERT_DIR"

  openssl req -x509 -nodes -days 3650 \
    -newkey rsa:2048 \
    -keyout "$KEY_FILE" \
    -out "$CRT_FILE" \
    -subj "/C=DE/ST=Dev/L=Local/O=ISCPP/CN=iscpp.local"
fi

exec nginx -g "daemon off;"
