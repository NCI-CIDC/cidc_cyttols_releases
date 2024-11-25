#!/bin/bash

# Usage: Update/confirm SOURCE_DATA, CYTTOOLS_LOCATION, FCS_DIR, PANEL, METADATA, RESULTS_BLANKS, and RESULTS_CLUSTERING
# ./cyttoolsPipeline.sh <BATCH SIZE FOR PROCESS>  &> /media/analysis/output/pipeline.log
# Example: ./cyttoolsPipeline.sh 5 &> /media/analysis/output/pipeline.log

# Fill in the varibles below with the locations of your various files
SOURCE_DATA="gs://" #Location of data on portal
CYTTOOLS_LOCATION="/home/pipeline/cyttools/" #Location of cyttools code
FCS_DIR="/media/analysis/input_data/" #Local location of source data
BATCH_SIZE=$1  #Size of batches used for FlowSOM processing and post-processing
PANEL="/media/analysis/results_blank/panelFile.txt" #Local location to store dataset panel
METADATA="/media/analysis/results_blank/MetaDataFile.txt" #Local location to store dataset metadata
RESULTS_BLANKS="/media/analysis/results_blank/" #Local location to store Rdata object
RESULTS_CLUSTERING="/media/analysis/output/clustering/" #Local location to store pipeline output

# Clean up previous runs
rm -r /media/analysis/input_data/*
rm /media/analysis/results_blank/*
rm -r /media/analysis/output/clustering/*

# Pull in SOURCE_DATA
gcloud storage cp "$SOURCE_DATA" "$FCS_DIR"

cd $CYTTOOLS_LOCATION

# if needed, generate panel and meta data files. DO THIS BEFORE YOU RUN THE MAIN ANALYSIS SCRIPT (EG FLOWSOM)!
Rscript cyttools.R --makePanelBlank "$FCS_DIR" "$RESULTS_BLANKS"
Rscript cyttools.R --makeMetaDataBlank "$FCS_DIR" "$RESULTS_BLANKS"

# Get a list of files in the main directory and calculate the number of subdirectories (ie batches)
FILES=("$FCS_DIR"/*)
FILE_COUNT=${#FILES[@]}
NUM_SUBDIRS=$(( (FILE_COUNT + BATCH_SIZE - 1) / BATCH_SIZE ))

# Subdivide Input Data into smaller batches
source divide_input_data.sh "$BATCH_SIZE" "$FCS_DIR" 

# perform clustering analysis on batches, WARNING FlowSOM takes a long time to run and will eat up most of your memory
for ((i=0; i<$NUM_SUBDIRS; i++)); do
    Rscript cyttools.R --cluster=FlowSOM "$FCS_DIR/subdir_$i" "$PANEL" "$RESULTS_CLUSTERING"
done
