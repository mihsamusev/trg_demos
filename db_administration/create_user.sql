--- Creating user on itsplatforms database
--- 1. username should be substituted with the user in the mail system eg. username@civil.aau.dk
--- 2. Set expiration date
--- 3. Write the fullname in the comments below
--- 4. Test access

CREATE ROLE username
WITH PASSWORD 'sikkertp' LOGIN
VALID UNTIL '2020-12-31' -- Set date at semester end
NOSUPERUSER INHERIT NOCREATEDB NOCREATEROLE NOREPLICATION;
COMMENT ON ROLE username IS 'FULL NAVM username@student.aau.dk';

CREATE SCHEMA AUTHORIZATION username;


-- Give access to everything its_readonly have access to
GRANT its_readonly TO username;


-- Test access:
SET ROLE='username';
SELECT * FROM prg.trips LIMIT 1;  -- Return denied
SELECT * FROM its."Koeretid" LIMIT 1; -- Return infomation
RESET ROLE;