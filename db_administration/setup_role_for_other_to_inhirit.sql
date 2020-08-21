--- Use this file to create to role, readonly and a writer
--- All access to data in database is revoked, so new users need to be inhirit a role who have access
--- Also remove public access to schema public

REVOKE ALL ON schema public FROM public;

--- Create read-only role for its schema

CREATE ROLE its_readonly NOLOGIN
  NOSUPERUSER NOINHERIT NOCREATEDB NOCREATEROLE NOREPLICATION;

GRANT USAGE ON SCHEMA its to its_readonly;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA its TO its_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA its TO its_readonly;

GRANT USAGE ON SCHEMA public to its_readonly;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO its_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO its_readonly;

--- Create writer-only role for its schema

CREATE ROLE its_writer NOLOGIN
  NOSUPERUSER NOINHERIT NOCREATEDB NOCREATEROLE NOREPLICATION;

GRANT USAGE, CREATE ON SCHEMA its to its_writer;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA its TO its_writer;
GRANT USAGE, SELECT, UPDATE ON ALL SEQUENCES IN SCHEMA its TO its_writer;

GRANT USAGE, CREATE ON SCHEMA public to its_writer;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO its_writer;
GRANT USAGE, SELECT, UPDATE ON ALL SEQUENCES IN SCHEMA public TO its_writer;
