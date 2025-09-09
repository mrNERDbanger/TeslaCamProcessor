import SwiftUI
import Combine
import AVFoundation
import Vision
import UniformTypeIdentifiers

@MainActor
class VideoProcessorViewModel: ObservableObject {
    @Published var videoFiles: [VideoFile] = []
    @Published var isProcessing = false
    @Published var overallProgress: Double = 0.0
    @Published var currentProcessingTask: String?
    @Published var processingLogs: [String] = []
    @Published var outputDirectory: URL?
    @Published var detectionCounts: [String: Int] = [:]
    
    private var processingQueue: OperationQueue
    private var detectionResults: [VehicleDetection] = []
    private var cancellables = Set<AnyCancellable>()
    private let videoProcessor: VideoProcessor
    private let csvExporter: CSVExporter
    private let videoMuxer: VideoMuxer
    
    init() {
        self.processingQueue = OperationQueue()
        self.processingQueue.maxConcurrentOperationCount = ProcessInfo.processInfo.processorCount
        self.processingQueue.qualityOfService = .userInitiated
        
        self.videoProcessor = VideoProcessor()
        self.csvExporter = CSVExporter()
        self.videoMuxer = VideoMuxer()
    }
    
    func handleDroppedVideos(providers: [NSItemProvider]) {
        for provider in providers {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { (item, error) in
                guard let data = item as? Data,
                      let url = URL(dataRepresentation: data, relativeTo: nil) else {
                    return
                }
                
                Task { @MainActor in
                    self.addVideoFile(url: url)
                }
            }
        }
    }
    
    private func addVideoFile(url: URL) {
        let filename = url.lastPathComponent
        guard let angle = VideoFile.CameraAngle.from(filename: filename) else {
            addLog("Skipped: \(filename) - Unknown camera angle")
            return
        }
        
        let timestamp = extractTimestamp(from: filename) ?? Date()
        let videoFile = VideoFile(url: url, angle: angle, timestamp: timestamp)
        
        if !videoFiles.contains(where: { $0.url == url }) {
            videoFiles.append(videoFile)
            addLog("Added: \(filename) (\(angle.rawValue))")
        }
    }
    
    private func extractTimestamp(from filename: String) -> Date? {
        let pattern = "(\\d{4})-(\\d{2})-(\\d{2})_(\\d{2})-(\\d{2})-(\\d{2})"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: filename, range: NSRange(filename.startIndex..., in: filename)) else {
            return nil
        }
        
        var components = DateComponents()
        components.year = Int((filename as NSString).substring(with: match.range(at: 1)))
        components.month = Int((filename as NSString).substring(with: match.range(at: 2)))
        components.day = Int((filename as NSString).substring(with: match.range(at: 3)))
        components.hour = Int((filename as NSString).substring(with: match.range(at: 4)))
        components.minute = Int((filename as NSString).substring(with: match.range(at: 5)))
        components.second = Int((filename as NSString).substring(with: match.range(at: 6)))
        
        return Calendar.current.date(from: components)
    }
    
    func startProcessing() {
        guard !isProcessing, let outputDir = outputDirectory else { return }
        
        isProcessing = true
        overallProgress = 0.0
        detectionResults.removeAll()
        processingLogs.removeAll()
        
        Task {
            await processAllVideos(outputDir: outputDir)
        }
    }
    
    private func processAllVideos(outputDir: URL) async {
        let totalVideos = videoFiles.count
        var processedCount = 0
        
        addLog("Starting processing of \(totalVideos) videos...")
        currentProcessingTask = "Initializing video processor..."
        
        let groupedVideos = Dictionary(grouping: videoFiles) { video in
            Calendar.current.startOfDay(for: video.timestamp)
        }
        
        for (date, videos) in groupedVideos {
            addLog("Processing videos from \(dateFormatter.string(from: date))")
            
            await withTaskGroup(of: [VehicleDetection].self) { group in
                for video in videos {
                    group.addTask {
                        await self.processVideo(video)
                    }
                }
                
                for await results in group {
                    self.detectionResults.append(contentsOf: results)
                    processedCount += 1
                    await MainActor.run {
                        self.overallProgress = Double(processedCount) / Double(totalVideos)
                    }
                }
            }
        }
        
        await MainActor.run {
            self.currentProcessingTask = "Generating CSV report..."
        }
        await generateCSV(outputDir: outputDir)
        
        await MainActor.run {
            self.currentProcessingTask = "Creating muxed videos..."
        }
        await createMuxedVideos(outputDir: outputDir)
        
        await MainActor.run {
            self.currentProcessingTask = "Saving to iCloud..."
        }
        await saveToiCloud(outputDir: outputDir)
        
        await MainActor.run {
            self.isProcessing = false
            self.currentProcessingTask = nil
            self.addLog("Processing completed!")
        }
    }
    
    private func processVideo(_ video: VideoFile) async -> [VehicleDetection] {
        await MainActor.run {
            self.currentProcessingTask = "Processing \(video.url.lastPathComponent)..."
        }
        
        let results = await videoProcessor.processVideo(url: video.url)
        
        await MainActor.run {
            let vehicleCount = results.count
            self.detectionCounts[video.url.lastPathComponent] = vehicleCount
            self.addLog("Found \(vehicleCount) vehicles in \(video.url.lastPathComponent)")
        }
        
        return results
    }
    
    private func generateCSV(outputDir: URL) async {
        let csvURL = outputDir.appendingPathComponent("vehicle_detections.csv")
        await csvExporter.export(detections: detectionResults, to: csvURL)
        addLog("CSV report saved to \(csvURL.lastPathComponent)")
    }
    
    private func createMuxedVideos(outputDir: URL) async {
        let groupedByPlate = Dictionary(grouping: detectionResults) { detection in
            detection.licensePlate?.number ?? "unknown"
        }
        
        for (plate, detections) in groupedByPlate where plate != "unknown" {
            let vehicleInfo = detections.first?.vehicleInfo
            let filename = "\(vehicleInfo?.make ?? "Unknown") - \(vehicleInfo?.model ?? "Unknown") - \(plate).mp4"
            let outputURL = outputDir.appendingPathComponent(filename)
            
            await videoMuxer.createMuxedVideo(
                for: detections,
                from: videoFiles,
                outputURL: outputURL
            )
            
            addLog("Created muxed video: \(filename)")
        }
    }
    
    private func saveToiCloud(outputDir: URL) async {
        addLog("Files saved to: \(outputDir.path)")
    }
    
    func cancelProcessing() {
        processingQueue.cancelAllOperations()
        isProcessing = false
        currentProcessingTask = nil
        addLog("Processing cancelled")
    }
    
    func clearAll() {
        videoFiles.removeAll()
        detectionResults.removeAll()
        processingLogs.removeAll()
        detectionCounts.removeAll()
        overallProgress = 0.0
    }
    
    private func addLog(_ message: String) {
        processingLogs.append("\(Date().formatted(date: .omitted, time: .shortened)) - \(message)")
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }
}