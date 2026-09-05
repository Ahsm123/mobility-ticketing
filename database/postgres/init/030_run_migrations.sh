#!/bin/sh
set -e

for migration in /migrations/*.sql; do
    echo "Running migration: $migration"
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -f "$migration"
done
