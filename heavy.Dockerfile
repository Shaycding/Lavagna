# Heavyweight image: contains Maven + JDK + source + build output
FROM maven:3.6.3-openjdk-8

# Work inside /app
WORKDIR /app

# Copy Maven descriptor first (better layer caching)
COPY pom.xml .
RUN mvn -q -DskipTests=true dependency:go-offline

# Copy the rest of the source code
COPY . .

# Build Lavagna inside the image (produces target/lavagna-jetty-console.war)
RUN mvn -q -DskipTests=true clean package

# Create directory for file-based HSQLDB data
RUN mkdir -p /data

RUN mkdir -p /lavagna-static \
    && cd /lavagna-static \
    && jar xf /app/target/lavagna-jetty-console.war

# Copy our custom entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Expose the application port
EXPOSE 8080

# Optional: declare DB volume for persistence (HSQLDB files)
VOLUME ["/data"]

# Use entrypoint.sh as the container's entrypoint (no CMD)
ENTRYPOINT ["/entrypoint.sh"]

