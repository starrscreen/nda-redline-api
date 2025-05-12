#!/bin/bash

PID_FILE="logs/nda_api.pid"
COMMAND=$1

function show_usage {
    echo "Usage: $0 [status|stop|url|logs]"
    echo ""
    echo "Commands:"
    echo "  status    - Check if the NDA API service is running"
    echo "  stop      - Stop the NDA API service"
    echo "  url       - Show the ngrok URL for the NDA API"
    echo "  logs      - Show the latest log files"
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

function stop_service {
    if [ ! -f "$PID_FILE" ]; then
        echo "No PID file found, service is not running"
        return 0
    fi
    
    read GUNICORN_PID NGROK_PID < "$PID_FILE"
    
    echo "Stopping NDA API service..."
    
    if ps -p "$NGROK_PID" > /dev/null; then
        echo "Stopping ngrok (PID: $NGROK_PID)"
        kill "$NGROK_PID"
    else
        echo "Ngrok is not running"
    fi
    
    if ps -p "$GUNICORN_PID" > /dev/null; then
        echo "Stopping gunicorn (PID: $GUNICORN_PID)"
        kill "$GUNICORN_PID"
    else
        echo "Gunicorn is not running"
    fi
    
    echo "Removing PID file"
    rm "$PID_FILE"
    echo "NDA API service stopped"
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
    *)
        show_usage
        ;;
esac 