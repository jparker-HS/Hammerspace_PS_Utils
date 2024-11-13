#!/bin/bash
# hs_alias_builder.sh
# Simple script to take a CSV file and build the main body of the alias portion of the share-update API call.
# CSV should have alias, path
# Author JParker 11-13-2024
# Revision 1: Initial release

# Check if the input file is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <input.csv>"
    exit 1
fi

input_file="$1"
output="["
first_line=true

# Read the CSV file line by line
while IFS=',' read -r colA colB; do
    # Skip the header row if present
    if $first_line; then
        first_line=false
        continue
    fi

    # Get the current timestamp
    timestamp=$(date +%s)

    # Add a comma if it's not the first item
    if [[ $output != "[" ]]; then
        output+=", "
    fi

    # Append the JSON object
    output+="{\"name\":\"$colA\",\"path\":\"$colB\",\"modified\":\"$timestamp\"}"
done < "$input_file"

output+="]"

# Print the result
echo "$output"