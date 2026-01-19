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
    
    # Check if already downloaded
    if [ -f "$DOWNLOADER_DIR/hytale-downloader" ]; then
        echo "[INFO] Hytale Downloader CLI already present"
        return 0
    fi
    
    mkdir -p "$DOWNLOADER_DIR"
    
    # Try multiple possible download URLs
    DOWNLOAD_URLS=(
        "https://cdn.hytale.com/downloader/hytale-downloader.zip"
        "https://download.hytale.com/hytale-downloader.zip"
        "https://hytale.com/download/hytale-downloader.zip"
        "https://support.hytale.com/hc/downloads/hytale-downloader.zip"
    )
    
    echo "[INFO] Attempting to download Hytale Downloader CLI..."
    
    for url in "${DOWNLOAD_URLS[@]}"; do
        echo "[INFO] Trying: $url"
        if wget -q --timeout=10 -O "$DOWNLOADER_DIR/hytale-downloader.zip" "$url" 2>/dev/null; then
            # Verify it's a valid zip
            if unzip -t "$DOWNLOADER_DIR/hytale-downloader.zip" >/dev/null 2>&1; then
                echo "[INFO] Downloaded successfully from $url"
                unzip -q -o "$DOWNLOADER_DIR/hytale-downloader.zip" -d "$DOWNLOADER_DIR"
                
                # Find and make executable
                for binary in "$DOWNLOADER_DIR/hytale-downloader" "$DOWNLOADER_DIR/hytale-downloader-linux-amd64" "$DOWNLOADER_DIR/hytale-downloader-linux"; do
                    if [ -f "$binary" ]; then
                        chmod +x "$binary"
                        # Rename to standard name if needed
                        if [ "$binary" != "$DOWNLOADER_DIR/hytale-downloader" ]; then
                            mv "$binary" "$DOWNLOADER_DIR/hytale-downloader"
                        fi
                        echo "[INFO] Hytale Downloader CLI installed successfully"
                        return 0
                    fi
                done
            fi
        fi
        rm -f "$DOWNLOADER_DIR/hytale-downloader.zip"
    done
    
    echo "[WARN] Could not download Hytale Downloader CLI automatically"
    return 1
}

