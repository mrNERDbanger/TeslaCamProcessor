import Foundation
import AVFoundation
import Vision
import CoreImage
import CoreML

actor VideoProcessor {
    private let vehicleDetector: VehicleDetector
    private let licensePlateDetector: LicensePlateDetector
    private let vehicleIdentifier: VehicleIdentificationBridge
    
    init() {
        self.vehicleDetector = VehicleDetector()
        self.licensePlateDetector = LicensePlateDetector()
        self.vehicleIdentifier = VehicleIdentificationBridge()
    }
    
    func processVideo(url: URL) async -> [VehicleDetection] {
        var detections: [VehicleDetection] = []
        
        let asset = AVAsset(url: url)
        guard let videoTrack = try? await asset.loadTracks(withMediaType: .video).first else {
            print("Failed to load video track from \(url.lastPathComponent)")
            return []
        }
        
        let duration = try? await asset.load(.duration)
        let frameRate = try? await videoTrack.load(.nominalFrameRate)
        let frameCount = Int((duration?.seconds ?? 0) * Double(frameRate ?? 30))
        
        let reader = try? AVAssetReader(asset: asset)
        let outputSettings: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        
        let output = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: outputSettings)
        reader?.add(output)
        reader?.startReading()
        
        var frameIndex = 0
        let processEveryNFrames = max(1, Int(frameRate ?? 30) / 2)
        
        var activeVehicles: [UUID: VehicleDetection] = [:]
        
        while let sampleBuffer = output.copyNextSampleBuffer() {
            if frameIndex % processEveryNFrames == 0 {
                guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { continue }
                
                let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer).seconds
                
                let vehicleResults = await vehicleDetector.detect(in: pixelBuffer)
                
                for result in vehicleResults {
                    let plateResult = await licensePlateDetector.detect(
                        in: pixelBuffer,
                        region: result.boundingBox
                    )
                    
                    let vehicleInfo = await identifyVehicle(
                        in: pixelBuffer,
                        boundingBox: result.boundingBox,
                        videoURL: url,
                        timestamp: timestamp
                    )
                    
                    let detection = VehicleDetection(
                        timeStart: timestamp,
                        timeEnd: timestamp,
                        boundingBox: result.boundingBox,
                        confidence: result.confidence,
                        licensePlate: plateResult,
                        vehicleInfo: vehicleInfo
                    )
                    
                    if let plate = plateResult {
                        let existingDetection = activeVehicles.values.first { 
                            $0.licensePlate?.number == plate.number 
                        }
                        
                        if let existing = existingDetection {
                            activeVehicles[existing.id] = VehicleDetection(
                                timeStart: existing.timeStart,
                                timeEnd: timestamp,
                                boundingBox: result.boundingBox,
                                confidence: max(existing.confidence, result.confidence),
                                licensePlate: LicensePlate(
                                    number: plate.number,
                                    confidence: max(existing.licensePlate?.confidence ?? 0, plate.confidence),
                                    boundingBox: plate.boundingBox,
                                    firstAppearance: existing.licensePlate?.firstAppearance ?? timestamp,
                                    lastAppearance: timestamp
                                ),
                                vehicleInfo: vehicleInfo ?? existing.vehicleInfo
                            )
                        } else {
                            activeVehicles[detection.id] = detection
                        }
                    } else {
                        let matchedVehicle = findMatchingVehicle(
                            boundingBox: result.boundingBox,
                            in: Array(activeVehicles.values)
                        )
                        
                        if let matched = matchedVehicle {
                            activeVehicles[matched.id] = VehicleDetection(
                                timeStart: matched.timeStart,
                                timeEnd: timestamp,
                                boundingBox: result.boundingBox,
                                confidence: max(matched.confidence, result.confidence),
                                licensePlate: matched.licensePlate,
                                vehicleInfo: vehicleInfo ?? matched.vehicleInfo
                            )
                        } else {
                            activeVehicles[detection.id] = detection
                        }
                    }
                }
                
                for (id, vehicle) in activeVehicles {
                    if timestamp - vehicle.timeEnd > 2.0 {
                        detections.append(vehicle)
                        activeVehicles.removeValue(forKey: id)
                    }
                }
            }
            
            frameIndex += 1
        }
        
        detections.append(contentsOf: activeVehicles.values)
        
        reader?.cancelReading()
        
        return detections
    }
    
    private func identifyVehicle(in pixelBuffer: CVPixelBuffer, boundingBox: CGRect, videoURL: URL, timestamp: TimeInterval) async -> VehicleInfo? {
        // Try Python-based identification first
        if let pythonResult = await vehicleIdentifier.identifyVehicle(
            videoPath: videoURL,
            timestamp: timestamp,
            boundingBox: boundingBox
        ) {
            return pythonResult
        }
        
        // Fallback to placeholder if Python script fails
        return VehicleInfo(
            make: "Unknown",
            model: "Unknown",
            color: "Unknown",
            year: "Unknown",
            confidence: 0.0
        )
    }
    
    private func findMatchingVehicle(boundingBox: CGRect, in vehicles: [VehicleDetection]) -> VehicleDetection? {
        for vehicle in vehicles {
            let intersection = boundingBox.intersection(vehicle.boundingBox)
            let iou = intersection.width * intersection.height / 
                     (boundingBox.width * boundingBox.height + 
                      vehicle.boundingBox.width * vehicle.boundingBox.height - 
                      intersection.width * intersection.height)
            
            if iou > 0.5 {
                return vehicle
            }
        }
        return nil
    }
}

class VehicleDetector {
    private lazy var objectDetectionRequest: VNRequest = {
        do {
            let config = MLModelConfiguration()
            config.computeUnits = .all
            
            guard let modelURL = Bundle.main.url(forResource: "YOLOv3", withExtension: "mlmodelc") else {
                return createBuiltInObjectDetectionRequest()
            }
            
            let model = try MLModel(contentsOf: modelURL, configuration: config)
            let visionModel = try VNCoreMLModel(for: model)
            
            let request = VNCoreMLRequest(model: visionModel) { request, error in
                if let error = error {
                    print("Vehicle detection error: \(error)")
                }
            }
            
            request.imageCropAndScaleOption = .scaleFit
            return request
        } catch {
            print("Failed to load ML model: \(error)")
            return createBuiltInObjectDetectionRequest()
        }
    }()
    
    private func createBuiltInObjectDetectionRequest() -> VNDetectRectanglesRequest {
        let request = VNDetectRectanglesRequest { request, error in
            if let error = error {
                print("Rectangle detection error: \(error)")
            }
        }
        request.minimumAspectRatio = 0.3
        request.maximumAspectRatio = 3.0
        request.minimumSize = 0.1
        request.maximumObservations = 10
        return request
    }
    
    func detect(in pixelBuffer: CVPixelBuffer) async -> [(boundingBox: CGRect, confidence: Float)] {
        var results: [(CGRect, Float)] = []
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        
        do {
            try handler.perform([objectDetectionRequest])
            
            if let observations = objectDetectionRequest.results as? [VNRecognizedObjectObservation] {
                results = observations
                    .filter { observation in
                        observation.labels.contains { $0.identifier.lowercased().contains("car") ||
                                                    $0.identifier.lowercased().contains("truck") ||
                                                    $0.identifier.lowercased().contains("vehicle") }
                    }
                    .map { ($0.boundingBox, $0.confidence) }
            } else if let observations = objectDetectionRequest.results as? [VNRectangleObservation] {
                results = observations.map { ($0.boundingBox, $0.confidence) }
            }
        } catch {
            print("Failed to perform vehicle detection: \(error)")
        }
        
        return results
    }
}