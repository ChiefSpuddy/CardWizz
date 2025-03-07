#!/bin/bash

# Create directory if not exists
mkdir -p assets/images

echo "Creating sample background images..."

# Create a simple purple background
echo '<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<svg width="800" height="600" xmlns="http://www.w3.org/2000/svg">
  <rect width="800" height="600" fill="#1a103b" />
  <rect width="800" height="600" fill="url(#grad)" />
  <defs>
    <linearGradient id="grad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#2c1068;stop-opacity:1" />
      <stop offset="100%" style="stop-color:#150833;stop-opacity:1" />
    </linearGradient>
  </defs>
</svg>' > assets/images/arena_background.svg

# Create a battle background
echo '<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<svg width="800" height="600" xmlns="http://www.w3.org/2000/svg">
  <rect width="800" height="600" fill="#0a0a0a" />
  <rect width="800" height="600" fill="url(#grad)" />
  <defs>
    <linearGradient id="grad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#1a0e33;stop-opacity:1" />
      <stop offset="100%" style="stop-color:#000000;stop-opacity:1" />
    </linearGradient>
  </defs>
</svg>' > assets/images/battle_background.svg

# Convert SVG to PNG if inkscape is available (optional)
if command -v inkscape &> /dev/null; then
  echo "Converting SVG to JPG using Inkscape..."
  inkscape -w 800 -h 600 assets/images/arena_background.svg -o assets/images/arena_background.jpg
  inkscape -w 800 -h 600 assets/images/battle_background.svg -o assets/images/battle_background.jpg
  echo "Converted successfully!"
else
  echo "Inkscape not found. You can manually convert the SVG files to JPG if needed."
  echo "For now, update the code to use SVG files instead of JPG files."
  
  # Update the card_arena_screen.dart file to use gradient instead
  sed -i '' 's/image: AssetImage(.arena_background.jpg.)/gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.purple.shade900, Colors.indigo.shade900],)/g' lib/screens/card_arena_screen.dart
  sed -i '' 's/image: AssetImage(.battle_background.jpg.)/gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black, Colors.blueGrey.shade900],)/g' lib/widgets/card_battle_animation.dart
fi

echo "Background images created!"

# Make this script executable
chmod +x /Users/sam.may/CardWizz/create_sample_bg_images.sh
