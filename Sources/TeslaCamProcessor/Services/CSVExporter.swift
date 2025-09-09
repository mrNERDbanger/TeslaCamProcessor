import Foundation

actor CSVExporter {
    func export(detections: [VehicleDetection], to url: URL) async {
        var csvContent = "Time Start,Time End,Duration,Make,Model,Color,License Plate Number\n"
        
        let sortedDetections = detections.sorted { $0.timeStart < $1.timeStart }
        
        let groupedByPlate = Dictionary(grouping: sortedDetections) { detection in
            detection.licensePlate?.number ?? "Unknown-\(UUID().uuidString.prefix(8))"
        }
        
        for (plate, plateDetections) in groupedByPlate.sorted(by: { $0.key < $1.key }) {
            let mergedDetections = mergeOverlappingDetections(plateDetections)
            
            for detection in mergedDetections {
                let timeStart = formatTime(detection.timeStart)
                let timeEnd = formatTime(detection.timeEnd)
                let duration = formatDuration(detection.duration)
                let make = detection.vehicleInfo?.make ?? "Unknown"
                let model = detection.vehicleInfo?.model ?? "Unknown"
                let color = detection.vehicleInfo?.color ?? "Unknown"
                let plateNumber = plate == "Unknown" ? "" : plate
                
                let row = "\(timeStart),\(timeEnd),\(duration),\(make),\(model),\(color),\(plateNumber)\n"
                csvContent.append(row)
            }
        }
        
        do {
            try csvContent.write(to: url, atomically: true, encoding: .utf8)
            print("CSV exported successfully to: \(url.path)")
        } catch {
            print("Failed to export CSV: \(error)")
        }
    }
    
    private func mergeOverlappingDetections(_ detections: [VehicleDetection]) -> [VehicleDetection] {
        guard !detections.isEmpty else { return [] }
        
        let sorted = detections.sorted { $0.timeStart < $1.timeStart }
        var merged: [VehicleDetection] = []
        var current = sorted[0]
        
        for i in 1..<sorted.count {
            let next = sorted[i]
            
            if next.timeStart <= current.timeEnd + 1.0 {
                current = VehicleDetection(
                    timeStart: current.timeStart,
                    timeEnd: max(current.timeEnd, next.timeEnd),
                    boundingBox: next.boundingBox,
                    confidence: max(current.confidence, next.confidence),
                    licensePlate: next.licensePlate ?? current.licensePlate,
                    vehicleInfo: next.vehicleInfo ?? current.vehicleInfo
                )
            } else {
                merged.append(current)
                current = next
            }
        }
        
        merged.append(current)
        return merged
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        let secs = Int(seconds) % 60
        let millis = Int((seconds.truncatingRemainder(dividingBy: 1)) * 1000)
        
        return String(format: "%02d:%02d:%02d.%03d", hours, minutes, secs, millis)
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        if seconds < 1.0 {
            return String(format: "%.3fs", seconds)
        } else if seconds < 60.0 {
            return String(format: "%.1fs", seconds)
        } else {
            let minutes = Int(seconds) / 60
            let secs = Int(seconds) % 60
            return String(format: "%dm %ds", minutes, secs)
        }
    }
}