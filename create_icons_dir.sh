#!/bin/bash

# Create icons directory
mkdir -p /Users/sam.may/CardWizz/assets/icons

# Create a placeholder icon file
echo "<!-- Placeholder SVG -->" > /Users/sam.may/CardWizz/assets/icons/placeholder.svg

echo "Created icons directory with placeholder icon"

# Make the script executable
chmod +x /Users/sam.may/CardWizz/create_icons_dir.sh
