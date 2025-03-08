#!/bin/bash

echo "===== CardWizz Cleanup Tools ====="
echo "Running tools to help clean up the project before release..."
echo ""

echo "1. Running Code Cleaner..."
dart run lib/utils/code_cleaner.dart

echo ""
echo "2. Finding Unused Imports..."
dart run lib/tools/find_unused_imports.dart

echo ""
echo "3. Displaying Cleanup Checklist..."
dart run lib/utils/cleanup_checklist.dart

echo ""
echo "Done! Review the output above and make necessary changes."
