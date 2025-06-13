DROP DATABASE IF EXISTS nyota_bank_db;
DROP ROLE IF EXISTS nyota_bank_user;

CREATE DATABASE nyota_bank_db;
CREATE USER nyota_bank_user WITH PASSWORD '^Rg]yI=fW5cGI.=!';
GRANT ALL PRIVILEGES ON DATABASE nyota_bank_db TO nyota_bank_user;
ALTER USER nyota_bank_user CREATEDB;

-- Grant usage on the public schema
GRANT ALL ON SCHEMA public TO nyota_bank_user;