#!/bin/bash
set -e

# ---- Default configuration (can be overridden with env vars) ----

# Database settings (we'll override these in docker-compose for MySQL)
: "${LAVAGNA_DB_DIALECT:=HSQLDB}"
: "${LAVAGNA_DB_URL:=jdbc:hsqldb:file:/data/lavagna}"
: "${LAVAGNA_DB_USERNAME:=sa}"
: "${LAVAGNA_DB_PASSWORD:=}"

# Spring profile
: "${LAVAGNA_SPRING_PROFILE:=dev}"

# HTTP port for the embedded Jetty
: "${LAVAGNA_PORT:=8080}"

# DB host (for waiting when using MySQL)
: "${LAVAGNA_DB_HOST:=db}"
: "${LAVAGNA_DB_PORT:=3306}"

# Ensure DB directory exists (for HSQLDB file mode)
mkdir -p /data

# ---- Helper: wait for database when using MySQL ----
wait_for_mysql() {
  local host="$1"
  local port="$2"

  echo "Waiting for MySQL at ${host}:${port} ..."
  # The ! inverts the status, so set -e won't kill the script here
  while ! echo > /dev/tcp/"$host"/"$port" 2>/dev/null; do
    echo "MySQL not ready yet, sleeping 2s..."
    sleep 2
  done
  echo "MySQL is up!"
}

# If dialect is MYSQL, wait for the DB to be ready
if [ "$LAVAGNA_DB_DIALECT" = "MYSQL" ]; then
  wait_for_mysql "$LAVAGNA_DB_HOST" "$LAVAGNA_DB_PORT"
fi

echo "Starting Lavagna with:"
echo "  Dialect:  ${LAVAGNA_DB_DIALECT}"
echo "  URL:      ${LAVAGNA_DB_URL}"
echo "  User:     ${LAVAGNA_DB_USERNAME}"
echo "  Profile:  ${LAVAGNA_SPRING_PROFILE}"
echo "  Port:     ${LAVAGNA_PORT}"

# ---- Run Lavagna's executable WAR ----
exec java \
  -Ddatasource.dialect="${LAVAGNA_DB_DIALECT}" \
  -Ddatasource.url="${LAVAGNA_DB_URL}" \
  -Ddatasource.username="${LAVAGNA_DB_USERNAME}" \
  -Ddatasource.password="${LAVAGNA_DB_PASSWORD}" \
  -Dspring.profile.active="${LAVAGNA_SPRING_PROFILE}" \
  -jar target/lavagna-jetty-console.war \
  --port "${LAVAGNA_PORT}" \
  --bindAddress 0.0.0.0

