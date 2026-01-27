#!/bin/bash
# Fix gRPC compatibility with Xcode 16
# This script patches the problematic template syntax in gRPC source files

echo "🔧 Patching gRPC source files for Xcode 16 compatibility..."

GRPC_DIR="/Users/mac/development/flutter_projects/pola/ios/Pods/gRPC-Core/src/core/lib/promise/detail"

if [ -d "$GRPC_DIR" ]; then
    # Fix basic_seq.h - template keyword issues
    sed -i '' 's/Traits::template CheckResultAndRunNext/Traits::CheckResultAndRunNext/g' "$GRPC_DIR/basic_seq.h"
    sed -i '' 's/Traits::template CallSeqFactory/Traits::CallSeqFactory/g' "$GRPC_DIR/basic_seq.h"
    
    # Fix other potential files in the same directory
    for file in "$GRPC_DIR"/*.h; do
        if [ -f "$file" ]; then
            sed -i '' 's/Traits::template /Traits::/g' "$file"
        fi
    done
    
    echo "✅ gRPC source files patched successfully"
else
    echo "⚠️ gRPC directory not found, skipping patch"
fi
