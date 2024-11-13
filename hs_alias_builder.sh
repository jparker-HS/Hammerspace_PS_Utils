#!/bin/bash
# hs_alias_builder.sh
# Simple script to take a CSV file and build the main body of the alias portion of the share-update API call.
# CSV should have alias, path
# Usage: Redirect output to a file. Add the output of the file to the end of the share-update API call:
# EXAMPLE
# curl -v -s -k -X PUT --header "Content-Type: application/json" --header "Accept: application/json" -u "admin:admin" -d '{"uoid":{"uuid":"622af4c9-ee08-41bd-ba2f-3bd3fcb108f0", "objectType":"SHARE"}, "name": "TheShare", "shareState": "PUBLISHED", "modified": "1699561038221", "smbAliases": <ADD OUTPUT FILE HERE> }' curl -v -s -k -X PUT --header "Content-Type: application/json" --header "Accept: application/json" -u "admin:admin" -d '{"uoid":{"uuid":"622af4c9-ee08-41bd-ba2f-3bd3fcb108f0", "objectType":"SHARE"}, "name": "TheShare", "shareState": "PUBLISHED", "modified": "1699561038221", "smbAliases": [{"name": "RootAlias", "path": "/", "modified": 1699560838000},{"name": "Alias1", "path": "/somedir1", "modified": 1699560838000},{"name": "Alias2", "path": "/somedir2", "modified": 1699560838000}]}' https://10.200.84.156:8443/mgmt/v1.2/rest/shares/622af4c9-ee08-41bd-ba2f-3bd3fcb108f0
# NOTE: Gather the UUID and modifcation information by running THE FOLLOWING COMMAND:
#  curl -s -k -X GET "https://10.200.84.156:8443/mgmt/v1.2/rest/shares" -H "accept: application/json"

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