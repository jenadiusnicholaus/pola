#!/bin/bash

# Script to fix Xcode 16+ BoringSSL-GRPC build issues
# Run this after pod install and before flutter build

echo "🔧 Fixing Xcode 16+ BoringSSL-GRPC compatibility issues..."

PODS_DIR="./Pods"

# Find and patch all BoringSSL source files to remove -G flag usage
find "$PODS_DIR" -name "*.c" -o -name "*.cc" -o -name "*.cpp" | grep -i "boringssl\|grpc" | while read file; do
    if grep -q "\-G" "$file" 2>/dev/null; then
        echo "Patching: $file"
        sed -i '' 's/-G[^ ]*//g' "$file"
    fi
done

# Patch build configuration files
find "$PODS_DIR" -name "*.xcconfig" | grep -i "boringssl\|grpc" | while read file; do
    if grep -q "\-G" "$file" 2>/dev/null; then
        echo "Patching config: $file"
        sed -i '' 's/-G[^ ]*//g' "$file"
    fi
done

# Set environment variables to override compiler flags
export OTHER_CFLAGS=""
export OTHER_CPLUSPLUSFLAGS=""
export GCC_OPTIMIZATION_LEVEL="0"

echo "✅ Xcode 16+ compatibility fixes applied"