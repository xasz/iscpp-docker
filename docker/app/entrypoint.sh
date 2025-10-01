#!/bin/sh
set -e

APP_DIR=/var/www
GITHUB_REPO="xasz/ISCPP"
GITHUB_BRANCH=$ISCPP_BRANCH

cd $APP_DIR

if [ "$ISCPP_CA_IMPORT" = "1" ]; then
  echo "Importing custom CA"
  update-ca-certificates
  echo "openssl.cafile=/etc/ssl/certs/ca-certificates.crt" > /usr/local/etc/php/conf.d/99-ca.ini
  echo "curl.cainfo=/etc/ssl/certs/ca-certificates.crt" >> /usr/local/etc/php/conf.d/99-ca.ini
else
  echo "No custom CA provided, skipping import."
fi

install_app () {
    echo "🔄 Fetching ISCPP from GitHub..."

  if [ -n "$GITHUB_BRANCH" ]; then
      echo "ℹ️ Using branch: $GITHUB_BRANCH"
      TAR_URL="https://github.com/$GITHUB_REPO/archive/refs/heads/$GITHUB_BRANCH.tar.gz"
  else
      echo "ℹ️ Using latest release"
      TAR_URL=$(curl -s https://api.github.com/repos/$GITHUB_REPO/releases/latest | jq -r '.tarball_url')
  fi

  echo "Download URL: $TAR_URL"

  curl -L "$TAR_URL" -o /tmp/iscpp_download.tar.gz

  if tar tzf /tmp/iscpp_download.tar.gz >/dev/null 2>&1; then

    echo "Download successful, extracting..."
    tar xz --strip-components=1 -C "$APP_DIR" -f /tmp/iscpp_download.tar.gz
  else
    echo "Download failed or not a valid tar.gz file:"
    cat /tmp/iscpp_download.tar.gz
    exit 1
  fi


  if [ ! -f ".env" ]; then
      echo "Creating .env file..."
      touch .env
      echo "APP_KEY=" >> .env
  fi
  
  echo "📦 Installing Composer dependencies..."
  composer install --no-dev --optimize-autoloader $COMPOSER_OPTIONS

  echo "⚙️ Running NPM setup..."
  npm install
  npm run build


  echo "⚙️ Running Laravel setup..."
  if ! grep -q "APP_KEY=" .env || grep -q "APP_KEY=$" .env; then
      echo "Generating new APP_KEY..."
      php artisan key:generate --force
  fi

  update_config

  php artisan migrate --force

  touch $APP_DIR/.installed
  echo "✅ ISCPP installation complete."
}

upgrade_app () {
  echo "🚀 Upgrading ISCPP to latest version..."

  echo "Backing up existing .env..."
  mv .env /tmp/.env.backup
  
  echo "Cleaning up old files..."
  rm -r $APP_DIR/*

  echo "Restoring .env from backup..."
  mv /tmp/.env.backup .env

  install_app
}

set_config() {
    key=$1
    value=$2
    if grep -q "^$key=" .env; then
        sed -i "s|^$key=.*|$key=$value|" .env
    else
        echo "$key=$value" >> .env
    fi
}

update_config() {
  echo "🔧 Updating configuration from environment variables..."

  # Use ISCPP__APP_KEY if set, otherwise fallback to existing APP_KEY in .env
  if [ -n "$ISCPP__APP_KEY" ]; then
      echo "Setting APP_KEY from ISCPP__APP_KEY environment variable."
      set_config "APP_KEY" "$ISCPP__APP_KEY"
  fi
  
  set_config "APP_ENV" "$ISCPP_APP_ENV"
  set_config "APP_DEBUG" "$ISCPP_APP_DEBUG"
  set_config "APP_URL" "$ISCPP_APP_URL"
  set_config "USER_DEFAULT_TIMEZONE" "$ISCPP_USER_DEFAULT_TIMEZONE"

  set_config "DB_CONNECTION" "$ISCPP_DB_CONNECTION"
  set_config "DB_HOST" "$ISCPP_DB_HOST"
  set_config "DB_PORT" "$ISCPP_DB_PORT"
  set_config "DB_DATABASE" "$ISCPP_DB_DATABASE"
  set_config "DB_USERNAME" "$ISCPP_DB_USERNAME"
  set_config "DB_PASSWORD" "$ISCPP_DB_PASSWORD"


  set_config "BROADCAST_CONNECTION" "log"

  if [ "$ISCPP_EXPOSE_CONFIG" = "1" ]; then
    echo "⚠️ ISCPP_EXPOSE_CONFIG is enabled. Exposing .env contents:"
    echo "---------- ISCPP .ENV FILE ----------"
    cat .env
    echo "---------- ISCPP .ENV END ----------"
    echo "Configuration update complete."
  fi
}

if [ "$1" = "upgrade-iscpp" ]; then
  upgrade_app
  exit 0
fi

# First-time install if not already installed
if [ ! -f "$APP_DIR/.installed" ]; then
  install_app
else
  if [ "$ISCPP_AUTO_UPDATE" = "1" ]; then
    echo "🔄 Auto-update is enabled. Checking for updates..."
    upgrade_app
  fi
fi


update_config

echo "Fixing permissions..."
chown -R www-data:www-data /var/www
chmod -R 755 /var/www/storage

# Start services
exec php-fpm
