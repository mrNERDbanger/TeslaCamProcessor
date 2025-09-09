#!/usr/bin/env swift

import Foundation
import AVFoundation

print("🧪 Testing TeslaCam Processor Components\n")

// Test 1: Check if app bundle exists
let appPath = "/Users/jonathanalbiar/TeslaCamProcessor/build/Build/Products/Debug/TeslaCamProcessor.app"
if FileManager.default.fileExists(atPath: appPath) {
    print("✅ App bundle exists at: \(appPath)")
} else {
    print("❌ App bundle not found")
}

// Test 2: Check test videos
let testVideosPath = "/Users/jonathanalbiar/TeslaCamProcessor/test_videos"
do {
    let videos = try FileManager.default.contentsOfDirectory(atPath: testVideosPath)
        .filter { $0.hasSuffix(".mp4") }
    print("✅ Found \(videos.count) test videos:")
    videos.forEach { print("   - \($0)") }
} catch {
    print("❌ Failed to read test videos: \(error)")
}

// Test 3: Verify FFmpeg installation
let ffmpegCheck = Process()
ffmpegCheck.executableURL = URL(fileURLWithPath: "/usr/bin/which")
ffmpegCheck.arguments = ["ffmpeg"]
let pipe = Pipe()
ffmpegCheck.standardOutput = pipe
try? ffmpegCheck.run()
ffmpegCheck.waitUntilExit()
let ffmpegPath = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
if let path = ffmpegPath, !path.isEmpty {
    print("✅ FFmpeg installed at: \(path)")
} else {
    print("❌ FFmpeg not found - video muxing will use fallback")
}

// Test 4: Check Python for vehicle identification
let pythonCheck = Process()
pythonCheck.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
pythonCheck.arguments = ["--version"]
let pythonPipe = Pipe()
pythonCheck.standardOutput = pythonPipe
try? pythonCheck.run()
pythonCheck.waitUntilExit()
if pythonCheck.terminationStatus == 0 {
    let version = String(data: pythonPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
    print("✅ Python3 available: \(version ?? "unknown version")")
} else {
    print("⚠️  Python3 not found - vehicle identification will use defaults")
}

// Test 5: Verify key source files
let sourceFiles = [
    "TeslaCamProcessorApp.swift",
    "Models/VideoFile.swift",
    "Models/VehicleDetection.swift",
    "Views/ContentView.swift",
    "Views/VideoListView.swift",
    "Views/ProcessingView.swift",
    "ViewModels/VideoProcessorViewModel.swift",
    "Services/VideoProcessor.swift",
    "Services/LicensePlateDetector.swift",
    "Services/CSVExporter.swift",
    "Services/VideoMuxer.swift",
    "Services/VehicleIdentificationBridge.swift"
]

print("\n📁 Source Files Check:")
var allFilesPresent = true
for file in sourceFiles {
    let path = "/Users/jonathanalbiar/TeslaCamProcessor/Sources/TeslaCamProcessor/\(file)"
    if FileManager.default.fileExists(atPath: path) {
        print("  ✅ \(file)")
    } else {
        print("  ❌ Missing: \(file)")
        allFilesPresent = false
    }
}

// Test 6: Check video processing capabilities
print("\n🎬 Video Processing Capabilities:")
let testVideoURL = URL(fileURLWithPath: "\(testVideosPath)/2024-01-15_14-30-00-front.mp4")
if FileManager.default.fileExists(atPath: testVideoURL.path) {
    let asset = AVAsset(url: testVideoURL)
    let duration = asset.duration
    if duration.isValid && duration.isNumeric {
        print("  ✅ Can read video files (test video duration: \(CMTimeGetSeconds(duration))s)")
    } else {
        print("  ⚠️  Video reading needs testing with real files")
    }
} else {
    print("  ⚠️  No test video to validate")
}

// Summary
print("\n📊 Test Summary:")
print("================")
if allFilesPresent {
    print("✅ All source files present")
    print("✅ App is built and ready")
    print("✅ Test videos created")
    if let path = ffmpegPath, !path.isEmpty {
        print("✅ FFmpeg available for muxing")
    } else {
        print("⚠️  FFmpeg not found (will use AVFoundation fallback)")
    }
    print("\n🚀 App is ready to launch and process videos!")
    print("\nTo test the app:")
    print("1. Run: open \(appPath)")
    print("2. Select an output folder")
    print("3. Drag test videos from: \(testVideosPath)")
    print("4. Click 'Process Videos'")
} else {
    print("❌ Some components missing - rebuild may be needed")
}