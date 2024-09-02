#!/bin/sh

# Variables for paths (no trailing slashes)
DOWNLOAD=/mnt/World/incoming
COMPLETE=/mnt/World/completed
LOG=/mnt/World/mvcompleted.log

# Logging function
log() {
    echo "$(date) $1" >> "$LOG"
}

# Function to check and rename if file/folder exists
find_unique_name() {
    local base_name=$(basename "$1")
    local dir_name=$(dirname "$1")
    local new_name="$base_name"
    local count=1

    while [ -e "$dir_name/$new_name" ]; do
        new_name="${base_name}_${count}"
        count=$((count + 1))
    done

    echo "$dir_name/$new_name"
}

# Function to move files and handle errors
move_file() {
    local src=$1
    local dst_dir=$2

    # Ensure destination directory exists and is writable
    if [ ! -d "$dst_dir" ]; then
        if [ -e "$dst_dir" ]; then
            log "ERROR: $dst_dir exists but is not a directory."
            exit 1
        else
            mkdir -p "$dst_dir" || { log "ERROR: Failed to create directory $dst_dir."; exit 1; }
        fi
    fi

    if [ ! -w "$dst_dir" ]; then
        log "ERROR: Destination directory $dst_dir is not writable."
        exit 1
    fi

    # Find a unique name if there's a conflict
    local dst=$(find_unique_name "$dst_dir/$(basename "$src")")
    mv --backup=t "$src" "$dst" >> "$LOG" 2>&1 || { log "ERROR: Failed to move $src to $dst."; exit 1; }
    log "INFO: Moved $src to $dst."
}

# Main script starts here
log "INFO: Task ID: $1 Completed."

if [ "$2" -eq 0 ]; then
    log "INFO: No file to move for Task ID $1."
    exit 0
fi

SRC=$3
SRCDIR=$(dirname "$SRC")
DSTDIR=$(echo "$SRCDIR" | sed "s,$DOWNLOAD,$COMPLETE,g")

# Ensure the source directory is within the expected download directory
if [ "$SRCDIR" = "$DSTDIR" ]; then
    log "ERROR: $SRC is not under $DOWNLOAD."
    exit 1
fi

# Move the file and clean up
move_file "$SRC" "$DSTDIR"

# Clean up empty directories
while [ "$SRCDIR" != "$DOWNLOAD" ]; do
    if [ ! "$(ls -A "$SRCDIR")" ]; then
        rmdir "$SRCDIR" >> "$LOG" 2>&1 || { log "ERROR: Failed to remove directory $SRCDIR."; exit 1; }
        SRCDIR=$(dirname "$SRCDIR")
    else
        break
    fi
done

log "INFO: Task ID $1 completed successfully."
exit 0

