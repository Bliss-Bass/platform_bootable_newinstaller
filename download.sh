#!/bin/bash

# URL for the GitHub release page
RELEASE_URL="https://github.com/Ananda-Aropa/aaropa_rootfs_installer_bass/releases/latest"

# Get the script's directory and change to it
SCRIPT_DIR=$(dirname "$0")
cd "$SCRIPT_DIR" || exit

# Function to remove existing files from the FILES list and directories
remove_existing_files() {
  # Remove files listed in the FILES array
  for FILE in "${FILES[@]}"; do
    if [[ -f "$FILE" ]]; then
      echo "Removing existing file: $FILE"
      rm -f "$FILE"*
    fi
  done

  # Remove install_lib and iso directories
  if [[ -d "install_lib" ]]; then
    echo "Removing existing directory: install_lib"
    rm -rf install_lib
  fi

  if [[ -d "iso" ]]; then
    echo "Removing existing directory: iso"
    rm -rf iso
  fi
}

# Function to download files using aria2c
download_with_aria2() {
  local file="$1"
  echo "Downloading $file using aria2c..."
  aria2c -x 16 -s 16 "$RELEASE_URL/download/$file"
}

# Function to download files using wget
download_with_wget() {
  local file="$1"
  echo "Downloading $file using wget..."
  wget "$RELEASE_URL/download/$file"
}

# Function to extract install_lib.tar.gz and move the content to the install folder
extract_install_lib() {
  echo "Extracting install_lib.tar.gz..."
  tar -xzf install_lib.tar.gz
  echo "Setting permissions for install_lib..."
  chmod -R 755 install_lib/*
  # Remove the extracted tar.gz file
  rm -f install_lib.tar.gz
}

# Function to display the help message
show_help() {
  cat <<EOF
Copyright (C) 2024 BlissLabs

Usage: ./download.sh [OPTION]

Options:
  --help                Show this help message and exit.
EOF
}

# Handle the command line argument using a case statement
case "$1" in
--help) show_help && exit 0 ;;
esac

# Files to download
FILES=(
  "install_lib.tar.gz"
)

# Remove existing files before starting the download
remove_existing_files

# Check if aria2c is installed
if command -v aria2c &>/dev/null; then
  echo "aria2c found, using aria2c for download."
  for FILE in "${FILES[@]}"; do
    download_with_aria2 "$FILE"
  done
else
  echo "aria2c not found, falling back to wget."
  for FILE in "${FILES[@]}"; do
    download_with_wget "$FILE"
  done
fi

extract_install_lib

exit 0
