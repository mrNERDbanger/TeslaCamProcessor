#!/bin/bash

echo "Building TeslaCam Processor..."

cd "$(dirname "$0")"

if ! command -v xcodegen &> /dev/null; then
    echo "Installing XcodeGen..."
    brew install xcodegen
fi

echo "Generating Xcode project..."
xcodegen generate

echo "Building with xcodebuild..."
xcodebuild -project TeslaCamProcessor.xcodeproj \
           -scheme TeslaCamProcessor \
           -configuration Debug \
           -derivedDataPath build \
           clean build

if [ $? -eq 0 ]; then
    echo "Build successful!"
    echo "Running TeslaCam Processor..."
    
    APP_PATH="build/Build/Products/Debug/TeslaCamProcessor.app"
    
    if [ -d "$APP_PATH" ]; then
        open "$APP_PATH"
    else
        echo "App not found at expected path. Trying to run executable directly..."
        EXEC_PATH="build/Build/Products/Debug/TeslaCamProcessor"
        if [ -f "$EXEC_PATH" ]; then
            "$EXEC_PATH"
        else
            echo "Could not find executable"
            exit 1
        fi
    fi
else
    echo "Build failed!"
    exit 1
fi