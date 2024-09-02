#!/bin/sh

# Variables for paths (no trailing slashes)
DOWNLOAD="/mnt/World/incoming"
COMPLETE="/mnt/World/completed"
LOG_FILE="/mnt/World/mvcompleted.log"
TASK_ID=$1
NUM_FILES=$2
SOURCE_FILE=$3

# Function to log messages
log()  {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Function to find a unique name if there's a conflict
find_unique_name()  {
    local base=$(basename "$1")
    local dir=$(dirname "$1")
    local count=0
    local new_base=$base

    while [ -e "$dir/$new_base" ]; do
        count=$((count + 1))
        new_base="${base%.*}"_"$count.${base##*.}"
    done

    echo "$dir/$new_base"
}

# Function to move files and handle errors
move_file()  {
    local src=$1
    local dst_dir=$2

    if [ ! -d "$dst_dir" ]; then
        mkdir -p "$dst_dir" || { log "ERROR: Failed to create directory $dst_dir."; exit 1; }
    fi

    local dst=$(find_unique_name "$dst_dir/$(basename "$src")")
    mv --backup=t "$src" "$dst" >> "$LOG_FILE" 2>&1 || { log "ERROR: Failed to move $src to $dst."; exit 1; }

    log "INFO: Moved $src to $dst."
}

# Function to move all files within a directory
move_directory_contents() {
    local src_dir=$1
    local dst_dir=$2

    # Ensure the destination directory exists
    mkdir -p "$dst_dir" || { log "ERROR: Failed to create directory $dst_dir."; exit 1; }

    # Loop through all files and directories in the source directory
    for file in "$src_dir"/*; do
        move_file "$file" "$dst_dir"
    done
}

# Main script starts here
log "INFO: Task ID: $TASK_ID Completed."
log "DEBUG: SOURCE_FILE is $SOURCE_FILE"

if [ "$NUM_FILES" -eq 0 ]; then
    log "INFO: No file to move for Task ID $TASK_ID."
    exit 0
fi

# Check if SOURCE_FILE is in the root of the incoming directory
if [ "$(dirname "$SOURCE_FILE")" = "$DOWNLOAD" ]; then
    SOURCE_DIR="$DOWNLOAD"
    DESTINATION_DIR="$COMPLETE"
    log "DEBUG: File is in the root incoming directory"
else
    SOURCE_DIR=$(dirname "$SOURCE_FILE")
    DESTINATION_DIR=$(echo "$SOURCE_DIR" | sed "s,$DOWNLOAD,$COMPLETE,")
    log "DEBUG: File is in a subdirectory"
fi

log "DEBUG: SOURCE_DIR is $SOURCE_DIR"
log "DEBUG: DESTINATION_DIR is $DESTINATION_DIR"

# Prevent moving the entire incoming directory
if [ "$SOURCE_DIR" = "$DOWNLOAD" ] && [ -d "$SOURCE_FILE" ]; then
    log "ERROR: Attempted to move the entire $DOWNLOAD directory, which is not allowed."
    exit 1
fi

# Check if it's a directory and move its contents, otherwise move the file
if [ -d "$SOURCE_FILE" ]; then
    log "DEBUG: Moving contents of the directory $SOURCE_FILE"
    move_directory_contents "$SOURCE_FILE" "$DESTINATION_DIR/$(basename "$SOURCE_FILE")"
else
    log "DEBUG: Moving a single file $SOURCE_FILE"
    move_file "$SOURCE_FILE" "$DESTINATION_DIR"
fi

log "INFO: Task ID $TASK_ID completed successfully."
exit 0
