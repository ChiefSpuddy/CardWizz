#!/bin/bash

echo "Setting up assets for Card Arena..."

# Create necessary directories
mkdir -p assets/images
mkdir -p assets/animations

# Download placeholder battle background image if not exists
if [ ! -f "assets/images/arena_background.jpg" ]; then
  echo "Downloading arena background image..."
  curl -o assets/images/arena_background.jpg "https://images.unsplash.com/photo-1612779193211-be8613d248ba?ixlib=rb-1.2.1&auto=format&fit=crop&w=1000&q=80" || {
    echo "Download failed. Creating a placeholder image instead."
    # Create a solid color placeholder image
    echo '<svg xmlns="http://www.w3.org/2000/svg" width="1000" height="600"><rect width="1000" height="600" fill="#101525"/></svg>' > assets/images/arena_background.svg
  }
fi

if [ ! -f "assets/images/battle_background.jpg" ]; then
  echo "Downloading battle background image..."
  curl -o assets/images/battle_background.jpg "https://images.unsplash.com/photo-1520034475321-cbe63696469a?ixlib=rb-1.2.1&auto=format&fit=crop&w=1000&q=80" || {
    echo "Download failed. Creating a placeholder image instead."
    # Create a solid color placeholder image
    echo '<svg xmlns="http://www.w3.org/2000/svg" width="1000" height="600"><rect width="1000" height="600" fill="#251010"/></svg>' > assets/images/battle_background.svg
  }
fi

# Create placeholder animation files
echo "Creating placeholder animation files..."

# Create placeholder Lottie animation files
ANIMATIONS=(
  "fire_effect.json"
  "water_effect.json"
  "electric_effect.json"
  "earth_effect.json"
  "psychic_effect.json"
  "battle_effect.json"
  "battle_intro.json"
  "special_effect.json"
  "critical_effect.json"
  "normal_attack.json"
)

for anim in "${ANIMATIONS[@]}"; do
  if [ ! -f "assets/animations/$anim" ]; then
    echo "Creating placeholder for $anim..."
    # Basic Lottie animation template
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
}' > "assets/animations/$anim"
  fi
done

echo "Updating pubspec.yaml assets..."

# Check if pubspec.yaml exists
if [ ! -f "pubspec.yaml" ]; then
  echo "Error: pubspec.yaml not found!"
  exit 1
fi

# Add assets section if it doesn't exist
if ! grep -q "assets:" pubspec.yaml; then
  # Find the flutter: section and append assets section
  awk '
  /flutter:/ {
    print;
    print "  assets:";
    print "    - assets/images/";
    print "    - assets/animations/";
    inFlutter=1;
    next;
  }
  {print}
  ' pubspec.yaml > pubspec.yaml.new && mv pubspec.yaml.new pubspec.yaml
else
  # Check if the images and animations directories are already included
  if ! grep -q "assets/images/" pubspec.yaml; then
    # Find the assets: section and append the images directory
    awk '
    /assets:/ {
      print;
      print "    - assets/images/";
      inAssets=1;
      next;
    }
    {print}
    ' pubspec.yaml > pubspec.yaml.new && mv pubspec.yaml.new pubspec.yaml
  fi
  
  if ! grep -q "assets/animations/" pubspec.yaml; then
    # Find the assets: section and append the animations directory
    awk '
    /assets:/ {
      print;
      print "    - assets/animations/";
      inAssets=1;
      next;
    }
    {print}
    ' pubspec.yaml > pubspec.yaml.new && mv pubspec.yaml.new pubspec.yaml
  fi
fi

echo "Running flutter pub get to update dependencies..."
flutter pub get

echo "Setup complete! You can now run the Card Arena feature."
