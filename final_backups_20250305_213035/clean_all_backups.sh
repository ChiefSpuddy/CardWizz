#!/bin/bash

# Colors for better output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}CardWizz Project Cleanup${NC}"
echo "========================="

# Create a directory for any backups of files we'll delete
FINAL_BACKUP_DIR="final_backups_$(date +"%Y%m%d_%H%M")"
mkdir -p "$FINAL_BACKUP_DIR"
echo -e "${YELLOW}Created final backup directory: $FINAL_BACKUP_DIR${NC}"

# Track cleanup stats
REMOVED_FILES=0
BACKED_UP=0

# Function to find and handle files matching a pattern
find_and_handle() {
  local pattern="$1"
  local description="$2"
  
  echo -e "\n${YELLOW}Looking for $description...${NC}"
  
  # Find all files matching the pattern
  FILES=$(find . -type f -name "$pattern" | sort)
  COUNT=$(echo "$FILES" | grep -v "^$" | wc -l)
  
  if [ "$COUNT" -gt 0 ]; then
    echo -e "Found $COUNT $description files:"
    echo "$FILES"
    
    # Confirm before removing
    echo -e "\n${YELLOW}Do you want to backup and remove these files? (y/N)${NC}"
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
      # Process each file
      echo "$FILES" | while read -r file; do
        if [ -n "$file" ]; then
          # Make backup
          cp "$file" "$FINAL_BACKUP_DIR/$(basename "$file")"
          BACKED_UP=$((BACKED_UP + 1))
          
          # Remove file
          rm "$file"
          REMOVED_FILES=$((REMOVED_FILES + 1))
          echo "✓ Removed: $file"
        fi
      done
    else
      echo "Skipping removal of $description files."
    fi
  else
    echo "No $description files found."
  fi
}

# 1. Clean up backup files
find_and_handle "*.backup*" "backup"
find_and_handle "*.bak" "bak"
find_and_handle "*.backup.*" "backup dot"
find_and_handle "main.dart.*" "main.dart backup"

# 2. Clean up backup directories
echo -e "\n${YELLOW}Looking for backup directories...${NC}"
BACKUP_DIRS=$(find . -maxdepth 1 -type d -name "*backup*" | sort)
BACKUP_DIR_COUNT=$(echo "$BACKUP_DIRS" | grep -v "^$" | wc -l)

if [ "$BACKUP_DIR_COUNT" -gt 0 ]; then
  echo -e "Found $BACKUP_DIR_COUNT backup directories:"
  echo "$BACKUP_DIRS"
  
  echo -e "\n${YELLOW}Do you want to remove these directories? (y/N)${NC}"
  read -r response
  if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    echo "$BACKUP_DIRS" | while read -r dir; do
      if [ -n "$dir" ] && [ "$dir" != "./$FINAL_BACKUP_DIR" ]; then
        rm -rf "$dir"
        echo "✓ Removed directory: $dir"
      fi
    done
  else
    echo "Skipping removal of backup directories."
  fi
else
  echo "No backup directories found."
fi

# 3. Clean up tools directory
echo -e "\n${YELLOW}Looking for leftover tool files...${NC}"
TOOL_FILES=$(find ./tools -name "fix_*" -o -name "*fix*" -o -name "clean_*" -o -name "*repair*" -o -name "direct_*" -o -name "*.dart" -o -name "*.sh" | grep -v "\/lib\/" | sort)
TOOL_COUNT=$(echo "$TOOL_FILES" | grep -v "^$" | wc -l)

if [ "$TOOL_COUNT" -gt 0 ]; then
  echo -e "Found $TOOL_COUNT tool files:"
  echo "$TOOL_FILES"
  
  echo -e "\n${YELLOW}Do you want to backup and remove these files? (y/N)${NC}"
  read -r response
  if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    echo "$TOOL_FILES" | while read -r file; do
      if [ -n "$file" ]; then
        # Make backup
        mkdir -p "$FINAL_BACKUP_DIR/tools"
        cp "$file" "$FINAL_BACKUP_DIR/tools/$(basename "$file")"
        BACKED_UP=$((BACKED_UP + 1))
        
        # Remove file
        rm "$file"
        REMOVED_FILES=$((REMOVED_FILES + 1))
        echo "✓ Removed: $file"
      fi
    done
  else
    echo "Skipping removal of tool files."
  fi
else
  echo "No tool files found."
fi

# 4. Clean up temporary files
find_and_handle "*.tmp" "temporary"
find_and_handle "*.log" "log"
find_and_handle "*.temp" "temp"

# 5. Clean up Flutter build artifacts
echo -e "\n${YELLOW}Do you want to run Flutter clean to remove build artifacts? (y/N)${NC}"
read -r response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
  echo "Running flutter clean..."
  flutter clean
  echo "Running flutter pub get..."
  flutter pub get
  echo -e "${GREEN}✓ Flutter clean completed${NC}"
fi

echo -e "\n${GREEN}=======================${NC}"
echo -e "${GREEN}Cleanup Summary:${NC}"
echo -e "Files removed: $REMOVED_FILES"
echo -e "Files backed up: $BACKED_UP"
echo -e "Backup location: $FINAL_BACKUP_DIR"
echo -e "\nCleanup process complete!"

# Ask to remove this script as well
echo -e "\n${YELLOW}Do you want to remove this cleanup script too? (y/N)${NC}"
read -r response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
  cp "$0" "$FINAL_BACKUP_DIR/$(basename "$0")"
  rm "$0"
  echo -e "${GREEN}✓ Removed this cleanup script${NC}"
fi
