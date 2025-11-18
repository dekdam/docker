#!/bin/bash

# -------------------------------------------------------
# Config Settings (Insert your Bot Token and Chat ID here)
# -------------------------------------------------------
BOT_TOKEN="YOUR_BOT_TOKEN_HERE"
CHAT_ID="YOUR_CHAT_ID_HERE"

# -------------------------------------------------------
# Check if message parameter is provided
# -------------------------------------------------------
if [ -z "$1" ]; then
    echo "Error: Please provide a message to send"
    echo "Usage: $0 \"message to send\""
    exit 1
fi

MESSAGE="$1"

# -------------------------------------------------------
# Send message via API
# -s : Silent mode (no progress bar)
# --data-urlencode : Automatically handles spaces and special characters
# -------------------------------------------------------
curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
    -d "chat_id=$CHAT_ID" \
    -d "parse_mode=HTML" \
    --data-urlencode "text=$MESSAGE"

# Add line break for better terminal appearance after sending
echo ""
