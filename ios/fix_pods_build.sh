#!/bin/bash
# Fix BoringSSL-GRPC compiler flags for Xcode 16+ compatibility
PROJECT_FILE="$SRCROOT/Pods/Pods.xcodeproj/project.pbxproj"
if [ -f "$PROJECT_FILE" ]; then
    sed -i '' 's/-GCC_WARN_INHIBIT_ALL_WARNINGS//g' "$PROJECT_FILE"
    echo "Fixed BoringSSL-GRPC compiler flags"
fi
