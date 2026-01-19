#!/bin/bash
set -e

HYTALE_DIR="/opt/hytale/server"
CONFIG_DIR="/opt/hytale/config"
CONFIG_FILE="$CONFIG_DIR/config.json"
DOWNLOADER_DIR="/opt/hytale/downloader"

echo "=========================================="
echo "  Hytale Server for TrueNAS"
echo "=========================================="
echo ""

# Function to download the Hytale Downloader CLI
download_hytale_cli() {
    echo "[INFO] Checking for Hytale Downloader CLI..."
    
    if [ ! -f "$DOWNLOADER_DIR/hytale-downloader" ]; then
        echo "[INFO] Downloading Hytale Downloader CLI..."
        mkdir -p "$DOWNLOADER_DIR"
        
        # Download the official Hytale Downloader CLI
        # The URL pattern may need updating based on official releases
        DOWNLOAD_URL="https://cdn.hytale.com/downloader/hytale-downloader-linux-amd64.zip"
        
        if ! wget -q -O "$DOWNLOADER_DIR/downloader.zip" "$DOWNLOAD_URL" 2>/dev/null; then
            echo "[WARN] Could not download from CDN, trying alternative..."
            # Fallback: the downloader may be bundled or use a different URL
            echo "[INFO] Please check https://hytale.com for the latest downloader URL"
        fi
        
        if [ -f "$DOWNLOADER_DIR/downloader.zip" ]; then
            unzip -q -o "$DOWNLOADER_DIR/downloader.zip" -d "$DOWNLOADER_DIR"
            chmod +x "$DOWNLOADER_DIR/hytale-downloader"* 2>/dev/null || true
            rm -f "$DOWNLOADER_DIR/downloader.zip"
            echo "[INFO] Hytale Downloader CLI installed"
        fi
    fi
}

# Function to download Hytale server using CLI
download_server() {
    echo "[INFO] Checking for Hytale server files..."
    
    # Check for server JAR in multiple possible locations
    SERVER_JAR=""
    for jar in "$HYTALE_DIR/HytaleServer.jar" "$HYTALE_DIR/hytale-server.jar" "$CONFIG_DIR/HytaleServer.jar" "$CONFIG_DIR/hytale-server.jar"; do
        if [ -f "$jar" ]; then
            SERVER_JAR="$jar"
            break
        fi
    done
    
    if [ -z "$SERVER_JAR" ]; then
        echo "[INFO] Server not found. Starting download process..."
        echo ""
        
        # Try to use the Hytale Downloader CLI
        DOWNLOADER=""
        for dl in "$DOWNLOADER_DIR/hytale-downloader" "$DOWNLOADER_DIR/hytale-downloader-linux-amd64"; do
            if [ -f "$dl" ] && [ -x "$dl" ]; then
                DOWNLOADER="$dl"
                break
            fi
        done
        
        if [ -n "$DOWNLOADER" ]; then
            echo "=========================================="
            echo "  HYTALE DOWNLOAD - AUTHENTICATION"
            echo "=========================================="
            echo ""
            echo "The Hytale Downloader will now authenticate with your account."
            echo "Watch for a code and URL to complete authentication."
            echo ""
            
            cd "$HYTALE_DIR"
            
            # Run the downloader - it will prompt for OAuth
            if $DOWNLOADER download --output "$HYTALE_DIR"; then
                echo "[INFO] Hytale server files downloaded successfully!"
                
                # Find and set the server JAR
                for jar in "$HYTALE_DIR/HytaleServer.jar" "$HYTALE_DIR/hytale-server.jar"; do
                    if [ -f "$jar" ]; then
                        SERVER_JAR="$jar"
                        break
                    fi
                done
            else
                echo "[WARN] Downloader failed. Falling back to manual instructions."
            fi
        fi
        
        # If still no server JAR, show manual instructions
        if [ -z "$SERVER_JAR" ]; then
            echo ""
            echo "=========================================="
            echo "  MANUAL SETUP REQUIRED"
            echo "=========================================="
            echo ""
            echo "Automatic download was not available or failed."
            echo ""
            echo "Option 1: Run the downloader manually"
            echo "  1. SSH into your TrueNAS server"
            echo "  2. Download the Hytale Downloader CLI from hytale.com"
            echo "  3. Run it and authenticate with your Hytale account"
            echo "  4. Copy HytaleServer.jar and Assets.zip to:"
            echo "     $CONFIG_DIR/"
            echo ""
            echo "Option 2: Copy from your PC"
            echo "  1. Find your Hytale installation folder"
            echo "  2. Copy the server files to: $CONFIG_DIR/"
            echo ""
            echo "After adding files, restart this container."
            echo "=========================================="
            echo ""
            
            echo "[INFO] Waiting for server files to be added..."
            sleep infinity
        fi
    fi
    
    echo "[INFO] Server JAR found: $SERVER_JAR"
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
check_auth() {
    AUTH_FILE="$CONFIG_DIR/.hytale_auth"
    
    if [ ! -f "$AUTH_FILE" ]; then
        echo ""
        echo "=========================================="
        echo "  SERVER AUTHENTICATION"
        echo "=========================================="
        echo ""
        echo "Hytale servers must be linked to a Hytale account."
        echo ""
        echo "When the server starts, you may see:"
        echo "  'Visit https://accounts.hytale.com/device and enter code: XXXX-XXXX'"
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
    
    # Find the server JAR
    SERVER_JAR=""
    for jar in "HytaleServer.jar" "hytale-server.jar" "$CONFIG_DIR/HytaleServer.jar" "$CONFIG_DIR/hytale-server.jar"; do
        if [ -f "$jar" ]; then
            SERVER_JAR="$jar"
            break
        fi
    done
    
    if [ -z "$SERVER_JAR" ]; then
        echo "[ERROR] No server JAR found!"
        exit 1
    fi
    
    # Find assets
    ASSETS_ARG=""
    for assets in "$HYTALE_DIR/Assets.zip" "$CONFIG_DIR/Assets.zip"; do
        if [ -f "$assets" ]; then
            ASSETS_ARG="--assets $assets"
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
    SERVER_ARGS="$SERVER_ARGS $ASSETS_ARG"
    
    if [ "$ALLOW_OP" = "true" ]; then
        SERVER_ARGS="$SERVER_ARGS --allow-op"
    fi
    
    echo "[INFO] Executing: java $JAVA_ARGS -jar $SERVER_JAR $SERVER_ARGS"
    echo ""
    
    exec java $JAVA_ARGS -jar "$SERVER_JAR" $SERVER_ARGS
}

# Main execution
download_hytale_cli
download_server
setup_config
check_auth
start_server
