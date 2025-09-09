# TeslaCam Processor - Complete Usage Guide

## Quick Start

1. **Launch the App**
   - Double-click `/Users/jonathanalbiar/launch_teslacam.command`
   - Or open the app directly from `/Users/jonathanalbiar/TeslaCamProcessor/build/Build/Products/Debug/TeslaCamProcessor.app`

2. **Prepare Your Videos**
   - Ensure your TeslaCam videos are named correctly with camera angles:
     - `*front*` for front camera
     - `*back*` for rear camera
     - `*left_repeater*` for left side camera
     - `*right_repeater*` for right side camera

3. **Process Videos**
   - Click "Select Output Folder" to choose where to save results
   - Drag and drop your video files into the app
   - Click "Process Videos"
   - Wait for processing to complete

## Features in Detail

### Vehicle Detection
- Automatically detects all vehicles in frame
- Tracks vehicles across multiple frames
- Merges detections of the same vehicle

### License Plate Recognition
- OCR technology reads license plates
- Supports US state formats
- Tracks plate appearances across time

### Vehicle Identification
- Identifies make, model, and color
- Uses machine learning for accuracy
- Falls back to "Unknown" if uncertain

### Output Files

#### CSV Report (`vehicle_detections.csv`)
Contains detailed information for each vehicle:
- Time stamps (start, end, duration)
- Vehicle details (make, model, color)
- License plate numbers
- Sorted by detection time

#### Muxed Videos
For each unique license plate detected:
- Filename: `Make - Model - LicensePlate.mp4`
- 2x2 grid showing all 4 camera angles
- H.264 encoded for compatibility
- Synchronized timestamps

## Advanced Features

### Multi-threaded Processing
- Utilizes all CPU cores on your M2 Mac
- Processes multiple videos in parallel
- Progress tracking for each video

### iCloud Integration
- Results automatically saved to your selected folder
- Access processed files from any device
- No cloud processing - all work done locally

## Tips for Best Results

1. **Video Quality**
   - Higher resolution = better detection
   - Clean camera lenses before recording
   - Good lighting improves accuracy

2. **File Organization**
   - Group videos by date/incident
   - Keep all 4 camera angles together
   - Use consistent naming conventions

3. **Performance**
   - Close other apps for faster processing
   - Ensure sufficient disk space (2x video size)
   - First run may be slower (model initialization)

## Troubleshooting

### "FFmpeg not found"
```bash
brew install ffmpeg
```

### Poor detection results
- Check video quality
- Ensure proper lighting in videos
- Verify camera angles are correct

### App crashes or freezes
- Check Console.app for error messages
- Ensure macOS 13.0+ is installed
- Verify sufficient RAM available

### Python script errors
```bash
pip3 install opencv-python numpy pillow
```

## Privacy Notice

- All processing is done locally on your Mac
- No data is sent to external servers
- Videos remain in your control
- License plate data should be handled responsibly

## Keyboard Shortcuts

- `Cmd+O`: Select output folder
- `Cmd+R`: Process videos
- `Cmd+K`: Clear all videos
- `Cmd+Q`: Quit application

## Command Line Usage

For automation or batch processing:

```bash
# Build the app
cd /Users/jonathanalbiar/TeslaCamProcessor
xcodebuild -project TeslaCamProcessor.xcodeproj \
           -scheme TeslaCamProcessor \
           -configuration Release build

# Run with specific videos (future feature)
# ./TeslaCamProcessor --input /path/to/videos --output /path/to/results
```

## Support

For issues or questions:
1. Check this usage guide
2. Review the README.md file
3. Check system requirements (macOS 13.0+, M1/M2 Mac)

## Version Information

- Version: 1.0.0
- Build Date: 2024
- Requires: macOS 13.0 or later
- Optimized for: Apple Silicon (M1/M2)

---

Enjoy using TeslaCam Processor to analyze your dashcam footage!