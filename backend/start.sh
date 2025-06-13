#!/bin/bash

echo "Starting Django application..."

echo "Running database migrations..."
python manage.py migrate --run-syncdb

echo "Collecting static files..."
python manage.py collectstatic --noinput

echo "Starting Gunicorn server..."
exec gunicorn nyota_bank.wsgi:application --bind 0.0.0.0:$PORT --log-file - 