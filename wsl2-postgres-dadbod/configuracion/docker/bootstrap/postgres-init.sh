#!/bin/sh
set -eu

until pg_isready -d Chinook >/dev/null 2>&1; do sleep 2; done
if ! psql -d Chinook -tAc "SELECT to_regclass('public.artist') IS NOT NULL" | grep -qx t; then
  # Load into the configured database; skip upstream DROP/CREATE DATABASE and reconnect.
  sed -n '/^CREATE TABLE/,$p' /assets/Chinook_PostgreSql.sql > /tmp/chinook-tables.sql
  psql -v ON_ERROR_STOP=1 -d Chinook -f /tmp/chinook-tables.sql
fi

psql -v ON_ERROR_STOP=1 -d Chinook -v ro_password="$DADBOD_RO_PASSWORD" <<'SQL'
SELECT format('CREATE ROLE dadbod_ro LOGIN PASSWORD %L', :'ro_password')
WHERE NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'dadbod_ro') \gexec
ALTER ROLE dadbod_ro LOGIN PASSWORD :'ro_password';
GRANT CONNECT ON DATABASE "Chinook" TO dadbod_ro;
GRANT USAGE ON SCHEMA public TO dadbod_ro;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO dadbod_ro;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO dadbod_ro;
SQL
