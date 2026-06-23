#!/bin/bash
# Runs once on first Postgres init. Creates an isolated role + database per app
# (the casino stays on its own SQLite, so it is not here). Passwords come from
# the container environment so nothing secret lives in this file.
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
  CREATE USER ticketing_user WITH PASSWORD '${TICKETING_DB_PASSWORD}';
  CREATE DATABASE ticketing OWNER ticketing_user;

  CREATE USER mockbank_user WITH PASSWORD '${MOCKBANK_DB_PASSWORD}';
  CREATE DATABASE mockbank OWNER mockbank_user;
EOSQL
