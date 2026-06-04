#!/bin/bash

# Parse DATABASE_URL: postgresql://user:password@host:port/dbname?...
DB_URL="${DATABASE_URL#postgresql://}"
POSTGRES_USER="${DB_URL%%:*}"
DB_URL="${DB_URL#*:}"
POSTGRES_PASSWORD="${DB_URL%%@*}"
DB_URL="${DB_URL#*@}"
PGHOST="${DB_URL%%:*}"
DB_URL="${DB_URL#*:}"
PGPORT="${DB_URL%%/*}"
DB_URL="${DB_URL#*/}"
POSTGRES_DB="${DB_URL%%\?*}"

export POSTGRES_USER POSTGRES_PASSWORD PGHOST PGPORT POSTGRES_DB

# Create schema on first initialization
cat > /docker-entrypoint-initdb.d/01-create-schema.sql << EOF
CREATE SCHEMA IF NOT EXISTS public;
GRANT ALL ON SCHEMA public TO ${POSTGRES_USER};
EOF

# Create init script to apply postgresql.conf during first initialization
cat > /docker-entrypoint-initdb.d/00-setup-config.sh << 'EOF'
#!/bin/bash
echo "Applying PostgreSQL configuration..."
envsubst < /etc/postgresql/postgresql.conf > ${PGDATA}/postgresql.conf
echo "PostgreSQL configuration applied successfully"
EOF
chmod +x /docker-entrypoint-initdb.d/00-setup-config.sh

# If database exists, update config (for container restarts)
if [ -f /var/lib/postgresql/data/postgresql.conf ]; then
  envsubst < /etc/postgresql/postgresql.conf > /var/lib/postgresql/data/postgresql.conf
  echo "PostgreSQL configuration updated"
fi

exec docker-entrypoint.sh postgres
