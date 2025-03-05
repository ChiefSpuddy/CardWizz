#!/bin/bash

# Set colors for better output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}CardWizz Comprehensive Cleanup${NC}"
echo "=============================="

# Create final backup directory just in case
BACKUP_DIR="final_backups_$(date +"%Y%m%d_%H%M%S")"
mkdir -p "$BACKUP_DIR"
echo -e "${YELLOW}Created backup directory: $BACKUP_DIR${NC}"

# Function to confirm deletion
confirm_delete() {
  local message="$1"
  local default="$2"
  
  if [ "$default" = "y" ]; then
    prompt="Y/n"
    default="Y"
  else
    prompt="y/N"
    default="N"
  fi
  
  read -p "$message [$prompt]: " response
  response=${response:-$default}
  
  if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    return 0  # true
  else
    return 1  # false
  fi
}

echo -e "\n${YELLOW}Looking for files to clean up...${NC}"

# 1. Remove all tool scripts
echo -e "1. Tool scripts:"
TOOL_FILES=$(find . -path "*/tools/*" -type f -name "*.dart" -o -name "*.sh" | grep -v "cleanup_all.sh")
if [ -n "$TOOL_FILES" ]; then
  echo "$TOOL_FILES"
  if confirm_delete "Delete all tool scripts?" "y"; then
    while read -r file; do
      if [ -n "$file" ]; then
        cp "$file" "$BACKUP_DIR/$(basename "$file")"
        rm "$file"
        echo -e "${GREEN}✓ Removed: $file${NC}"
      fi
    done <<< "$TOOL_FILES"
  fi
else
  echo "No tool scripts found."
fi

# 2. Remove additional cleanup scripts at root level
echo -e "\n2. Root level cleanup scripts:"
ROOT_CLEANUP=$(find . -maxdepth 1 -type f -name "remove_*.sh" -o -name "*clean*.sh" | grep -v "cleanup_all.sh")
if [ -n "$ROOT_CLEANUP" ]; then
  echo "$ROOT_CLEANUP"
  if confirm_delete "Delete these cleanup scripts?" "y"; then
    while read -r file; do
      if [ -n "$file" ]; then
        cp "$file" "$BACKUP_DIR/$(basename "$file")"
        rm "$file"
        echo -e "${GREEN}✓ Removed: $file${NC}"
      fi
    done <<< "$ROOT_CLEANUP"
  fi
else
  echo "No root cleanup scripts found."
fi

# 3. Remove backup files
echo -e "\n3. Backup files:"
BACKUP_FILES=$(find . -type f -name "*.backup*" -o -name "*.bak" -o -name "main.dart.*")
if [ -n "$BACKUP_FILES" ]; then
  echo "$BACKUP_FILES"
  if confirm_delete "Delete all backup files?" "y"; then
    while read -r file; do
      if [ -n "$file" ]; then
        cp "$file" "$BACKUP_DIR/$(basename "$file")"
        rm "$file"
        echo -e "${GREEN}✓ Removed: $file${NC}"
      fi
    done <<< "$BACKUP_FILES"
  fi
else
  echo "No backup files found."
fi

# 4. Remove backup directories
echo -e "\n4. Backup directories:"
BACKUP_DIRS=$(find . -maxdepth 1 -type d -name "*backup*" -o -name "*fix*" | grep -v "$BACKUP_DIR")
if [ -n "$BACKUP_DIRS" ]; then
  echo "$BACKUP_DIRS"
  if confirm_delete "Delete all backup directories?" "y"; then
    while read -r dir; do
      if [ -n "$dir" ] && [ "$dir" != "./$BACKUP_DIR" ]; then
        rm -rf "$dir"
        echo -e "${GREEN}✓ Removed directory: $dir${NC}"
      fi
    done <<< "$BACKUP_DIRS"
  fi
else
  echo "No backup directories found."
fi

# 5. Remove temp/other unused files
echo -e "\n5. Temporary and other unused files:"
TEMP_FILES=$(find . -type f -name "*.tmp" -o -name "*.log" -o -name "temp_*" -o -name "simple_main.dart")
if [ -n "$TEMP_FILES" ]; then
  echo "$TEMP_FILES"
  if confirm_delete "Delete these temporary files?" "y"; then
    while read -r file; do
      if [ -n "$file" ]; then
        cp "$file" "$BACKUP_DIR/$(basename "$file")"
        rm "$file"
        echo -e "${GREEN}✓ Removed: $file${NC}"
      fi
    done <<< "$TEMP_FILES"
  fi
else
  echo "No temporary files found."
fi

# 6. Flutter clean
echo -e "\n6. Flutter build artifacts:"
if confirm_delete "Run 'flutter clean' to remove build artifacts?" "y"; then
  flutter clean
  echo -e "${GREEN}✓ Flutter build artifacts removed${NC}"
  
  # Run flutter pub get
  echo -e "\nRestoring packages..."
  flutter pub get
  echo -e "${GREEN}✓ Flutter packages restored${NC}"
fi

echo -e "\n${GREEN}Cleanup complete!${NC}"
echo "Everything has been backed up to: $BACKUP_DIR"
echo -e "${YELLOW}To remove this cleanup script too, run: rm cleanup_all.sh${NC}"
