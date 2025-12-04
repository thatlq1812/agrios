#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE DATABASE agrios_users;
    CREATE DATABASE agrios_articles;
    GRANT ALL PRIVILEGES ON DATABASE agrios_users TO postgres;
    GRANT ALL PRIVILEGES ON DATABASE agrios_articles TO postgres;
EOSQL
