#!/usr/bin/env bash
set -e

echo "Running database migrations..."
bundle exec rails db:migrate

echo "Starting Puma..."
bundle exec puma -t 5:5 -p ${PORT:-3000} -e ${RACK_ENV:-development}
