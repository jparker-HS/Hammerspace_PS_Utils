#!/bin/bash
# vol_assim.sh
# Add volumes, assimilate then decommission.
# Author J. Parker, 04/05/2025
# Version 0.1 -- written for a customer that needs to assimilate a large number of volumes into a single, or limited number of shares. Ver 0.1 is basic AF and needs more error checking. This is a logic run to make sure the overall process worked.

# Generate timestamp for the log file
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="/tmp/vol_assims_${TIMESTAMP}.log"

echo "Starting volume assimilation process at $(date)" >> "$LOG_FILE"

# Skip the header line
tail -n +2 "$1" | while IFS=',' read -r LV_NAME NODE_NAME SHARE_NAME DEST_PATH; do
  echo "Processing volume: LV_NAME=$LV_NAME, NODE_NAME=$NODE_NAME, SHARE_NAME=$SHARE_NAME, DEST_PATH=$DEST_PATH" >> "$LOG_FILE"

  # Check for running volume assimilation tasks
  while true; do
    RUNNING_TASKS=$(hscli task-list --name volume-assimilation 2>> "$LOG_FILE" | grep "Status: *EXECUTING" | wc -l)
    echo "Number of running volume assimilation tasks: $RUNNING_TASKS" >> "$LOG_FILE"
    if [[ "$RUNNING_TASKS" -lt 2 ]]; then
      break
    fi
    echo "More than 2 volume assimilation tasks are running. Waiting..." >> "$LOG_FILE"
    sleep 60 # Wait for 60 seconds before checking again
  done

  # Add the volume
  echo "Adding volume: $LV_NAME on $NODE_NAME" >> "$LOG_FILE"
  hscli volume-add --async --logical-volume-name "$LV_NAME" --node-name "$NODE_NAME" --access-type READ_ONLY >> "$LOG_FILE" 2>&1
  echo "Volume addition initiated. Waiting for 30 seconds..." >> "$LOG_FILE"
  sleep 30

  # Perform volume assimilation
  VOL_NAME="$NODE_NAME::$LV_NAME" # We can look at changing this to use ID but that will take a query.
  echo "Starting volume assimilation for $VOL_NAME" >> "$LOG_FILE"
  hscli volume-assimilation --async --log --name "$VOL_NAME" --share-name "$SHARE_NAME" --destination-path "$DEST_PATH" --skip-file-access-test >> "$LOG_FILE" 2>&1
  echo "Volume assimilation initiated for $VOL_NAME" >> "$LOG_FILE"
  echo "####################" >> "$LOG_FILE"
  echo "" >> "$LOG_FILE"
done

echo "Finished adding and assimilating all volumes from the input file." >> "$LOG_FILE"
echo "" >> "$LOG_FILE"
echo "The following assimilations are still running check to see if they are long running or have hung" >> "$LOG_FILE"
hscli task-list --name volume-assimilation --status EXECUTING >> "$LOG_FILE" 




# Decommission volumes -- Pull out and place in a separate script
# We will need more checks in this section. For one we will want to make sure assimilations are completed before decomm. Then make sure decomm is done before remove.
#echo "Starting volume decommissioning..." >> "$LOG_FILE"
#tail -n +2 "$1" | while IFS=',' read -r LV_NAME NODE_NAME _ _; do
#  VOLUME_TO_DECOMMISSION="$NODE_NAME::$LV_NAME"
#  echo "Decommissioning volume: $VOLUME_TO_DECOMMISSION" >> "$LOG_FILE"
#  hscli volume-decommission --name "$VOLUME_TO_DECOMMISSION" >> "$LOG_FILE" 2>&1
#  sleep 120
#  hscli volume-remove --name "$VOLUME_TO_DECOMMISSION" >> "$LOG_FILE" 2>&1
#done

#echo "Volume decommissioning process completed at $(date)" >> "$LOG_FILE"

#echo "Logs can be found in: $LOG_FILE"