# Function to download server files using CLI
download_server_files() {
    if [ -f "$DOWNLOADER_DIR/hytale-downloader" ]; then
        echo ""
        echo "=========================================="
        echo "  DOWNLOADING HYTALE SERVER FILES"
        echo "=========================================="
        echo ""
        echo "The downloader will authenticate with your Hytale account."
        echo "Watch for a URL and code to complete authentication."
        echo ""
        
        cd "$DOWNLOADER_DIR"
        
        # Run the downloader
        if ./hytale-downloader -download-path "$DOWNLOADER_DIR/server-files.zip"; then
            echo "[INFO] Download completed!"
            
            # Extract the server files
            if [ -f "$DOWNLOADER_DIR/server-files.zip" ]; then
                unzip -q -o "$DOWNLOADER_DIR/server-files.zip" -d "$HYTALE_DIR"
                
                # Move Server folder contents if present
                if [ -d "$HYTALE_DIR/Server" ]; then
                    mv "$HYTALE_DIR/Server/"* "$HYTALE_DIR/" 2>/dev/null || true
                    rmdir "$HYTALE_DIR/Server" 2>/dev/null || true
                fi
                
                # Copy Assets.zip if found
                find "$HYTALE_DIR" -name "Assets.zip" -exec cp {} "$HYTALE_DIR/Assets.zip" \; 2>/dev/null || true
                
                echo "[INFO] Server files extracted successfully!"
                return 0
            fi
        else
            echo "[WARN] Downloader failed"
        fi
    fi
    return 1
}

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
            return 0
        fi
    done
    
    # Server not found - try to download
    echo "[INFO] Server files not found. Attempting automatic download..."
    
    # First, try to get the downloader CLI (don't exit on failure)
    if download_hytale_cli; then
        # Then try to download server files
        if download_server_files; then
            # Re-check for server JAR
            for jar in "$HYTALE_DIR/HytaleServer.jar" "$HYTALE_DIR/hytale-server.jar"; do
                if [ -f "$jar" ]; then
                    SERVER_JAR="$jar"
                    echo "[INFO] Found server JAR: $SERVER_JAR"
                    return 0
                fi
            done
        fi
    fi
    
    # Still no server files - show manual instructions and WAIT (don't exit!)
    echo ""
    echo "=========================================="
    echo "  MANUAL SETUP REQUIRED"
    echo "=========================================="
    echo ""
    echo "Automatic download was not available."
    echo ""
    echo "To get the server files:"
    echo ""
    echo "1. Download the Hytale Downloader CLI from:"
    echo "   https://support.hytale.com/hc/en-us/articles/45326769420827"
    echo "   (Look for 'hytale-downloader.zip' link)"
    echo ""
    echo "2. Run the downloader on your computer to get:"
    echo "   - Server folder (contains HytaleServer.jar)"
    echo "   - Assets.zip"
    echo ""
    echo "3. Copy these files to your TrueNAS 'config' dataset"
    echo "   (the folder you mounted to this container)"
    echo "   Example: /mnt/YOUR_POOL/hytale/config/"
    echo ""
    echo "4. Restart this container:"
    echo "   sudo docker compose restart hytale"
    echo ""
    echo "==========================================" 
    echo ""
    echo "[INFO] Waiting for server files... (checking every 60 seconds)"
    
    # Wait without exiting - check periodically for files
    while true; do
        sleep 60
        for jar in "$HYTALE_DIR/HytaleServer.jar" "$HYTALE_DIR/hytale-server.jar" \
                   "$CONFIG_DIR/HytaleServer.jar" "$CONFIG_DIR/hytale-server.jar"; do
            if [ -f "$jar" ]; then
                echo "[INFO] Server files detected! Continuing setup..."
                return 0
            fi
        done
        echo "[INFO] Still waiting for server files..."
    done
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

# Function to show auth info
show_auth_info() {
    echo ""
    echo "=========================================="
    echo "  SERVER AUTHENTICATION"
    echo "=========================================="
    echo ""
    echo "When the server starts, you may see a prompt to authenticate."
    echo "Visit the URL shown and enter the provided code."
    echo "=========================================="
    echo ""
}

# Function to prepare and start the server
start_server() {
    echo "[INFO] Starting Hytale server..."
    echo "[INFO] Java Memory: ${JAVA_MEMORY}"
    echo "[INFO] Max Players: ${MAX_PLAYERS}"
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
        echo "[ERROR] Server JAR not found!"
        exit 1
    fi
    
    # Copy from config if needed
    if [[ "$SERVER_JAR" == "$CONFIG_DIR"* ]]; then
        cp "$SERVER_JAR" "$HYTALE_DIR/"
        SERVER_JAR="$(basename $SERVER_JAR)"
        [ -f "$CONFIG_DIR/Assets.zip" ] && cp "$CONFIG_DIR/Assets.zip" "$HYTALE_DIR/"
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
    
    # Java arguments
    JAVA_ARGS="-Xmx${JAVA_MEMORY} -Xms${JAVA_MEMORY} -XX:+UseG1GC -XX:MaxGCPauseMillis=200"
    
    # Server arguments
    SERVER_ARGS="--bind 0.0.0.0:5520 --world-dir /opt/hytale/worlds"
    [ -n "$ASSETS_ARG" ] && SERVER_ARGS="$SERVER_ARGS $ASSETS_ARG"
    [ "$ALLOW_OP" = "true" ] && SERVER_ARGS="$SERVER_ARGS --allow-op"
    
    echo "[INFO] Executing: java $JAVA_ARGS -jar $SERVER_JAR $SERVER_ARGS"
    echo ""
    
    exec java $JAVA_ARGS -jar "$SERVER_JAR" $SERVER_ARGS
}

# Main execution
check_server_files
setup_config
show_auth_info
start_server
