import Foundation

class VehicleIdentificationBridge {
    private let pythonScriptPath = "\(NSHomeDirectory())/TeslaCamProcessor/Scripts/vehicle_identifier.py"
    
    func identifyVehicle(videoPath: URL, timestamp: TimeInterval, boundingBox: CGRect) async -> VehicleInfo? {
        let requestData: [String: Any] = [
            "video_path": videoPath.path,
            "timestamp": timestamp,
            "bbox": [
                boundingBox.minX,
                boundingBox.minY,
                boundingBox.width,
                boundingBox.height
            ]
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestData),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            print("Failed to create JSON request")
            return nil
        }
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
        process.arguments = [pythonScriptPath, jsonString]
        
        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = Pipe()
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            guard let output = String(data: outputData, encoding: .utf8),
                  let responseData = output.data(using: .utf8),
                  let response = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any] else {
                print("Failed to parse Python script output")
                return nil
            }
            
            return VehicleInfo(
                make: response["make"] as? String,
                model: response["model"] as? String,
                color: response["color"] as? String,
                year: response["year"] as? String,
                confidence: Float(response["confidence"] as? Double ?? 0.0)
            )
        } catch {
            print("Failed to run Python vehicle identification: \(error)")
            return nil
        }
    }
}