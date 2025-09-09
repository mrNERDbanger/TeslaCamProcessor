#!/usr/bin/env swift

import Foundation

// Test CSV Export functionality
print("🧪 Testing CSV Export Functionality\n")

// Create test detection data
struct TestDetection {
    let timeStart: Double
    let timeEnd: Double
    let make: String
    let model: String
    let color: String
    let licensePlate: String
    
    var duration: Double { timeEnd - timeStart }
}

let testDetections = [
    TestDetection(timeStart: 1.5, timeEnd: 4.2, make: "Tesla", model: "Model 3", color: "White", licensePlate: "ABC 1234"),
    TestDetection(timeStart: 5.1, timeEnd: 8.7, make: "Toyota", model: "Camry", color: "Silver", licensePlate: "XYZ 5678"),
    TestDetection(timeStart: 2.3, timeEnd: 6.9, make: "Honda", model: "Accord", color: "Black", licensePlate: "DEF 9012")
]

// Format time
func formatTime(_ seconds: Double) -> String {
    let hours = Int(seconds) / 3600
    let minutes = (Int(seconds) % 3600) / 60
    let secs = Int(seconds) % 60
    let millis = Int((seconds.truncatingRemainder(dividingBy: 1)) * 1000)
    return String(format: "%02d:%02d:%02d.%03d", hours, minutes, secs, millis)
}

// Format duration
func formatDuration(_ seconds: Double) -> String {
    if seconds < 60.0 {
        return String(format: "%.1fs", seconds)
    } else {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%dm %ds", minutes, secs)
    }
}

// Create CSV content
var csvContent = "Time Start,Time End,Duration,Make,Model,Color,License Plate Number\n"

for detection in testDetections {
    let row = "\(formatTime(detection.timeStart)),\(formatTime(detection.timeEnd)),\(formatDuration(detection.duration)),\(detection.make),\(detection.model),\(detection.color),\(detection.licensePlate)\n"
    csvContent.append(row)
}

// Write test CSV
let testCSVPath = "/Users/jonathanalbiar/TeslaCamProcessor/test_output.csv"
do {
    try csvContent.write(toFile: testCSVPath, atomically: true, encoding: .utf8)
    print("✅ CSV Export Test Passed")
    print("📄 Test CSV created at: \(testCSVPath)")
    print("\nCSV Content Preview:")
    print("--------------------")
    print(csvContent)
} catch {
    print("❌ CSV Export Test Failed: \(error)")
}

// Verify CSV is valid
if let csvData = try? String(contentsOfFile: testCSVPath) {
    let lines = csvData.components(separatedBy: .newlines).filter { !$0.isEmpty }
    print("✅ CSV Validation: \(lines.count) lines (\(lines.count - 1) detections + header)")
    
    // Check header
    let expectedHeader = "Time Start,Time End,Duration,Make,Model,Color,License Plate Number"
    if lines.first == expectedHeader {
        print("✅ CSV header format correct")
    } else {
        print("❌ CSV header format incorrect")
    }
} else {
    print("❌ Failed to read CSV file")
}