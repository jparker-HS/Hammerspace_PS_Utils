#!/bin/bash
# hs_find_by_vol.sh
# List all volumes for a cluster then present the user with a menu of those volumes.
# This will list all storage and object volumes.
# User is prompted for a share to evaluate then we find and list all files with
# an instance on the selected volume.
# TO DO:
#
# REV 1.0  -- J. Parker
# Rev 1.1 -- 20-Ded-24 J.Parker optimized and cleaned up initial run

clear

# Prompt for initials and company name early
read -p 'Your Initials: ' hssevar
read -p 'Customer Name (shortened is fine, no spaces): ' companyvar
DATESTAMP=$(date +"%Y%m%d_%H%M")
vols_output="${hssevar}-${companyvar}-${DATESTAMP}-instances.log"
touch "$vols_output"

# Prompt for IP address and admin password
read -p "Enter the Cluster IP address: " ip_address
read -s -p "Enter the admin password: " admin_password
echo

# Fetch and process volume data
get_volumes() {
    local endpoint="$1"
    local output_file="$2"

    curl -k -s -X GET "https://${ip_address}/mgmt/v1.2/rest/${endpoint}" \
        -u "admin:${admin_password}" \
        -H "accept: application/json" | \
        jq -r ".[] | .name // .associatedLocations[].storageVolume.name" | \
        grep -v null > "$output_file"

    if [ $? -ne 0 ] || [ ! -s "$output_file" ]; then
        echo "Error: Failed to retrieve volumes from ${endpoint}."
        exit 1
    fi
}

# Get storage and object volumes
storage_vols="/tmp/${ip_address}_svols.out"
object_vols="/tmp/${ip_address}_osvols.out"
get_volumes "storage-volumes" "$storage_vols"
get_volumes "object-storage-volumes" "$object_vols"

echo -e "The following volumes are present on ${ip_address}" | tee -a "$vols_output"
echo -e  "--------------------------------------------------------------" | tee -a "$vols_output"
# Combine volumes into a list
mapfile -t volumes < <(cat "$storage_vols" "$object_vols" | sort -u)

# Create a menu for volume selection
PS3="Select a volume: "
select target_vol in "${volumes[@]}"; do
    if [ -n "$target_vol" ]; then
        break
    fi
    echo "Invalid selection. Please choose a valid volume."
done

# Fetch list of Shares
share_list="/tmp/${ip_address}_shares.out"
curl -k -s -u "admin:${admin_password}" -X GET "https://${ip_address}/mgmt/v1.2/rest/shares" -H "accept: application/json" | jq .[].name | grep -v root > "$share_list"
echo -e "Current shares on the Cluster at ${ip_address} are:"
cat ${share_list} | tee -a "$vols_output"

# List NFS mounted volumes. These are for reference. Might turn this into a menu.
echo -e "--------------------------------------------------------------" | tee -a "$vols_output"
echo -e "NFS volumes mounted on this host:" | tee -a "$vols_output"
echo -e "\n"
mount -t nfs | tee -a "$vols_output"
mount -t nfs4 | tee -a "$vols_output"

# Prompt for Hammerspace share directory
echo -e "\nThis script will search for files that have an instance on the volume: $target_vol" | tee -a "$vols_output"
read -p "Enter the directory to start the search: " hs_share

# Total # of files and total space used of files on this volume from the supplied directory
echo -e "Total number of files, Space Used" | tee -a "$vols_output"
hs sum -e 'IS_FILE&&!ISNA(instances[|volume=storage_volume("'"$target_vol"'")])&&ROWS(INSTANCES)==1?{1FILE/FILE,SPACE_USED/BYTES}' "$hs_share" | tee -a "$vols_output"

# Perform recursive search for file list
echo "Searching for files on volume $target_vol starting at $hs_share..." | tee -a "$vols_output"
/usr/local/bin/hs eval -r -e \
    'IS_FILE&&!ISNA(instances[|volume=storage_volume("'"$target_vol"'")])&&ROWS(INSTANCES)==1?PATH' \
    "$hs_share" >> "$vols_output"

echo "Output has been saved in $vols_output"

# Clean up temporary files
rm -f "$storage_vols" "$object_vols" "$share_list"
