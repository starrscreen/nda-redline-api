#!/bin/bash

PID_FILE="logs/nda_api.pid"
COMMAND=$1
PORT=8000

function show_usage {
    echo "Usage: $0 [status|stop|url|logs|kill-ngrok|kill-all]"
    echo ""
    echo "Commands:"
    echo "  status     - Check if the NDA API service is running"
    echo "  stop       - Stop the NDA API service"
    echo "  url        - Show the ngrok URL for the NDA API"
    echo "  logs       - Show the latest log files"
    echo "  kill-ngrok - Kill any existing ngrok processes"
    echo "  kill-all   - Kill all related processes (gunicorn, ngrok, port 8000)"
    echo ""
}

function check_status {
    if [ ! -f "$PID_FILE" ]; then
        echo "NDA API service is not running (no PID file found)"
        return 1
    fi
    
    read GUNICORN_PID NGROK_PID < "$PID_FILE"
    
    GUNICORN_RUNNING=0
    NGROK_RUNNING=0
    
    if ps -p "$GUNICORN_PID" > /dev/null; then
        GUNICORN_RUNNING=1
    fi
    
    if ps -p "$NGROK_PID" > /dev/null; then
        NGROK_RUNNING=1
    fi
    
    if [ $GUNICORN_RUNNING -eq 1 ] && [ $NGROK_RUNNING -eq 1 ]; then
        echo "NDA API service is running"
        echo "  - Gunicorn PID: $GUNICORN_PID"
        echo "  - Ngrok PID: $NGROK_PID"
        return 0
    elif [ $GUNICORN_RUNNING -eq 1 ]; then
        echo "WARNING: Gunicorn is running, but ngrok is not"
        echo "  - Gunicorn PID: $GUNICORN_PID"
        return 2
    elif [ $NGROK_RUNNING -eq 1 ]; then
        echo "WARNING: Ngrok is running, but Gunicorn is not"
        echo "  - Ngrok PID: $NGROK_PID"
        return 2
    else
        echo "NDA API service is not running (stale PID file found)"
        echo "Removing stale PID file"
        rm "$PID_FILE"
        return 1
    fi
}

function kill_ngrok {
    EXISTING_NGROK=$(ps aux | grep ngrok | grep -v grep | awk '{print $2}')
    if [ -n "$EXISTING_NGROK" ]; then
        echo "Found ngrok process with PID: $EXISTING_NGROK"
        echo "Killing ngrok process..."
        kill $EXISTING_NGROK 2>/dev/null || true
        sleep 1
        # Check if it's still running
        EXISTING_NGROK=$(ps aux | grep ngrok | grep -v grep | awk '{print $2}')
        if [ -n "$EXISTING_NGROK" ]; then
            echo "Force killing stubborn ngrok process..."
            kill -9 $EXISTING_NGROK 2>/dev/null || true
        fi
        echo "✅ Ngrok process terminated"
    else
        echo "No running ngrok processes found"
    fi
}

function kill_all {
    echo "🧹 Cleaning up all related processes..."
    
    # Kill any ngrok processes
    EXISTING_NGROK=$(ps aux | grep ngrok | grep -v grep | awk '{print $2}')
    if [ -n "$EXISTING_NGROK" ]; then
        echo "  - Killing ngrok process(es)..."
        kill $EXISTING_NGROK 2>/dev/null || true
    else
        echo "  - No ngrok processes found"
    fi
    
    # Kill any gunicorn processes
    EXISTING_GUNICORN=$(ps aux | grep gunicorn | grep -v grep | awk '{print $2}')
    if [ -n "$EXISTING_GUNICORN" ]; then
        echo "  - Killing gunicorn process(es)..."
        kill $EXISTING_GUNICORN 2>/dev/null || true
    else
        echo "  - No gunicorn processes found"
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
    else
        echo "  - Port $PORT is free"
    fi
    
    # Remove stale PID file
    if [ -f "$PID_FILE" ]; then
        echo "  - Removing PID file..."
        rm "$PID_FILE"
    fi
    
    echo "✅ All processes cleaned up"
}

function stop_service {
    if [ ! -f "$PID_FILE" ]; then
        echo "No PID file found, service is not running"
        
        # Check if there are stray processes anyway
        EXISTING_NGROK=$(ps aux | grep ngrok | grep -v grep | awk '{print $2}')
        EXISTING_GUNICORN=$(ps aux | grep gunicorn | grep -v grep | awk '{print $2}')
        
        if [ -n "$EXISTING_NGROK" ] || [ -n "$EXISTING_GUNICORN" ]; then
            echo "But found stray processes. Running kill-all to clean up..."
            kill_all
        fi
        
        return 0
    fi
    
    read GUNICORN_PID NGROK_PID < "$PID_FILE"
    
    echo "Stopping NDA API service..."
    
    if ps -p "$NGROK_PID" > /dev/null; then
        echo "Stopping ngrok (PID: $NGROK_PID)"
        kill "$NGROK_PID" 2>/dev/null || true
    else
        echo "Ngrok is not running"
    fi
    
    if ps -p "$GUNICORN_PID" > /dev/null; then
        echo "Stopping gunicorn (PID: $GUNICORN_PID)"
        kill "$GUNICORN_PID" 2>/dev/null || true
    else
        echo "Gunicorn is not running"
    fi
    
    # Wait a moment
    sleep 2
    
    # Force kill if still running
    if ps -p "$NGROK_PID" > /dev/null; then
        echo "Force stopping ngrok (PID: $NGROK_PID)"
        kill -9 "$NGROK_PID" 2>/dev/null || true
    fi
    
    if ps -p "$GUNICORN_PID" > /dev/null; then
        echo "Force stopping gunicorn (PID: $GUNICORN_PID)"
        kill -9 "$GUNICORN_PID" 2>/dev/null || true
    fi
    
    echo "Removing PID file"
    rm "$PID_FILE"
    echo "NDA API service stopped"
    
    # Check if we need to clean up any stray processes
    EXISTING_NGROK=$(ps aux | grep ngrok | grep -v grep | awk '{print $2}')
    EXISTING_GUNICORN=$(ps aux | grep gunicorn | grep -v grep | awk '{print $2}')
    
    if [ -n "$EXISTING_NGROK" ] || [ -n "$EXISTING_GUNICORN" ]; then
        echo "Found stray processes. Cleaning up..."
        kill_all
    fi
}

function show_url {
    if ! check_status > /dev/null; then
        echo "NDA API service is not running, no URL available"
        return 1
    fi
    
    # Find the latest ngrok log file
    LATEST_LOG=$(ls -t logs/ngrok_*.log | head -n 1)
    
    if [ -z "$LATEST_LOG" ]; then
        echo "No ngrok log file found"
        return 1
    fi
    
    echo "NDA API Service URL:"
    grep -A 2 "Forwarding" "$LATEST_LOG" | head -n 2
}

function show_logs {
    echo "Latest NDA API log files:"
    echo ""
    echo "Gunicorn logs:"
    ls -t logs/gunicorn_*.log | head -n 3
    echo ""
    echo "Ngrok logs:"
    ls -t logs/ngrok_*.log | head -n 3
    echo ""
    echo "To view a log file, use: cat [log_file_path]"
    echo "For example: cat $(ls -t logs/gunicorn_*.log | head -n 1)"
}

# Main command processing
case "$COMMAND" in
    status)
        check_status
        ;;
    stop)
        stop_service
        ;;
    url)
        show_url
        ;;
    logs)
        show_logs
        ;;
    kill-ngrok)
        kill_ngrok
        ;;
    kill-all)
        kill_all
        ;;
    *)
        show_usage
        ;;
esac 