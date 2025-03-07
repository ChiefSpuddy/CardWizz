#!/bin/bash

# Create placeholder files for each required animation
mkdir -p /Users/sam.may/CardWizz/assets/animations

# Create simple placeholder animation files
for anim in battle_effect.json fire_effect.json water_effect.json electric_effect.json earth_effect.json psychic_effect.json battle_intro.json; do
  if [ ! -f "/Users/sam.may/CardWizz/assets/animations/$anim" ]; then
    echo '{
  "v": "5.5.7",
  "fr": 30,
  "ip": 0,
  "op": 60,
  "w": 300,
  "h": 300,
  "layers": []
}' > "/Users/sam.may/CardWizz/assets/animations/$anim"
    echo "Created placeholder for $anim"
  fi
done

echo "All animation placeholders created"
