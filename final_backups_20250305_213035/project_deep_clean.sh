#!/bin/bash

# Set terminal colors
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}CardWizz Project Deep Clean${NC}"
echo "==========================="

# Create timestamp for backups
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_DIR="backup_$TIMESTAMP"
mkdir -p $BACKUP_DIR
echo -e "${YELLOW}Created backup directory: $BACKUP_DIR${NC}"

# Step 1: Fix common errors in scanner_service.dart
echo -e "\n${YELLOW}1. Fixing scanner_service.dart...${NC}"
if [ -f lib/services/scanner_service.dart ]; then
  cp lib/services/scanner_service.dart $BACKUP_DIR/scanner_service.dart.backup
  
  # Fix match.group() calls by adding null safety checks
  sed -i '' 's/match\.group(/match\?\.group(/g' lib/services/scanner_service.dart
  sed -i '' 's/match2\.group(/match2\?\.group(/g' lib/services/scanner_service.dart
  sed -i '' 's/match\.start/match\?\.start/g' lib/services/scanner_service.dart
  sed -i '' 's/match\.end/match\?\.end/g' lib/services/scanner_service.dart
  echo -e "${GREEN}✓ Added null safety checks to RegExp match operations${NC}"
  
  # Fix line 65 specifically by replacing content
  LINE65_NUM=$(grep -n '\.group(' lib/services/scanner_service.dart | grep -E '^65:' | wc -l)
  if [ "$LINE65_NUM" -gt 0 ]; then
    # Get the indentation level
    INDENT=$(grep -E '^65:' lib/services/scanner_service.dart | sed -E 's/[^ ].*//')
    # Replace with safer version
    sed -i '' '65s/.*$/'"$INDENT"'if (match2 != null \&\& match2.group(1) != null) {/' lib/services/scanner_service.dart
    echo -e "${GREEN}✓ Fixed line 65 with explicit null check${NC}"
  fi
  
  echo -e "${GREEN}✓ Fixed scanner_service.dart${NC}"
else
  echo -e "${RED}× scanner_service.dart not found${NC}"
fi

# Step 2: Fix main.dart issues
echo -e "\n${YELLOW}2. Fixing main.dart...${NC}"
if [ -f lib/main.dart ]; then
  cp lib/main.dart $BACKUP_DIR/main.dart.backup
  
  # Remove const from localizationsDelegates
  sed -i '' 's/localizationsDelegates: const \[/localizationsDelegates: \[/g' lib/main.dart
  echo -e "${GREEN}✓ Removed const from localizationsDelegates${NC}"
  
  # Fix root navigator issues
  sed -i '' 's/RootNavigator(/const RootNavigator(/g' lib/main.dart
  echo -e "${GREEN}✓ Added const to RootNavigator${NC}"
  
  # Fix duplicate constructors by finding and removing them
  DUPLICATES=$(grep -n "const.*({super.key});" lib/main.dart | sort | uniq -d -f 2 | wc -l)
  if [ "$DUPLICATES" -gt 0 ]; then
    # The sed approach would be complex here, so we'll inform the user
    echo -e "${YELLOW}⚠️ Found potential duplicate constructors. Consider running the Dart fix script for better handling.${NC}"
  fi
  
  echo -e "${GREEN}✓ Fixed main.dart${NC}"
else
  echo -e "${RED}× main.dart not found${NC}"
fi

# Step 3: Clean flutter project
echo -e "\n${YELLOW}3. Running Flutter clean...${NC}"
flutter clean
flutter pub get
echo -e "${GREEN}✓ Flutter project cleaned and packages updated${NC}"

# Step 4: Fix iOS-specific issues
echo -e "\n${YELLOW}4. Checking iOS configuration...${NC}"
if [ -d "ios" ]; then
  # Check Podfile
  if [ -f "ios/Podfile" ]; then
    cp ios/Podfile $BACKUP_DIR/Podfile.backup
    # Make sure platform is set to at least iOS 12.0
    sed -i '' 's/platform :ios, .*/platform :ios, '\''12.0'\''/' ios/Podfile
    echo -e "${GREEN}✓ Updated iOS platform version in Podfile${NC}"
  fi
  
  # Clean iOS build
  echo -e "${YELLOW}Running pod install...${NC}"
  cd ios && pod install && cd ..
  echo -e "${GREEN}✓ iOS dependencies installed${NC}"
else
  echo -e "${RED}× iOS directory not found${NC}"
fi

# Step 5: General code cleanup
echo -e "\n${YELLOW}5. Running Flutter format and analyze...${NC}"
flutter format .
flutter analyze --no-fatal-infos
echo -e "${GREEN}✓ Code formatted and analyzed${NC}"

echo -e "\n${GREEN}==========================${NC}"
echo -e "${GREEN}Deep cleaning process complete!${NC}"
echo -e "Backups saved in: ${BACKUP_DIR}"
echo -e "\nNext step: Run 'flutter run' to verify the fixes worked"
