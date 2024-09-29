CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";


CREATE EXTENSION pgagent;

CREATE USER "pgagent" WITH
  LOGIN
  NOSUPERUSER
  INHERIT
  NOCREATEDB
  NOCREATEROLE
  NOREPLICATION
  encrypted password 'securepassword';

GRANT USAGE ON SCHEMA pgagent TO pgagent;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA pgagent TO pgagent;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA pgagent TO pgagent;