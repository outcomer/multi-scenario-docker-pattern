-- Initialize database
-- This file is executed only once on first PostgreSQL container startup

-- Database is already created by POSTGRES_DB env var
-- User is already created by POSTGRES_USER env var
-- No additional initialization needed for basic setup

-- You can add additional initialization SQL here if needed
-- For example, create extensions:
-- CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
-- CREATE EXTENSION IF NOT EXISTS "pgcrypto";

SELECT 'Database initialization complete!' AS message;
