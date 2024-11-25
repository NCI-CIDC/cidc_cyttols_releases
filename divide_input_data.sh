#!/bin/bash

# Check if the correct number of arguments are provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 batch_size main_directory"
    exit 1
fi

# Parameters
BATCH_SIZE=$1
MAIN_DIR=$2

# Validate that batch size is a positive integer
if ! [[ "$BATCH_SIZE" =~ ^[0-9]+$ ]] ; then
   echo "Error: Batch size must be a positive integer."
   exit 1
fi

# Validate that the main directory exists
if [ ! -d "$MAIN_DIR" ]; then
    echo "Error: Main directory does not exist."
    exit 1
fi

# Get a list of files in the main directory
FILES=("$MAIN_DIR"/*)
FILE_COUNT=${#FILES[@]}

# Calculate the number of subdirectories needed
NUM_SUBDIRS=$(( (FILE_COUNT + BATCH_SIZE - 1) / BATCH_SIZE ))

# Create subdirectories and move files
for ((i=0; i<$NUM_SUBDIRS; i++)); do
    SUBDIR="$MAIN_DIR/subdir_$i"
    mkdir -p "$SUBDIR"
    
    START_INDEX=$((i * BATCH_SIZE))
    END_INDEX=$((START_INDEX + BATCH_SIZE))

    for ((j=START_INDEX; j<END_INDEX && j<FILE_COUNT; j++)); do
        cp "${FILES[$j]}" "$SUBDIR"
    done
done

echo "Files have been copied into $NUM_SUBDIRS subdirectories."