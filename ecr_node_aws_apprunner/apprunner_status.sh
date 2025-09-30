#!/bin/bash
SERVICE_NAME=$1
PROFILE=$2
REGION=$3

# Maximum number of attempts
max_attempts=30

# Counter for attempts
attempts=0

# Function to fetch data
fetch_data() {
    # Command to fetch data (replace with your actual command)
    data=$(aws apprunner list-services --query "ServiceSummaryList[?ServiceName=='$SERVICE_NAME'].Status|[0]" --profile $PROFILE --region $REGION)
    echo "$data"
}

echo "Checking ($REGION) running service..."
sleep 10

# Main loop
while true; do
    # Increment attempts counter
    attempts=$((attempts + 1))

    # Fetch data
    result=$(fetch_data)
    
    # Check if the result is not "RUNNING"
    if echo "$result" | grep -q "RUNNING"; then
        echo "Data retrieval successful. Result: $result"
        sh ./../notify.sh "App runner ($REGION) is $result"
        break  # Exit the loop if condition is met
    else
        echo "Data is $result. Attempt: $attempts"
    fi

    # Check if maximum attempts reached
    if [ $attempts -ge $max_attempts ]; then
        echo "Maximum attempts reached. Exiting."
        break
    fi

    # Add a delay before next attempt (optional)
    sleep 30  # Adjust the delay time as needed
done
