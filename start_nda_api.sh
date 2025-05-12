#!/bin/bash

# Variables
PORT=8000
# If you have reserved a domain, add it here, otherwise leave empty
DOMAIN="ndareviewer.ngrok.io"  # Your custom domain
LOG_DIR="logs"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
GUNICORN_LOG="$LOG_DIR/gunicorn_$TIMESTAMP.log"
NGROK_LOG="$LOG_DIR/ngrok_$TIMESTAMP.log"
PID_FILE="$LOG_DIR/nda_api.pid"

# Create logs directory if it doesn't exist
mkdir -p "$LOG_DIR"

# Function to clean up processes - enhanced version with more thorough cleanup
cleanup_processes() {
    echo "🧹 Performing thorough cleanup before starting..."
    
    # Stop any existing service first using PID file if it exists
    if [ -f "$PID_FILE" ]; then
        read GUNICORN_PID NGROK_PID < "$PID_FILE"
        
        if ps -p "$NGROK_PID" > /dev/null 2>&1; then
            echo "  - Stopping existing ngrok service (PID: $NGROK_PID)"
            kill "$NGROK_PID" 2>/dev/null || true
        fi
        
        if ps -p "$GUNICORN_PID" > /dev/null 2>&1; then
            echo "  - Stopping existing gunicorn service (PID: $GUNICORN_PID)"
            kill "$GUNICORN_PID" 2>/dev/null || true
        fi
        
        # Remove PID file
        rm "$PID_FILE" 2>/dev/null || true
        echo "  - Removed existing PID file"
        
        # Give processes time to terminate gracefully
        sleep 2
    fi
    
    # Kill any ngrok processes regardless of PID file
    EXISTING_NGROK=$(ps aux | grep ngrok | grep -v grep | awk '{print $2}')
    if [ -n "$EXISTING_NGROK" ]; then
        echo "  - Killing all ngrok processes..."
        kill $EXISTING_NGROK 2>/dev/null || true
    fi
    
    # Kill any gunicorn processes regardless of PID file
    EXISTING_GUNICORN=$(ps aux | grep gunicorn | grep -v grep | awk '{print $2}')
    if [ -n "$EXISTING_GUNICORN" ]; then
        echo "  - Killing all gunicorn processes..."
        kill $EXISTING_GUNICORN 2>/dev/null || true
    fi
    
    # Wait a moment to let processes terminate
    sleep 2
    
    # Force kill any stubborn processes
    EXISTING_NGROK=$(ps aux | grep ngrok | grep -v grep | awk '{print $2}')
    if [ -n "$EXISTING_NGROK" ]; then
        echo "  - Force killing stubborn ngrok processes..."
        kill -9 $EXISTING_NGROK 2>/dev/null || true
    fi
    
    EXISTING_GUNICORN=$(ps aux | grep gunicorn | grep -v grep | awk '{print $2}')
    if [ -n "$EXISTING_GUNICORN" ]; then
        echo "  - Force killing stubborn gunicorn processes..."
        kill -9 $EXISTING_GUNICORN 2>/dev/null || true
    fi
    
    # Check if port is still in use
    if lsof -i :$PORT > /dev/null 2>&1; then
        echo "  - Port $PORT is still in use. Freeing it up..."
        PROCESS_USING_PORT=$(lsof -t -i :$PORT)
        if [ -n "$PROCESS_USING_PORT" ]; then
            echo "  - Killing process using port $PORT: $PROCESS_USING_PORT"
            kill -9 $PROCESS_USING_PORT 2>/dev/null || true
        fi
    fi
    
    # Remove stale PID file if it exists (redundant check but safe)
    if [ -f "$PID_FILE" ]; then
        echo "  - Removing stale PID file..."
        rm "$PID_FILE" 2>/dev/null || true
    fi
    
    echo "✅ Thorough cleanup completed - ready for fresh instance"
}

# Perform thorough cleanup before starting
cleanup_processes

# Start the Flask app with Gunicorn in the background
echo "Starting NDA Redline API on port $PORT..."
cd "$(dirname "$0")"  # Change to script directory
source venv/bin/activate
gunicorn --bind 0.0.0.0:$PORT application:app > "$GUNICORN_LOG" 2>&1 &
GUNICORN_PID=$!

# Wait a bit for the app to start
sleep 3

# Check if gunicorn is really running
if ! ps -p $GUNICORN_PID > /dev/null; then
    echo "ERROR: Gunicorn failed to start. Check logs at $GUNICORN_LOG"
    exit 1
fi

# Start ngrok in the background
echo "Starting ngrok tunnel for NDA API..."
if [ -z "$DOMAIN" ]; then
    echo "Using free ngrok with random URL"
    ngrok http $PORT > "$NGROK_LOG" 2>&1 &
else
    echo "Using reserved domain: $DOMAIN"
    ngrok http --domain=$DOMAIN $PORT > "$NGROK_LOG" 2>&1 &
fi
NGROK_PID=$!

# Wait a bit for ngrok to start
sleep 3

# Check if ngrok is really running
if ! ps -p $NGROK_PID > /dev/null; then
    echo "ERROR: ngrok failed to start. Check logs at $NGROK_LOG"
    echo "This could be due to:"
    echo "  - Another ngrok session running on your account"
    echo "  - Network connectivity issues"
    echo "  - Invalid domain configuration"
    echo ""
    echo "Check the ngrok log for details: cat $NGROK_LOG"
    kill $GUNICORN_PID
    exit 1
fi

# Save PIDs to file
echo "$GUNICORN_PID $NGROK_PID" > "$PID_FILE"

echo "✅ NDA API service started successfully in background!"
echo "Gunicorn PID: $GUNICORN_PID, Ngrok PID: $NGROK_PID"
echo "Logs are available at:"
echo "  - Gunicorn: $GUNICORN_LOG"
echo "  - Ngrok: $NGROK_LOG"
echo ""
echo "To check the service status: ./nda_api_control.sh status"
echo "To get the public URL: ./nda_api_control.sh url"
echo "To stop the service: ./nda_api_control.sh stop" 