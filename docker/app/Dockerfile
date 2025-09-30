FROM php:8.3-fpm

# Install system dependencies
RUN apt-get update && apt-get install -y \
    unzip \
    git \
    curl \
    libpq-dev \
    libsqlite3-dev \
    npm \
    jq \
    && docker-php-ext-install pdo pdo_pgsql pdo_sqlite \
    && rm -rf /var/lib/apt/lists/*

# Install Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Working directory for Laravel app
WORKDIR /var/www

# Copy entrypoint script into container and make executable
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Expose PHP-FPM socket
EXPOSE 9000

# Use custom entrypoint
ENTRYPOINT ["sh", "/usr/local/bin/entrypoint.sh"]
