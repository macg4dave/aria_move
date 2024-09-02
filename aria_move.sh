#!/bin/sh

# Variables for paths (no trailing slashes)
DOWNLOAD="/mnt/World/incoming"
COMPLETE="/mnt/World/completed"
LOG_FILE="/mnt/World/mvcompleted.log"
TASK_ID=$1
NUM_FILES=$2
SOURCE_FILE=$3
LOG_LEVEL=1  # 1=NORMAL, 2=NORMAL+INFO, 3=NORMAL+INFO+ERROR, 4=NORMAL+DEBUG+INFO+ERROR

# Function to log messages based on log level
log() {
    local level=$1
    local message=$2
    local datetime=$(date '+%Y-%m-%d %H:%M:%S')

    case $level in
        NORMAL)
            echo "$datetime - NORMAL: $message" >> "$LOG_FILE"
            ;;
        ERROR)
            echo "$datetime - ERROR: $message" >> "$LOG_FILE"
            ;;
        INFO)
            [ $LOG_LEVEL -ge 2 ] && echo "$datetime - INFO: $message" >> "$LOG_FILE"
            ;;
        DEBUG)
            [ $LOG_LEVEL -ge 3 ] && echo "$datetime - DEBUG: $message" >> "$LOG_FILE"
            ;;
    esac
}

# Function to find a unique name if there's a conflict
find_unique_name() {
    local base=$(basename "$1")
    local dir=$(dirname "$1")
    local count=0
    local new_base=$base

    log DEBUG "Finding unique name for $1"

    while [ -e "$dir/$new_base" ]; do
        count=$((count + 1))
        new_base="${base%.*}"_"$count.${base##*.}"
    done

    log DEBUG "Unique name found: $dir/$new_base"
    echo "$dir/$new_base"
}

# Function to move files and handle errors
move_file() {
    local src=$1
    local dst_dir=$2

    log DEBUG "Attempting to move file $src to directory $dst_dir"

    if [ ! -d "$dst_dir" ]; then
        mkdir -p "$dst_dir" || { log ERROR "Failed to create directory $dst_dir."; exit 1; }
    fi

    local dst=$(find_unique_name "$dst_dir/$(basename "$src")")
    mv --backup=t "$src" "$dst" >> "$LOG_FILE" 2>&1 || { log ERROR "Failed to move $src to $dst."; exit 1; }

    log INFO "Moved $src to $dst."
}

# Function to move all files within a directory
move_directory() {
    local src_dir=$1
    local dst_dir=$2

    log DEBUG "Attempting to move directory $src_dir to $dst_dir"

    mkdir -p "$dst_dir" || { log ERROR "Failed to create directory $dst_dir."; exit 1; }

    mv --backup=t "$src_dir" "$dst_dir" >> "$LOG_FILE" 2>&1 || { log ERROR "Failed to move $src_dir to $dst_dir."; exit 1; }

    log INFO "Moved directory $src_dir to $dst_dir."
}

# Main script starts here
log INFO "Task ID: $TASK_ID Completed."
log DEBUG "SOURCE_FILE is $SOURCE_FILE"

if [ "$NUM_FILES" -eq 0 ]; then
    log INFO "No file to move for Task ID $TASK_ID."
    exit 0
fi

# Determine the source and destination directories
SOURCE_DIR=$(dirname "$SOURCE_FILE")
DESTINATION_DIR=$(echo "$SOURCE_DIR" | sed "s,$DOWNLOAD,$COMPLETE,")

log DEBUG "SOURCE_DIR is $SOURCE_DIR"
log DEBUG "DESTINATION_DIR is $DESTINATION_DIR"

# Check if SOURCE_FILE is part of a directory and move the entire directory
if [ "$(basename "$SOURCE_DIR")" != "$(basename "$DOWNLOAD")" ]; then
    log DEBUG "Moving entire directory as the source file is within a subdirectory"
    move_directory "$SOURCE_DIR" "$COMPLETE"
else
    log DEBUG "Moving a single file $SOURCE_FILE"
    move_file "$SOURCE_FILE" "$DESTINATION_DIR"
fi

log NORMAL "Task ID $TASK_ID completed successfully."
log NORMAL "Moving $SOURCE_FILE completed successfully."
exit 0
