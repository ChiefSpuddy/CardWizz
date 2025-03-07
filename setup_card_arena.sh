#!/bin/bash

echo "Starting Card Arena setup..."

# Create all necessary directories
mkdir -p /Users/sam.may/CardWizz/assets/animations
mkdir -p /Users/sam.may/CardWizz/assets/icons
mkdir -p /Users/sam.may/CardWizz/assets/images

# Create placeholder SVG for icons directory
echo '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24">
  <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm0 18c-4.42 0-8-3.58-8-8s3.58-8 8-8 8 3.58 8 8-3.58 8-8 8z"/>
  <path d="M0 0h24v24H0z" fill="none"/>
</svg>' > /Users/sam.may/CardWizz/assets/icons/placeholder.svg

echo "Created all necessary directories"

# Ensure animation files exist
if [ ! -f "/Users/sam.may/CardWizz/assets/animations/battle_effect.json" ]; then
  echo "Creating battle_effect.json"
  cp "/Users/sam.may/CardWizz/assets/animations/placeholder.json" "/Users/sam.may/CardWizz/assets/animations/battle_effect.json" 2>/dev/null || echo '{
  "v": "5.5.7",
  "fr": 30,
  "ip": 0,
  "op": 60,
  "w": 300,
  "h": 300,
  "layers": []
}' > "/Users/sam.may/CardWizz/assets/animations/battle_effect.json"
fi

# Do the same for all other required animation files
for anim in fire_effect.json water_effect.json electric_effect.json earth_effect.json psychic_effect.json battle_intro.json; do
  if [ ! -f "/Users/sam.may/CardWizz/assets/animations/$anim" ]; then
    echo "Creating $anim"
    echo '{
  "v": "5.5.7",
  "fr": 30,
  "ip": 0,
  "op": 60,
  "w": 300,
  "h": 300,
  "layers": []
}' > "/Users/sam.may/CardWizz/assets/animations/$anim"
  fi
done

echo "All animation files created"

# Run Flutter pub get to ensure dependencies are up to date
cd /Users/sam.may/CardWizz
flutter pub get

echo "Setup complete! Run 'flutter run' to launch the app"

# Make this script executable
chmod +x /Users/sam.may/CardWizz/setup_card_arena.sh
