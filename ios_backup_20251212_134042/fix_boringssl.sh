#!/bin/bash

# Fix BoringSSL-GRPC compiler flags for Xcode 16+ compatibility
# Remove the -GCC_WARN_INHIBIT_ALL_WARNINGS flag that causes "unsupported option '-G'" error

PODS_PROJECT="Pods/Pods.xcodeproj/project.pbxproj"

if [ -f "$PODS_PROJECT" ]; then
    echo "Fixing BoringSSL-GRPC compiler flags..."
    sed -i '' 's/-GCC_WARN_INHIBIT_ALL_WARNINGS//g' "$PODS_PROJECT"
    echo "Done! Removed -GCC_WARN_INHIBIT_ALL_WARNINGS flags from Pods project."
else
    echo "Error: $PODS_PROJECT not found"
    exit 1
fi
