#!/bin/bash
# Build script for Prompts Framework MCP Server

set -e

echo "======================================"
echo "Prompts Framework MCP Server - Build"
echo "======================================"
echo ""

# Check Dart installation
if ! command -v dart &> /dev/null; then
    echo "❌ Error: Dart SDK not found"
    echo "Please install Dart: https://dart.dev/get-dart"
    exit 1
fi

echo "✓ Dart SDK found: $(dart --version 2>&1)"
echo ""

# Install dependencies
echo "📦 Installing dependencies..."
dart pub get
echo ""

# Run tests
echo "🧪 Running tests..."
dart test
echo ""

# Run analyzer
echo "🔍 Running analyzer..."
dart analyze
echo ""

# Format code
echo "🎨 Formatting code..."
dart format .
echo ""

# Create build directory
mkdir -p build

# Compile to native binary
echo "🔨 Compiling to native binary..."
dart compile exe bin/prompts_framework_mcp_server.dart -o build/server
echo ""

# Check binary
if [ -f "build/server" ]; then
    echo "✅ Build successful!"
    echo ""
    echo "Binary location: $(pwd)/build/server"
    echo "Binary size: $(ls -lh build/server | awk '{print $5}')"
    echo ""
    echo "To run the server:"
    echo "  ./build/server"
    echo ""
    echo "To build Docker image:"
    echo "  docker build -t prompts-framework-mcp:latest ."
else
    echo "❌ Build failed: Binary not found"
    exit 1
fi
