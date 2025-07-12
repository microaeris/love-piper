#!/bin/bash

cd build

pwd

python3 -m http.server 8000 &
SERVER_PID=$!

open http://localhost:8000

echo "Server started on http://localhost:8000"
echo "Press Ctrl+C to stop the server"

# Function to clean up
cleanup() {
    echo "Stopping server..."
    kill $SERVER_PID 2>/dev/null
    kill $(lsof -t -i:8000) 2>/dev/null
    echo "Server stopped"
    exit 0
}

# Set up trap to catch Ctrl+C
trap cleanup SIGINT SIGTERM

# Wait indefinitely
wait
