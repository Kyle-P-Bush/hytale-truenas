#!/bin/bash
set -e

HYTALE_DIR="/opt/hytale/server"
CONFIG_FILE="/opt/hytale/config/config.json"

echo "=========================================="
echo "  Hytale Server for TrueNAS"
echo "=========================================="
echo ""

# Function to download Hytale server
download_server() {
    echo "[INFO] Checking for Hytale server files..."
    
    if [ ! -f "$HYTALE_DIR/hytale-server.jar" ]; then
        echo "[INFO] Server not found. Downloading Hytale server..."
        
        # Note: Hytale server download requires authentication via Hytale Launcher
        # Users can either:
        # 1. Copy server files from their Hytale installation
        # 2. Use the Hytale Downloader CLI tool
        
        echo ""
        echo "=========================================="
        echo "  FIRST TIME SETUP REQUIRED"
        echo "=========================================="
        echo ""
        echo "Hytale server files are not present."
        echo ""
        echo "To set up your server:"
        echo "1. Download the Hytale server from your Hytale Launcher installation"
        echo "2. Copy the server files to the mounted config volume:"
        echo "   - hytale-server.jar"
        echo "   - Any additional required files"
        echo ""
        echo "Alternatively, use the Hytale Downloader CLI:"
        echo "   https://github.com/HytaleServerTools/hytale-downloader"
        echo ""
        echo "After adding the files, restart this container."
        echo "=========================================="
        echo ""
        
        # Keep container running for debugging
        echo "[INFO] Waiting for server files to be added..."
        sleep infinity
    fi
}

# Function to create/update config
setup_config() {
    echo "[INFO] Setting up server configuration..."
    
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "[INFO] Creating default config.json..."
        cat > "$CONFIG_FILE" << EOF
{
    "serverName": "${SERVER_NAME}",
    "maxPlayers": ${MAX_PLAYERS},
    "viewDistance": ${VIEW_DISTANCE},
    "difficulty": "${DIFFICULTY}",
    "worldPath": "/opt/hytale/worlds",
    "port": 5520
}
EOF
        echo "[INFO] Config created at $CONFIG_FILE"
    else
        echo "[INFO] Using existing config at $CONFIG_FILE"
    fi
}

# Function to handle authentication
check_auth() {
    AUTH_FILE="/opt/hytale/config/.hytale_auth"
    
    if [ ! -f "$AUTH_FILE" ]; then
        echo ""
        echo "=========================================="
        echo "  AUTHENTICATION REQUIRED"
        echo "=========================================="
        echo ""
        echo "Hytale servers must be linked to a Hytale account."
        echo ""
        echo "When the server starts, you will see a message like:"
        echo "  'Visit https://hytale.com/link and enter code: XXXX-XXXX'"
        echo ""
        echo "Complete the authentication in your browser."
        echo "=========================================="
        echo ""
    fi
}

# Function to start the server
start_server() {
    echo "[INFO] Starting Hytale server..."
    echo "[INFO] Java Memory: ${JAVA_MEMORY}"
    echo "[INFO] Max Players: ${MAX_PLAYERS}"
    echo "[INFO] View Distance: ${VIEW_DISTANCE}"
    echo ""
    
    cd "$HYTALE_DIR"
    
    # Build Java arguments
    JAVA_ARGS="-Xmx${JAVA_MEMORY} -Xms${JAVA_MEMORY}"
    JAVA_ARGS="$JAVA_ARGS -XX:+UseG1GC"
    JAVA_ARGS="$JAVA_ARGS -XX:+ParallelRefProcEnabled"
    JAVA_ARGS="$JAVA_ARGS -XX:MaxGCPauseMillis=200"
    
    # Server arguments
    SERVER_ARGS="--config $CONFIG_FILE"
    SERVER_ARGS="$SERVER_ARGS --world-dir /opt/hytale/worlds"
    
    if [ "$ALLOW_OP" = "true" ]; then
        SERVER_ARGS="$SERVER_ARGS --allow-op"
    fi
    
    echo "[INFO] Executing: java $JAVA_ARGS -jar hytale-server.jar $SERVER_ARGS"
    echo ""
    
    exec java $JAVA_ARGS -jar hytale-server.jar $SERVER_ARGS
}

# Main execution
download_server
setup_config
check_auth
start_server
