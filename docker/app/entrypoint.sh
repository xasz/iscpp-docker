#!/bin/sh
set -e

APP_DIR=/var/www
GITHUB_REPO="xasz/ISCPP"
GITHUB_BRANCH="${ISCPP_BRANCH:-main}"

cd $APP_DIR

install_app () {
    echo "🔄 Fetching ISCPP from GitHub..."

  if [ -n "$GITHUB_BRANCH" ]; then
      echo "ℹ️ Using branch: $GITHUB_BRANCH"
      TAR_URL="https://github.com/$GITHUB_REPO/archive/refs/heads/$GITHUB_BRANCH.tar.gz"
  else
      echo "ℹ️ Using latest release"
      TAR_URL=$(curl -s https://api.github.com/repos/$GITHUB_REPO/releases/latest | jq -r '.tarball_url')
  fi

  # App-Verzeichnis sauber machen
  find $APP_DIR -mindepth 1 ! -name ".env" -exec rm -rf {} +
  curl -sL $TAR_URL | tar xz --strip-components=1 -C $APP_DIR

  echo "📦 Installing Composer dependencies..."
  composer install --no-dev --optimize-autoloader

  echo "⚙️ Running NPM setup..."
  npm install
  npm run build


  if [ ! -f ".env" ]; then
      echo "Creating .env file..."
      touch .env
      echo "APP_KEY=" >> .env
  fi

  update_config

  echo "⚙️ Running Laravel setup..."
  if ! grep -q "APP_KEY=" .env || grep -q "APP_KEY=$" .env; then
      echo "Generating new APP_KEY..."
      php artisan key:generate --force
  fi

  php artisan migrate --force

  touch $APP_DIR/.installed
  echo "✅ ISCPP installation complete."
}

upgrade_app () {
  echo "🚀 Upgrading ISCPP to latest version..."
  rm -f $APP_DIR/.installed
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

  # Use MY_APP_KEY if set, otherwise fallback to existing APP_KEY in .env
  if [ -n "$MY_APP_KEY" ]; then
      echo "Setting APP_KEY from MY_APP_KEY environment variable."
      set_config "APP_KEY" "$MY_APP_KEY"
  fi
  set_config "APP_ENV" "${APP_ENV:-production}"
  set_config "APP_DEBUG" "${APP_DEBUG:-false}"
  set_config "APP_URL" "$APP_URL"
  set_config "USER_DEFAULT_TIMEZONE" "$USER_DEFAULT_TIMEZONE"

  set_config "DB_CONNECTION" "pgsql"
  set_config "DB_HOST" "$DB_HOST"
  set_config "DB_PORT" "$DB_PORT"
  set_config "DB_DATABASE" "$DB_DATABASE"
  set_config "DB_USERNAME" "$DB_USERNAME"
  set_config "DB_PASSWORD" "$DB_PASSWORD"

  echo "Show Config"

}

if [ "$1" = "upgrade-iscpp" ]; then
  upgrade_app
  exit 0
fi

# First-time install if not already installed
if [ ! -f "$APP_DIR/.installed" ]; then
  install_app
fi

update_config

# Start services
exec php-fpm
