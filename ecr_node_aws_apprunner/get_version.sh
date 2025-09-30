#!/bin/sh
  
URL=$1

# Download the version data
version_data=$(curl -s "$URL")

# Check if download was successful
if [ -z "$version_data" ]; then
    echo "1.0.0"
else
    # Extract the current version number
    current_version=$(echo "$version_data" | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+')

    # Check if version extraction was successful
    if [ -z "$current_version" ]; then
        echo "Error: Could not extract version number from data"
        exit 1
    fi

    # Split version into components (major, minor, patch)
    major=$(echo "$current_version" | cut -d. -f1)
    minor=$(echo "$current_version" | cut -d. -f2)
    patch=$(echo "$current_version" | cut -d. -f3)

    # Increment the last version number (patch)
    patch=$((patch + 1))

    # Rebuild the new version string
    new_version="$major.$minor.$patch"

    echo "$new_version"
fi