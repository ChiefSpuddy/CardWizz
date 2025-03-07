#!/bin/bash

echo "Setting up Card Arena..."

# Create all required directories
mkdir -p /Users/sam.may/CardWizz/assets/animations
mkdir -p /Users/sam.may/CardWizz/assets/icons

# Create placeholder animation files
ANIMATIONS=(
  "battle_effect.json"
  "fire_effect.json"
  "water_effect.json"
  "electric_effect.json"
  "earth_effect.json"
  "psychic_effect.json"
  "battle_intro.json"
)

for anim in "${ANIMATIONS[@]}"; do
  if [ ! -f "/Users/sam.may/CardWizz/assets/animations/$anim" ]; then
    echo "Creating $anim placeholder..."
    echo '{
  "v": "5.5.7",
  "fr": 30,
  "ip": 0,
  "op": 60,
  "w": 300,
  "h": 300,
  "nm": "Effect",
  "ddd": 0,
  "assets": [],
  "layers": [
    {
      "ddd": 0,
      "ind": 1,
      "ty": 4,
      "nm": "Shape",
      "sr": 1,
      "ks": {
        "o": {"a": 1, "k": [{"t": 0, "s": [0]}, {"t": 15, "s": [100]}, {"t": 30, "s": [0]}]},
        "r": {"a": 1, "k": [{"t": 0, "s": [0]}, {"t": 30, "s": [360]}]},
        "p": {"a": 0, "k": [150, 150, 0]},
        "a": {"a": 0, "k": [0, 0, 0]},
        "s": {"a": 1, "k": [{"t": 0, "s": [50, 50]}, {"t": 30, "s": [150, 150]}]}
      },
      "shapes": [
        {
          "ty": "el",
          "d": 1,
          "s": {"a": 0, "k": [100, 100]},
          "p": {"a": 0, "k": [0, 0]},
          "nm": "Ellipse"
        },
        {
          "ty": "st",
          "c": {"a": 0, "k": [1, 1, 1, 1]},
          "o": {"a": 0, "k": 100},
          "w": {"a": 0, "k": 4},
          "lc": 1,
          "lj": 1,
          "ml": 4,
          "nm": "Stroke"
        }
      ]
    }
  ]
}' > "/Users/sam.may/CardWizz/assets/animations/$anim"
  fi
done

# Create placeholder icon
echo '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24"><path d="M0 0h24v24H0z" fill="none"/><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm0 18c-4.41 0-8-3.59-8-8s3.59-8 8-8 8 3.59 8 8-3.59 8-8 8z"/></svg>' > /Users/sam.may/CardWizz/assets/icons/placeholder.svg

echo "Cleaning project..."
flutter clean

echo "Getting dependencies..."
flutter pub get

echo "Card Arena setup complete! Run the app with 'flutter run'"
