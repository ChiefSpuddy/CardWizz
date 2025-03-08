#!/bin/bash

# This script helps you safely test file removal by renaming files
# rather than deleting them immediately

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}===== CardWizz File Removal Testing =====${NC}"

# Check if a file path is provided
if [ -z "$1" ]; then
  echo -e "${RED}Error: Please provide a file path to test for removal${NC}"
  echo "Usage: $0 lib/path/to/file.dart"
  exit 1
fi

FILE_PATH=$1
BACKUP_PATH="${FILE_PATH}.unused"

# Check if file exists
if [ ! -f "$FILE_PATH" ]; then
  echo -e "${RED}Error: File not found: $FILE_PATH${NC}"
  exit 1
fi

# Check if backup already exists
if [ -f "$BACKUP_PATH" ]; then
  echo -e "${YELLOW}Warning: Backup already exists: $BACKUP_PATH${NC}"
  echo "Do you want to restore the original file? (y/n)"
  read -r RESTORE
  
  if [[ $RESTORE =~ ^[Yy]$ ]]; then
    mv "$BACKUP_PATH" "$FILE_PATH"
    echo -e "${GREEN}Original file restored from backup${NC}"
    exit 0
  else
    echo "Keeping the current state."
    exit 0
  fi
fi

# Backup the file by renaming
echo -e "${YELLOW}Backing up $FILE_PATH to $BACKUP_PATH${NC}"
mv "$FILE_PATH" "$BACKUP_PATH"

echo -e "${GREEN}File renamed for testing removal${NC}"
echo ""
echo -e "${YELLOW}Testing steps:${NC}"
echo "1. Run your app and test functionality thoroughly"
echo "2. If everything works, you can safely delete $BACKUP_PATH"
echo "3. If issues occur, restore the file with:"
echo "   $0 $FILE_PATH"

exit 0
