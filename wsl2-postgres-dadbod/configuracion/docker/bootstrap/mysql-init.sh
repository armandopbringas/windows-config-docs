#!/bin/sh
set -eu

mysql='mysql -h mysql -uroot --protocol=tcp'
until sh -c "$mysql -e \"SELECT 1\"" >/dev/null 2>&1; do sleep 2; done

if ! sh -c "$mysql -Nse \"SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='Chinook' AND table_name='Artist'\"" | grep -qx 1; then
  sh -c "$mysql < /assets/Chinook_MySql.sql"
fi

sh -c "$mysql" <<SQL
CREATE USER IF NOT EXISTS 'dadbod_ro'@'%' IDENTIFIED BY '${DADBOD_RO_PASSWORD}';
ALTER USER 'dadbod_ro'@'%' IDENTIFIED BY '${DADBOD_RO_PASSWORD}';
GRANT SELECT ON Chinook.* TO 'dadbod_ro'@'%';
FLUSH PRIVILEGES;
SQL
