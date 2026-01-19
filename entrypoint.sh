#!/bin/bash
set -e

HYTALE_DIR="/opt/hytale/server"
CONFIG_DIR="/opt/hytale/config"
CONFIG_FILE="$CONFIG_DIR/config.json"

echo "=========================================="
echo "  Hytale Server for TrueNAS"
echo "=========================================="
echo ""

# Function to check for server files
check_server_files() {
    echo "[INFO] Checking for Hytale server files..."
    
    # Check for server JAR in multiple possible locations
    SERVER_JAR=""
    for jar in "$HYTALE_DIR/HytaleServer.jar" "$HYTALE_DIR/hytale-server.jar" \
               "$CONFIG_DIR/HytaleServer.jar" "$CONFIG_DIR/hytale-server.jar" \
               "$HYTALE_DIR/Server/HytaleServer.jar"; do
        if [ -f "$jar" ]; then
            SERVER_JAR="$jar"
            echo "[INFO] Found server JAR: $SERVER_JAR"
            break
        fi
    done
    
    if [ -z "$SERVER_JAR" ]; then
        echo ""
        echo "=========================================="
        echo "  SERVER FILES REQUIRED"
        echo "=========================================="
        echo ""
        echo "Hytale server files are not present."
        echo ""
        echo "To download the server files:"
        echo ""
        echo "1. On your computer, download the Hytale Downloader CLI from:"
        echo "   https://hytale.com (look in Downloads or Server section)"
        echo ""
        echo "2. Run the downloader - it will authenticate with your Hytale account"
        echo "   and download HytaleServer.jar and Assets.zip"
        echo ""
        echo "3. Transfer the files to your TrueNAS server:"
        echo "   - HytaleServer.jar"
        echo "   - Assets.zip"
        echo ""
        echo "4. Place them in your config dataset (mounted at $CONFIG_DIR)"
        echo ""
        echo "5. Restart this container:"
        echo "   sudo docker compose restart hytale"
        echo ""
        echo "=========================================="
        echo ""
        echo "[INFO] Container will wait for files. Add them and restart."
        echo ""
        
        # Wait indefinitely but don't exit - this prevents restart loop
        while true; do
            sleep 3600  # Check every hour
            # Re-check for files
            for jar in "$HYTALE_DIR/HytaleServer.jar" "$HYTALE_DIR/hytale-server.jar" \
                       "$CONFIG_DIR/HytaleServer.jar" "$CONFIG_DIR/hytale-server.jar"; do
                if [ -f "$jar" ]; then
                    echo "[INFO] Server files detected! Restarting setup..."
                    exec "$0"  # Re-run the script
                fi
            done
        done
    fi
    
    # Copy JAR to server directory if it's in config
    if [[ "$SERVER_JAR" == "$CONFIG_DIR"* ]] && [ "$SERVER_JAR" != "$HYTALE_DIR"* ]; then
        echo "[INFO] Copying server files to runtime directory..."
        cp "$SERVER_JAR" "$HYTALE_DIR/"
        SERVER_JAR="$HYTALE_DIR/$(basename $SERVER_JAR)"
        
        # Also copy Assets.zip if present
        if [ -f "$CONFIG_DIR/Assets.zip" ]; then
            cp "$CONFIG_DIR/Assets.zip" "$HYTALE_DIR/"
        fi
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

# Function to handle authentication info
show_auth_info() {
    echo ""
    echo "=========================================="
    echo "  SERVER AUTHENTICATION"
    echo "=========================================="
    echo ""
    echo "Hytale servers must be linked to a Hytale account."
    echo ""
    echo "When the server starts, you may see a prompt like:"
    echo "  'Visit https://accounts.hytale.com/device'"
    echo "  'Enter code: XXXX-XXXX'"
    echo ""
    echo "Complete the authentication in your browser."
    echo "=========================================="
    echo ""
}

# Function to start the server
start_server() {
    echo "[INFO] Starting Hytale server..."
    echo "[INFO] Java Memory: ${JAVA_MEMORY}"
    echo "[INFO] Max Players: ${MAX_PLAYERS}"
    echo "[INFO] View Distance: ${VIEW_DISTANCE}"
    echo ""
    
    cd "$HYTALE_DIR"
    
    # Find the server JAR
    SERVER_JAR=""
    for jar in "HytaleServer.jar" "hytale-server.jar"; do
        if [ -f "$jar" ]; then
            SERVER_JAR="$jar"
            break
        fi
    done
    
    if [ -z "$SERVER_JAR" ]; then
        echo "[ERROR] No server JAR found in $HYTALE_DIR!"
        exit 1
    fi
    
    # Find assets
    ASSETS_ARG=""
    for assets in "$HYTALE_DIR/Assets.zip" "$CONFIG_DIR/Assets.zip"; do
        if [ -f "$assets" ]; then
            ASSETS_ARG="--assets $assets"
            echo "[INFO] Using assets: $assets"
            break
        fi
    done
    
    # Build Java arguments
    JAVA_ARGS="-Xmx${JAVA_MEMORY} -Xms${JAVA_MEMORY}"
    JAVA_ARGS="$JAVA_ARGS -XX:+UseG1GC"
    JAVA_ARGS="$JAVA_ARGS -XX:+ParallelRefProcEnabled"
    JAVA_ARGS="$JAVA_ARGS -XX:MaxGCPauseMillis=200"
    
    # Server arguments
    SERVER_ARGS="--bind 0.0.0.0:5520"
    SERVER_ARGS="$SERVER_ARGS --world-dir /opt/hytale/worlds"
    if [ -n "$ASSETS_ARG" ]; then
        SERVER_ARGS="$SERVER_ARGS $ASSETS_ARG"
    fi
    
    if [ "$ALLOW_OP" = "true" ]; then
        SERVER_ARGS="$SERVER_ARGS --allow-op"
    fi
    
    echo "[INFO] Executing: java $JAVA_ARGS -jar $SERVER_JAR $SERVER_ARGS"
    echo ""
    
    exec java $JAVA_ARGS -jar "$SERVER_JAR" $SERVER_ARGS
}

# Main execution
check_server_files
setup_config
show_auth_info
start_server
