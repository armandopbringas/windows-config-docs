#!/bin/sh
set -eu

sqlcmd='/opt/mssql-tools18/bin/sqlcmd -S sqlserver -U sa -C -b'
until sh -c "$sqlcmd -Q \"SELECT 1\"" >/dev/null 2>&1; do sleep 2; done
sh -c "$sqlcmd -Q \"IF DB_ID(N'Chinook') IS NULL CREATE DATABASE [Chinook];\""
if ! sh -c "$sqlcmd -d Chinook -h -1 -W -Q \"SELECT COUNT(*) FROM sys.tables WHERE name=N'Artist'\"" | grep -qx 1; then
  sh -c "$sqlcmd -d Chinook -i /assets/Chinook_SqlServer.sql"
fi
sh -c "$sqlcmd -d Chinook -v DADBOD_RO_PASSWORD=\"$DADBOD_RO_PASSWORD\" -Q \"
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name=N'dadbod_ro')
  CREATE LOGIN [dadbod_ro] WITH PASSWORD='\$(DADBOD_RO_PASSWORD)', CHECK_POLICY=ON;
ELSE ALTER LOGIN [dadbod_ro] WITH PASSWORD='\$(DADBOD_RO_PASSWORD)';
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name=N'dadbod_ro')
  CREATE USER [dadbod_ro] FOR LOGIN [dadbod_ro];
ALTER ROLE [db_datareader] ADD MEMBER [dadbod_ro];\""
