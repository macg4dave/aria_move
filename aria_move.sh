#!/bin/bash

# Variables for paths (no trailing slashes)
DOWNLOAD="/mnt/World/incoming"
COMPLETE="/mnt/World/completed"
LOG_FILE="/mnt/World/mvcompleted.log"

#Set log level
LOG_LEVEL=2  # 1=NORMAL, 2=NORMAL+ERROR, 3=NORMAL+ERROR+INFO, 4=NORMAL+INFO+ERROR+DEBUG

#aria2 output
TASK_ID=$1
NUM_FILES=$2
SOURCE_FILE=$3

# Function to log messages based on log level
log() {
    local level=$1
    local datetime
    local message=$2
    datetime=$(printf '%(%Y-%m-%d %H:%M:%S)T\n' -1)

    case $level in
        NORMAL)
            echo "$datetime - NORMAL: $message" >> "$LOG_FILE"
            ;;
        ERROR)
            [ $LOG_LEVEL -ge 2 ] && echo "$datetime - ERROR: $message" >> "$LOG_FILE"
            ;;
        INFO)
            [ $LOG_LEVEL -ge 3 ] && echo "$datetime - INFO: $message" >> "$LOG_FILE"
            ;;
        DEBUG)
            [ $LOG_LEVEL -ge 4 ] && echo "$datetime - DEBUG: $message" >> "$LOG_FILE"
            ;;
    esac
}

# Function to find a unique name if there's a conflict
find_unique_name() {
    local base
    local dir
    local count=0
    local new_base

    base=$(basename "$1")
    dir=$(dirname "$1")
    new_base=$base

    log DEBUG "Finding unique name for $1"

    while [ -e "$dir/$new_base" ]; do
        count=$((count + 1))
        new_base="${base%.*}_${count}.${base##*.}"
    done

    log DEBUG "Unique name found: $dir/$new_base"
    echo "$dir/$new_base"
}

# Function to sync files and handle errors using rsync
sync_file() {
    local src=$1
    local dst_dir=$2
    local dst

    log DEBUG "Attempting to sync file $src to directory $dst_dir"

    if [ ! -d "$dst_dir" ]; then
        mkdir -p "$dst_dir" || { log ERROR "Failed to create directory $dst_dir."; exit 1; }
    fi

    dst=$(find_unique_name "$dst_dir/$(basename "$src")")
    rsync -a --backup --suffix=_rsync_backup --remove-source-files "$src" "$dst" >> "$LOG_FILE" 2>&1 || { log ERROR "Failed to sync $src to $dst."; exit 1; }

    log INFO "Synced $src to $dst and removed source."
}

# Function to sync all files within a directory, including all subdirectories
sync_directory() {
    local src_dir=$1
    local dst_dir=$2

    log DEBUG "Attempting to sync directory $src_dir to $dst_dir"

    mkdir -p "$dst_dir" || { log ERROR "Failed to create directory $dst_dir."; exit 1; }

    rsync -a --backup --suffix=_rsync_backup --remove-source-files "$src_dir/" "$dst_dir/" --log-file="$LOG_FILE" --log-file-format="%t - INFO: Copied %f" >> "$LOG_FILE" 2>&1 || { log ERROR "Failed to sync $src_dir to $dst_dir."; exit 1; }

    log INFO "Synced directory $src_dir to $dst_dir and removed source."

    # Attempt to remove the source directory and its empty parent directories if empty
    if find "$src_dir" -type d -empty -delete; then
        log INFO "Deleted empty directories in $src_dir."
    else
        log DEBUG "Some directories in $src_dir were not empty or failed to delete."
    fi
}

# Main script starts here
log INFO "Task ID: $TASK_ID Completed."
log DEBUG "SOURCE_FILE is $SOURCE_FILE"

if [ "$NUM_FILES" -eq 0 ]; then
    log INFO "No file to move for Task ID $TASK_ID."
    exit 0
fi

# Determine the source and destination directories using parameter expansion
SOURCE_DIR=$(dirname "$SOURCE_FILE")
RELATIVE_DIR="${SOURCE_DIR#"$DOWNLOAD"}"
DESTINATION_DIR="$COMPLETE$RELATIVE_DIR"

log DEBUG "SOURCE_DIR is $SOURCE_DIR"
log DEBUG "DESTINATION_DIR is $DESTINATION_DIR"

# Check if SOURCE_FILE is part of a directory and sync the entire directory
if [ "$(basename "$SOURCE_DIR")" != "$(basename "$DOWNLOAD")" ]; then
    log DEBUG "Syncing entire directory as the source file is within a subdirectory"
    sync_directory "$SOURCE_DIR" "$DESTINATION_DIR"
else
    log DEBUG "Syncing a single file $SOURCE_FILE"
    sync_file "$SOURCE_FILE" "$DESTINATION_DIR"

    # Attempt to remove the source directory and its empty parent directories if empty
    if find "$SOURCE_DIR" -type d -empty -delete; then
        log INFO "Deleted empty directories in $SOURCE_DIR."
    else
        log DEBUG "Some directories in $SOURCE_DIR were not empty or failed to delete."
    fi
fi

log NORMAL "Task ID $TASK_ID completed successfully."
log NORMAL "Syncing $SOURCE_FILE completed successfully."
exit 0
