#!/bin/bash

# Optimized script to find potentially unused files across the codebase
# Usage: ./find_unused_files.sh

echo "Searching for potentially unused files in CardWizz codebase..."

# Search in the current directory (root of project)
PROJECT_ROOT="."

# Get all source code files with more aggressive exclusions
echo "Finding relevant source files..."
SOURCE_FILES=$(find $PROJECT_ROOT \
  -type f \
  \( -name "*.dart" \) \
  -not -path "*/\.*" \
  -not -path "*/build/*" \
  -not -path "*/generated*/*" \
  -not -path "*/ios/Pods/*" \
  -not -path "*/android/.gradle/*" \
  -not -path "*/.dart_tool/*" \
  -not -path "*/test/*" \
  -not -path "*/integration_test/*" \
  | sort)

# Create a temp file to store all source file contents for faster searching
TEMP_DIR=$(mktemp -d)
ALL_IMPORTS_FILE="$TEMP_DIR/all_imports.txt"

echo "Creating search index for better performance..."
# Extract all imports and references to a single file for faster searching
find $PROJECT_ROOT \
  -type f \
  -name "*.dart" \
  -not -path "*/\.*" \
  -not -path "*/build/*" \
  -not -path "*/generated*/*" \
  -not -path "*/ios/Pods/*" \
  -not -path "*/android/.gradle/*" \
  -not -path "*/.dart_tool/*" \
  -exec grep -l "import\|part\|export" {} \; | \
  xargs cat > "$ALL_IMPORTS_FILE"

# Array to store potentially unused files
UNUSED_FILES=()
TOTAL_FILES=$(echo "$SOURCE_FILES" | wc -l | sed 's/^[[:space:]]*//g')
CURRENT=0

echo "Analyzing $TOTAL_FILES Dart files for references..."

# For each file, check if it's imported or referenced
for FILE in $SOURCE_FILES; do
    CURRENT=$((CURRENT+1))
    
    # More frequent progress updates
    if [ $((CURRENT % 10)) -eq 0 ] || [ $CURRENT -eq $TOTAL_FILES ]; then
        PERCENT=$((CURRENT * 100 / TOTAL_FILES))
        echo -ne "Progress: $CURRENT / $TOTAL_FILES files ($PERCENT%)\r"
    fi
    
    # Get basename without path and extension for searching
    FILENAME=$(basename "$FILE")
    BASENAME="${FILENAME%.*}"
    
    # Skip entry points and config files
    if [[ "$BASENAME" == "main" ]] || 
       [[ "$BASENAME" == "app" ]] || 
       [[ "$BASENAME" == *"config"* ]] || 
       [[ "$BASENAME" == "generated"* ]] || 
       [[ "$FILENAME" == "pubspec.yaml" ]]; then
        continue
    fi
    
    # Get path formats for checking imports
    RELATIVE_PATH=${FILE#./}
    IMPORT_PATH=${RELATIVE_PATH#lib/}
    PACKAGE_PATH="package:${RELATIVE_PATH#lib/}"
    
    # Check if this file is referenced anywhere using the pre-built index
    if grep -q "$IMPORT_PATH\|$BASENAME\|$PACKAGE_PATH" "$ALL_IMPORTS_FILE"; then
        continue
    fi
    
    # If we get here, no references were found
    UNUSED_FILES+=("$FILE")
done

# Print newline to clear progress line
echo ""
echo "Analysis complete!"

# Print results
echo ""
echo "=== Potentially Unused Files ==="
if [ ${#UNUSED_FILES[@]} -eq 0 ]; then
    echo "No unused files found."
else
    echo "The following ${#UNUSED_FILES[@]} files may be unused (manual verification recommended):"
    for FILE in "${UNUSED_FILES[@]}"; do
        echo " - $FILE"
    done
    
    echo ""
    echo "Note: These files might still be used via dynamic loading, reflection,"
    echo "or referenced in ways not detected by this script."
    echo "Always verify manually before deleting any files."
fi

# Simplified duplicated file check
echo ""
echo "=== Checking for Known Duplicated Files ==="

# Check specific known duplicates to avoid heavy computation
if [ -f "lib/root_navigator.dart" ] && [ -f "lib/screens/root_navigator.dart" ]; then
    echo "Potential duplication found:"
    echo " - lib/root_navigator.dart"
    echo " - lib/screens/root_navigator.dart"
    
    # Only calculate differences if both files exist and aren't too large
    if [ $(stat -f%z "lib/root_navigator.dart") -lt 1000000 ] && [ $(stat -f%z "lib/screens/root_navigator.dart") -lt 1000000 ]; then
        SIMILARITY=$(diff -y --suppress-common-lines "lib/root_navigator.dart" "lib/screens/root_navigator.dart" | wc -l)
        echo "   Differences: $SIMILARITY lines"
    fi
    echo ""
fi

if [ -f "lib/services/mtg_api_service.dart" ] && [ -f "lib/services/tcgdex_api_service.dart" ]; then
    echo "Potential related services:"
    echo " - lib/services/mtg_api_service.dart"
    echo " - lib/services/tcgdex_api_service.dart"
    echo ""
fi

# Check for fix scripts
echo ""
echo "=== Checking for iOS Fix Scripts ==="
IOS_FIX_SCRIPTS=$(find ./ios -name "fix_*.sh" 2>/dev/null)

if [ -n "$IOS_FIX_SCRIPTS" ]; then
    echo "Potentially obsolete iOS fix scripts:"
    echo "$IOS_FIX_SCRIPTS" | sed 's/^/ - /'
    echo ""
    echo "These scripts are typically used once during setup or troubleshooting."
    echo "If your app is working correctly, they might be safely removed."
fi

# Cleanup
rm -rf "$TEMP_DIR"

echo ""
echo "=== Complete ==="
echo "Remember to back up your code before removing any files!"
