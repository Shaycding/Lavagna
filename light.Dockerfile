########################
# Stage 1: Builder
########################
FROM maven:3.6.3-openjdk-8 AS builder

# Work inside /app
WORKDIR /app

# Copy Maven descriptor first (better layer caching)
COPY pom.xml .
RUN mvn -q -DskipTests=true dependency:go-offline

# Copy the rest of the source code
COPY . .

# Build Lavagna (produces target/lavagna-jetty-console.war)
RUN mvn -q -DskipTests=true clean package


########################
# Stage 2: Runtime (lightweight)
########################
FROM eclipse-temurin:8-jre-alpine

# We use /app just like in the heavy image
WORKDIR /app

# Install bash because entrypoint.sh uses #!/bin/bash and /dev/tcp
RUN apk add --no-cache bash

# Create directory for file-based HSQLDB/MySQL-related data if needed
RUN mkdir -p /data

# Copy the built WAR from the builder stage
COPY --from=builder /app/target/lavagna-jetty-console.war /app/target/lavagna-jetty-console.war

# Copy our existing entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Expose application port
EXPOSE 8080

# Optional volume for data
VOLUME ["/data"]

# Use entrypoint.sh (no CMD)
ENTRYPOINT ["/entrypoint.sh"]

