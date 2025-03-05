#!/bin/bash

# Make the script executable
chmod +x "$0"

# Set colors for better readability
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}CardWizz Performance Toolkit Runner${NC}"
echo "==============================="
echo ""

# Fix pubspec dependencies first
echo -e "${YELLOW}Fixing dependencies...${NC}"
dart tools/fix_pubspec.dart

if [ $? -ne 0 ]; then
  echo -e "${RED}Failed to fix dependencies. Please fix pubspec.yaml manually${NC}"
  echo "Make sure 'path' and 'yaml' packages are in dev_dependencies."
  exit 1
fi

# Function to run a tool
run_tool() {
  local tool_name=$1
  local file_path="tools/$tool_name.dart"
  
  if [ ! -f "$file_path" ]; then
    echo -e "${RED}Error: Tool not found at $file_path${NC}"
    return 1
  fi
  
  echo ""
  echo -e "${GREEN}=== Running $tool_name ===${NC}"
  echo ""
  
  dart "$file_path"
  
  echo ""
  echo -e "${YELLOW}$tool_name completed.${NC}"
  echo "----------------------------------------"
}

# Show menu
echo "Which tool would you like to run?"
echo "1. Widget Performance Analysis (check_widget_performance)"
echo "2. Image Cache Optimization (update_image_cache)"
echo "3. Asset Usage Analysis (optimize_assets)"
echo "4. Memory Usage Analysis (memory_usage_analyzer)"
echo "5. Add Const Constructors (add_const_constructor)"
echo "6. ListView Optimization Analysis (list_view_optimizer)"
echo "7. General Performance Analysis (performance_cleanup)"
echo "8. Run all tools (except add_const_constructor)"
echo ""
read -p "Enter option (1-8): " option

case $option in
  1) run_tool "check_widget_performance" ;;
  2) run_tool "update_image_cache" ;;
  3) run_tool "optimize_assets" ;;
  4) run_tool "memory_usage_analyzer" ;;
  5) run_tool "add_const_constructor" ;;
  6) run_tool "list_view_optimizer" ;;
  7) run_tool "performance_cleanup" ;;
  8)
    run_tool "check_widget_performance"
    run_tool "update_image_cache"
    run_tool "optimize_assets"
    run_tool "memory_usage_analyzer" 
    run_tool "list_view_optimizer"
    run_tool "performance_cleanup"
    echo -e "${YELLOW}Note: The 'add_const_constructor' tool was skipped because it modifies your code directly.${NC}"
    echo -e "${YELLOW}Run it separately if you'd like to add const constructors automatically.${NC}"
    ;;
  *)
    echo -e "${RED}Invalid option. Exiting.${NC}"
    exit 1
    ;;
esac

echo -e "${GREEN}All operations completed.${NC}"
echo "Review reports in your project directory."
