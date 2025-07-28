#!/bin/bash

# Build script for V-lang application
APP_NAME="tetris_game"
VERSION="1.0.0"

echo "Building $APP_NAME v$VERSION for multiple platforms..."

# Create build directory
mkdir -p builds

# Build for different platforms
echo "Building for Linux (x64)..."
v -prod -o builds/${APP_NAME}_linux_x64 .

echo "Building for Windows (x64)..."
v -os windows -prod -o builds/${APP_NAME}_windows_x64.exe .

echo "Building for macOS (x64)..."
if command -v x86_64-apple-darwin20.4-clang >/dev/null 2>&1; then
    VCROSS_COMPILER_NAME=x86_64-apple-darwin20.4-clang v -os macos -prod -o builds/${APP_NAME}_macos_x64 .
else
    echo "Warning: macOS cross-compiler not found. Skipping macOS x64 build."
    echo "Install osxcross or build on macOS directly."
fi

echo "Building for macOS (ARM64)..."
if command -v aarch64-apple-darwin20.4-clang >/dev/null 2>&1; then
    VCROSS_COMPILER_NAME=aarch64-apple-darwin20.4-clang v -os macos -arch arm64 -prod -o builds/${APP_NAME}_macos_arm64 .
else
    echo "Warning: macOS ARM64 cross-compiler not found. Skipping macOS ARM64 build."
    echo "Install osxcross or build on macOS directly."
fi

# Create release packages
echo "Creating release packages..."

# Linux package
cd builds
tar -czf ${APP_NAME}_v${VERSION}_linux_x64.tar.gz ${APP_NAME}_linux_x64
zip ${APP_NAME}_v${VERSION}_linux_x64.zip ${APP_NAME}_linux_x64

# Windows package  
zip ${APP_NAME}_v${VERSION}_windows_x64.zip ${APP_NAME}_windows_x64.exe

# macOS packages (only if files exist)
if [ -f "${APP_NAME}_macos_x64" ]; then
    tar -czf ${APP_NAME}_v${VERSION}_macos_x64.tar.gz ${APP_NAME}_macos_x64
else 
    echo "Skipping macOS x64 package (binary not found)"
fi

if [ -f "${APP_NAME}_macos_arm64" ]; then
    tar -czf ${APP_NAME}_v${VERSION}_macos_arm64.tar.gz ${APP_NAME}_macos_arm64
else
    echo "Skipping macOS ARM64 package (binary not found)"  
fi

cd ..

echo "Build complete! Check the builds/ directory."
echo "Release packages created:"
ls -la builds/*.tar.gz builds/*.zip