#!/bin/bash

notify_endpoint="{MS Workflow webhook URL}"
message=$1

curl -X POST $notify_endpoint -H "Content-Type: application/json" -d '{ "type": "message", "attachments": [ { "contentType": "application/vnd.microsoft.card.adaptive", "content": { "$schema": "http://adaptivecards.io/schemas/adaptive-card.json", "type": "AdaptiveCard", "version": "1.0", "body": [ { "type": "TextBlock", "text": '"'$message'"' } ] } } ] }' 
