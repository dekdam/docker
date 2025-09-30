#!/bin/bash

# Check if the correct number of arguments are provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <search_text> <file_path>"
    exit 1
fi

search_text="$1"
file_path="$2"

# Check if the file exists
if [ ! -f "$file_path" ]; then
    echo "File not found: $file_path"
    exit 1
fi

# Use grep to search for the text in the file and print matching lines
# along with the next 15 lines
grep -A 15 "$search_text" "$file_path"