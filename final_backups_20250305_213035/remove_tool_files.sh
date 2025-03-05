#!/bin/bash

echo "Removing all generated tool files..."

# Create backup directory
BACKUP_DIR="tool_backups_$(date +"%Y%m%d_%H%M")"
mkdir -p "$BACKUP_DIR"

# Find and backup all fix_* files and other tool files
find ./tools -name "fix_*" -o -name "*fix*" -o -name "clean_*" -o -name "*repair*" -o -name "direct_*" | while read file; do
  if [ -f "$file" ]; then
    cp "$file" "$BACKUP_DIR/$(basename "$file")"
    echo "Backed up: $file"
    rm "$file"
    echo "Removed: $file"
  fi
done

echo "All tool files removed. Backups saved in $BACKUP_DIR"
echo "To remove this script too, run: rm remove_tool_files.sh"
