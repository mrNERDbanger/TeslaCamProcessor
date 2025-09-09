import Foundation

struct VideoFile: Identifiable, Hashable {
    let id = UUID()
    let url: URL
    let angle: CameraAngle
    let timestamp: Date
    var processingStatus: ProcessingStatus = .pending
    
    enum CameraAngle: String, CaseIterable {
        case front = "front"
        case back = "back"
        case left = "left_repeater"
        case right = "right_repeater"
        
        static func from(filename: String) -> CameraAngle? {
            let lowercased = filename.lowercased()
            for angle in CameraAngle.allCases {
                if lowercased.contains(angle.rawValue) {
                    return angle
                }
            }
            return nil
        }
    }
    
    enum ProcessingStatus: Hashable, Equatable {
        case pending
        case processing(progress: Double)
        case completed
        case failed(String)
        
        static func == (lhs: ProcessingStatus, rhs: ProcessingStatus) -> Bool {
            switch (lhs, rhs) {
            case (.pending, .pending), (.completed, .completed):
                return true
            case let (.processing(p1), .processing(p2)):
                return p1 == p2
            case let (.failed(e1), .failed(e2)):
                return e1 == e2
            default:
                return false
            }
        }
        
        func hash(into hasher: inout Hasher) {
            switch self {
            case .pending:
                hasher.combine(0)
            case .processing(let progress):
                hasher.combine(1)
                hasher.combine(progress)
            case .completed:
                hasher.combine(2)
            case .failed(let error):
                hasher.combine(3)
                hasher.combine(error)
            }
        }
    }
}