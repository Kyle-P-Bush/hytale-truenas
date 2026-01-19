# Hytale Server Docker Image for TrueNAS
# Based on Adoptium Temurin Java 25

FROM eclipse-temurin:25-jre-alpine

LABEL maintainer="TrueNAS Community"
LABEL description="Hytale Dedicated Server for TrueNAS SCALE"
LABEL version="1.0.0"

# Install required packages
RUN apk add --no-cache \
    curl \
    wget \
    bash \
    jq \
    unzip

# Create hytale user and directories
RUN addgroup -g 1000 hytale && \
    adduser -u 1000 -G hytale -h /opt/hytale -D hytale

# Set working directory
WORKDIR /opt/hytale

# Create necessary directories
RUN mkdir -p /opt/hytale/server \
    /opt/hytale/worlds \
    /opt/hytale/config \
    /opt/hytale/backups && \
    chown -R hytale:hytale /opt/hytale

# Copy entrypoint script
COPY --chmod=755 entrypoint.sh /opt/hytale/entrypoint.sh

# Environment variables with defaults
ENV SERVER_NAME="TrueNAS Hytale Server"
ENV MAX_PLAYERS=10
ENV VIEW_DISTANCE=192
ENV DIFFICULTY="normal"
ENV JAVA_MEMORY="4G"
ENV HYTALE_VERSION="latest"
ENV ALLOW_OP="false"

# Expose UDP port for Hytale (QUIC protocol)
EXPOSE 5520/udp

# Volume mounts for persistent data
VOLUME ["/opt/hytale/worlds", "/opt/hytale/config", "/opt/hytale/backups"]

# Run as root for TrueNAS volume mount compatibility
# (TrueNAS volumes are typically owned by apps:apps UID 568)

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -sf http://localhost:5520/health || exit 1

ENTRYPOINT ["/opt/hytale/entrypoint.sh"]

