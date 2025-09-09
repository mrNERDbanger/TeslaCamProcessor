# TeslaCam Processor

A macOS application for processing TeslaCam video files with advanced vehicle detection, license plate recognition, and video composition capabilities.

## Features

- **Drag & Drop Interface**: Simply drag your TeslaCam video files into the app
- **Multi-Camera Support**: Processes front, back, left_repeater, and right_repeater camera angles
- **Vehicle Detection**: Uses Vision framework and Core ML to detect vehicles in video frames
- **License Plate Recognition**: OCR technology to read and track license plates
- **Vehicle Identification**: Identifies make, model, and color of detected vehicles
- **CSV Export**: Generates detailed CSV reports with:
  - Time Start/End
  - Duration
  - Vehicle Make/Model/Color
  - License Plate Numbers
- **2x2 Video Muxing**: Creates composite videos showing all 4 camera angles simultaneously
- **Multi-threaded Processing**: Optimized for M2 Mac with parallel processing
- **iCloud Integration**: Saves processed files to iCloud for access anywhere

## Requirements

- macOS 13.0 or later
- M1/M2 Mac recommended for optimal performance
- FFmpeg installed (for video muxing)

## Installation

### Install FFmpeg (if not already installed)
```bash
brew install ffmpeg
```

### Build and Run

1. Clone or download the project
2. Navigate to the project directory
3. Run the build script:
```bash
./build_and_run.sh
```

Or build manually with Xcode:
```bash
xcodegen generate
xcodebuild -project TeslaCamProcessor.xcodeproj -scheme TeslaCamProcessor -configuration Release build
```

## Usage

1. **Launch the App**: Double-click the TeslaCam Processor app

2. **Select Output Folder**: Click "Select Output Folder" to choose where processed files will be saved

3. **Add Videos**: Drag and drop your TeslaCam video files into the drop zone
   - Files should be named with camera angle identifiers (front, back, left_repeater, right_repeater)
   - Example: `2024-01-15_10-30-45-front.mp4`

4. **Process Videos**: Click "Process Videos" to start the analysis
   - The app will detect vehicles and license plates
   - Track vehicle appearances across frames
   - Generate CSV reports
   - Create muxed videos for each unique license plate

5. **View Results**: Check your output folder for:
   - `vehicle_detections.csv` - Complete detection report
   - Individual muxed videos named as: `Make - Model - LicensePlate.mp4`

## Output Format

### CSV Columns
- **Time Start**: When the vehicle first appears (HH:MM:SS.mmm)
- **Time End**: When the vehicle last appears (HH:MM:SS.mmm)
- **Duration**: Total time vehicle was visible
- **Make**: Vehicle manufacturer
- **Model**: Vehicle model
- **Color**: Vehicle color
- **License Plate Number**: Detected plate number

### Muxed Videos
- 2x2 grid layout:
  - Top Left: Front camera
  - Top Right: Back camera
  - Bottom Left: Left repeater camera
  - Bottom Right: Right repeater camera
- H.264 encoding for compatibility
- Named by vehicle details for easy identification

## Performance Tips

- Process videos in batches by date for better organization
- The app uses all available CPU cores for parallel processing
- First run may be slower as the system caches ML models
- Ensure sufficient disk space for processed videos

## Troubleshooting

### App Won't Launch
- Ensure you're running macOS 13.0 or later
- Check that the app has necessary permissions in System Settings > Privacy & Security

### FFmpeg Not Found
- Install FFmpeg using: `brew install ffmpeg`
- The app will fall back to AVFoundation if FFmpeg is unavailable

### Poor Detection Results
- Ensure video quality is sufficient (1080p recommended)
- Clean camera lenses for better clarity
- Process during good lighting conditions for best results

## Privacy & Security

- All processing happens locally on your Mac
- No data is sent to external servers
- Videos and results are saved only to your specified locations

## License

This project is for personal use. Please respect privacy laws when processing videos that may contain other vehicles and license plates.

## Support

For issues or questions, please check the project repository or create an issue on GitHub.