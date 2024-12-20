#!/bin/bash
# hs_find_by_vol.sh
# List all volumes for a cluster then present the user with a menu of those volumes.
# This will list all storage and object volumes.
# User is prompted for a share to evaluate then we find and list all files with
# an instance on the selected volume.
# TO DO: 
#   
# REV 1.0  -- J. Parker

# Output file
vols_output=files-by-vol_$(date +%F_%T)
touch ${vols_output}

# Build List of Storage Volumes
# Prompt for IP address
read -p "Enter the Cluster IP address: " ip_address

# Prompt for password (hidden input)
read -s -p "Enter the admin password: " admin_password
echo  # Add newline after hidden password input

# Make the API call using the provided values
curl -k -X GET "https://${ip_address}/mgmt/v1.2/rest/storage-volumes" \
    -u "admin:${admin_password}" \
    -H "accept: application/json" | \
    jq ".[] | .associatedLocations[]| .storageVolume.name" | \
    grep -v null > /tmp/${ip_address}_svols.out

# Check if the curl command succeeded
if [ $? -ne 0 ]; then
    echo "Error: Failed to retrieve storage volumes. Please check your credentials and connectivity."
    exit 1
fi

# Build List of Object Volumes
# Make the API call using the provided values
curl -k -X GET "https://${ip_address}/mgmt/v1.2/rest/object-storage-volumes" \
    -u "admin:${admin_password}" \
    -H "accept: application/json" | \
    jq ".[] | .name" > /tmp/${ip_address}_osvols.out

# Check if the curl command succeeded
if [ $? -ne 0 ]; then
    echo "Error: Failed to retrieve storage volumes. Please check your credentials and connectivity."
    exit 1
fi

# Combine both volume files into a temporary array
mapfile -t volumes < <(cat  /tmp/${ip_address}_osvols.out  /tmp/${ip_address}_svols.out)

# Remove empty lines and create menu
PS3="Select a volume: "
select vol in "${volumes[@]}"; do
   if [ -n "$vol" ]; then
       # Remove quotes and store in target_vol
       target_vol=$(echo "$vol" | tr -d '"')
       break
   fi
done


# Prompt for Hammerspace share
echo "This script will search for files that have an instance on $target_vol"
echo
echo "The script will perform a recursivve search from the specified directory\n"
echo "This directory must be in a Hammerspace share."
read -p "Enter the directory to start the search: " hs_share

/usr/local/bin/hs eval -r -e 'IS_FILE&&!ISNA(instances[|volume=storage_volume("'"$target_vol"'")])&&ROWS(INSTANCES)==1?PATH' ${hs_share} | tee ${vols_output}
echo "Output has been saved in $vols_output"