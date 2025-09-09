import Foundation
import CoreGraphics

struct VehicleDetection: Identifiable {
    let id = UUID()
    let timeStart: TimeInterval
    let timeEnd: TimeInterval
    let boundingBox: CGRect
    let confidence: Float
    let licensePlate: LicensePlate?
    let vehicleInfo: VehicleInfo?
    
    var duration: TimeInterval {
        timeEnd - timeStart
    }
}

struct LicensePlate: Identifiable {
    let id = UUID()
    let number: String
    let confidence: Float
    let boundingBox: CGRect
    let firstAppearance: TimeInterval
    let lastAppearance: TimeInterval
    
    var duration: TimeInterval {
        lastAppearance - firstAppearance
    }
}

struct VehicleInfo: Identifiable {
    let id = UUID()
    let make: String?
    let model: String?
    let color: String?
    let year: String?
    let confidence: Float
}