#!/bin/bash

# URLs for the GitHub release page and API
RELEASE_URL="https://github.com/Ananda-Aropa/aaropa_rootfs_installer_bass/releases/latest"
API_URL="https://api.github.com/repos/Ananda-Aropa/aaropa_rootfs_installer_bass/releases/latest"
VERSION_FILE="version.txt"

# Get the script's directory and change to it
SCRIPT_DIR=$(dirname "$0")
cd "$SCRIPT_DIR" || exit

# Function to get the latest tag from GitHub API
get_latest_version() {
  if command -v curl &> /dev/null; then
    curl -s "$API_URL" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/'
  elif command -v wget &> /dev/null; then
    wget -qO- "$API_URL" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/'
  fi
}

# Function to check version and optionally exit
check_version() {
  echo "Checking for the latest version..."
  LATEST_VERSION=$(get_latest_version)
  
  if [[ -z "$LATEST_VERSION" ]]; then
    echo "Warning: Could not determine the latest version from GitHub. Proceeding with download..."
    return 0
  fi

  if [[ -f "$VERSION_FILE" ]]; then
    LOCAL_VERSION=$(cat "$VERSION_FILE")
    if [[ "$LATEST_VERSION" == "$LOCAL_VERSION" ]]; then
      echo "You already have the latest version ($LATEST_VERSION). Skipping download."
      exit 0
    fi
  fi
  
  echo "New version found: $LATEST_VERSION (Current: ${LOCAL_VERSION:-None})"
}

# Function to update the version file
update_version() {
  if [[ -n "$LATEST_VERSION" ]]; then
    echo "$LATEST_VERSION" > "$VERSION_FILE"
    echo "Updated $VERSION_FILE to $LATEST_VERSION."
  fi
}

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
Copyright (C) 2026 BlissLabs

Usage: ./download.sh [OPTION]

Options:
  --help                Show this help message and exit.
EOF
}

# Handle the command line argument using a case statement
case "$1" in
--help) show_help && exit 0 ;;
esac

# Check the version first before doing any file operations
check_version

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

# Save the new version
update_version
echo "Script execution complete!"

exit 0
