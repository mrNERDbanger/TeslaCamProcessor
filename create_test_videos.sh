#!/bin/bash

echo "Creating test TeslaCam video files..."

# Create test directory
TEST_DIR="/Users/jonathanalbiar/TeslaCamProcessor/test_videos"
mkdir -p "$TEST_DIR"

# Function to create a test video with text overlay
create_test_video() {
    local angle=$1
    local filename=$2
    local color=$3
    
    ffmpeg -f lavfi -i color=c=$color:s=1280x960:d=10 \
           -vf "drawtext=fontfile=/System/Library/Fonts/Helvetica.ttc:text='$angle Camera\nTest Video\n$(date +%Y-%m-%d_%H-%M-%S)':fontcolor=white:fontsize=48:x=(w-text_w)/2:y=(h-text_h)/2" \
           -c:v libx264 -preset ultrafast -crf 23 \
           "$TEST_DIR/$filename" -y 2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo "✓ Created $filename"
    else
        echo "✗ Failed to create $filename"
    fi
}

# Create test videos for each camera angle
TIMESTAMP="2024-01-15_14-30-00"

create_test_video "FRONT" "${TIMESTAMP}-front.mp4" "blue"
create_test_video "BACK" "${TIMESTAMP}-back.mp4" "green"
create_test_video "LEFT" "${TIMESTAMP}-left_repeater.mp4" "red"
create_test_video "RIGHT" "${TIMESTAMP}-right_repeater.mp4" "purple"

echo ""
echo "Test videos created in: $TEST_DIR"
echo ""
echo "Files created:"
ls -la "$TEST_DIR"/*.mp4 2>/dev/null | awk '{print "  - "$9}'
echo ""
echo "You can now drag these files into the TeslaCam Processor app for testing."