#!/bin/bash

# Folders to clear
FOLDER_PATH1="./outputs/csvs"
FOLDER_PATH2="./outputs/graphs"

# Function to delete files in a folder
delete_files_in_folder() {
  local FOLDER_PATH="$1"

  if [ -d "$FOLDER_PATH" ]; then
    rm -f "$FOLDER_PATH"/*
    echo "All files in '$FOLDER_PATH' have been deleted."
  else
    echo "The folder '$FOLDER_PATH' does not exist."
  fi
}

# Clear files in both folders
delete_files_in_folder "$FOLDER_PATH1"
delete_files_in_folder "$FOLDER_PATH2"

