#!/bin/sh
set -e

APP_DIR=/var/www
cd $APP_DIR

while true; do
  php artisan schedule:run
  sleep 60
done
