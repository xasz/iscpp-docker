#!/bin/sh
set -e

APP_DIR=/var/www
cd $APP_DIR

while true; do
  php artisan queue:work
  sleep 1
done
