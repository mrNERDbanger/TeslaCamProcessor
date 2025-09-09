import Foundation
import AVFoundation

actor VideoMuxer {
    private let ffmpegPath = "/opt/homebrew/bin/ffmpeg"
    
    func createMuxedVideo(
        for detections: [VehicleDetection],
        from videoFiles: [VideoFile],
        outputURL: URL
    ) async {
        let startTime = detections.map { $0.timeStart }.min() ?? 0
        let endTime = detections.map { $0.timeEnd }.max() ?? 0
        
        let frontVideo = videoFiles.first { $0.angle == .front }
        let backVideo = videoFiles.first { $0.angle == .back }
        let leftVideo = videoFiles.first { $0.angle == .left }
        let rightVideo = videoFiles.first { $0.angle == .right }
        
        guard let front = frontVideo?.url,
              let back = backVideo?.url,
              let left = leftVideo?.url,
              let right = rightVideo?.url else {
            print("Missing required camera angles for muxing")
            return
        }
        
        await muxVideosWithFFmpeg(
            front: front,
            back: back,
            left: left,
            right: right,
            startTime: startTime,
            duration: endTime - startTime,
            outputURL: outputURL
        )
    }
    
    private func muxVideosWithFFmpeg(
        front: URL,
        back: URL,
        left: URL,
        right: URL,
        startTime: TimeInterval,
        duration: TimeInterval,
        outputURL: URL
    ) async {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: ffmpegPath)
        
        let startTimeStr = formatFFmpegTime(startTime)
        let durationStr = String(format: "%.2f", duration)
        
        let filterComplex = """
            [0:v]scale=640:480[v0];
            [1:v]scale=640:480[v1];
            [2:v]scale=640:480[v2];
            [3:v]scale=640:480[v3];
            [v0][v1]hstack[top];
            [v2][v3]hstack[bottom];
            [top][bottom]vstack[out]
            """
        
        process.arguments = [
            "-ss", startTimeStr,
            "-i", front.path,
            "-ss", startTimeStr,
            "-i", back.path,
            "-ss", startTimeStr,
            "-i", left.path,
            "-ss", startTimeStr,
            "-i", right.path,
            "-t", durationStr,
            "-filter_complex", filterComplex,
            "-map", "[out]",
            "-c:v", "libx264",
            "-preset", "fast",
            "-crf", "23",
            "-an",
            "-y",
            outputURL.path
        ]
        
        do {
            try process.run()
            process.waitUntilExit()
            
            if process.terminationStatus == 0 {
                print("Successfully created muxed video: \(outputURL.lastPathComponent)")
            } else {
                print("FFmpeg failed with status: \(process.terminationStatus)")
                await fallbackMuxWithAVFoundation(
                    front: front,
                    back: back,
                    left: left,
                    right: right,
                    startTime: startTime,
                    duration: duration,
                    outputURL: outputURL
                )
            }
        } catch {
            print("Failed to run FFmpeg: \(error)")
            await fallbackMuxWithAVFoundation(
                front: front,
                back: back,
                left: left,
                right: right,
                startTime: startTime,
                duration: duration,
                outputURL: outputURL
            )
        }
    }
    
    private func fallbackMuxWithAVFoundation(
        front: URL,
        back: URL,
        left: URL,
        right: URL,
        startTime: TimeInterval,
        duration: TimeInterval,
        outputURL: URL
    ) async {
        let composition = AVMutableComposition()
        let videoComposition = AVMutableVideoComposition()
        
        let renderSize = CGSize(width: 1280, height: 960)
        videoComposition.renderSize = renderSize
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
        
        var instructions: [AVMutableVideoCompositionInstruction] = []
        
        let videoURLs = [(front, CGRect(x: 0, y: 0, width: 640, height: 480)),
                        (back, CGRect(x: 640, y: 0, width: 640, height: 480)),
                        (left, CGRect(x: 0, y: 480, width: 640, height: 480)),
                        (right, CGRect(x: 640, y: 480, width: 640, height: 480))]
        
        for (url, frame) in videoURLs {
            let asset = AVAsset(url: url)
            
            guard let videoTrack = try? await asset.loadTracks(withMediaType: .video).first,
                  let compositionTrack = composition.addMutableTrack(
                    withMediaType: .video,
                    preferredTrackID: kCMPersistentTrackID_Invalid
                  ) else {
                continue
            }
            
            let startCMTime = CMTime(seconds: startTime, preferredTimescale: 600)
            let durationCMTime = CMTime(seconds: duration, preferredTimescale: 600)
            let timeRange = CMTimeRange(start: startCMTime, duration: durationCMTime)
            
            do {
                try compositionTrack.insertTimeRange(
                    timeRange,
                    of: videoTrack,
                    at: .zero
                )
                
                let instruction = AVMutableVideoCompositionInstruction()
                instruction.timeRange = CMTimeRange(start: .zero, duration: durationCMTime)
                
                let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compositionTrack)
                
                let transform = CGAffineTransform(translationX: frame.minX, y: frame.minY)
                    .scaledBy(x: frame.width / 1280, y: frame.height / 960)
                
                layerInstruction.setTransform(transform, at: .zero)
                instruction.layerInstructions.append(layerInstruction)
                instructions.append(instruction)
            } catch {
                print("Failed to insert video track: \(error)")
            }
        }
        
        videoComposition.instructions = instructions
        
        guard let exportSession = AVAssetExportSession(
            asset: composition,
            presetName: AVAssetExportPresetHighestQuality
        ) else {
            print("Failed to create export session")
            return
        }
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        exportSession.videoComposition = videoComposition
        
        await exportSession.export()
        
        switch exportSession.status {
        case .completed:
            print("Successfully created muxed video with AVFoundation: \(outputURL.lastPathComponent)")
        case .failed:
            if let error = exportSession.error {
                print("Export failed: \(error)")
            }
        case .cancelled:
            print("Export cancelled")
        default:
            print("Export status: \(exportSession.status.rawValue)")
        }
    }
    
    private func formatFFmpegTime(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        let secs = seconds.truncatingRemainder(dividingBy: 60)
        
        return String(format: "%02d:%02d:%06.3f", hours, minutes, secs)
    }
}