#!/bin/sh
set -eu

apk add --no-cache curl >/dev/null
base_url=https://github.com/lerocha/chinook-database/releases/download/v1.4.5

for script in Chinook_PostgreSql.sql Chinook_MySql.sql Chinook_SqlServer.sql; do
  target=/assets/$script
  [ -s "$target" ] || curl --fail --location --silent --show-error "$base_url/$script" -o "$target"
done
