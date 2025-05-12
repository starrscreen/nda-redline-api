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

# Check if service is already running
if [ -f "$PID_FILE" ]; then
    EXISTING_PID=$(cat "$PID_FILE")
    if ps -p "$EXISTING_PID" > /dev/null; then
        echo "NDA API service is already running with PID $EXISTING_PID"
        echo "To stop it, run: ./nda_api_control.sh stop"
        exit 1
    else
        echo "Removing stale PID file"
        rm "$PID_FILE"
    fi
fi

# Start the Flask app with Gunicorn in the background
echo "Starting NDA Redline API on port $PORT..."
cd "$(dirname "$0")"  # Change to script directory
source venv/bin/activate
gunicorn --bind 0.0.0.0:$PORT application:application > "$GUNICORN_LOG" 2>&1 &
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