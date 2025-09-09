import Foundation
import Vision
import CoreImage
import CoreGraphics

class LicensePlateDetector {
    private let context = CIContext()
    
    func detect(in pixelBuffer: CVPixelBuffer, region: CGRect) async -> LicensePlate? {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        
        let cropRect = CGRect(
            x: region.minX * CGFloat(width),
            y: (1.0 - region.maxY) * CGFloat(height),
            width: region.width * CGFloat(width),
            height: region.height * CGFloat(height)
        )
        
        let croppedImage = ciImage.cropped(to: cropRect)
        
        let enhancedImage = enhanceImage(croppedImage)
        
        guard let cgImage = context.createCGImage(enhancedImage, from: enhancedImage.extent) else {
            return nil
        }
        
        let textRequest = VNRecognizeTextRequest { request, error in
            if let error = error {
                print("Text recognition error: \(error)")
            }
        }
        
        textRequest.recognitionLevel = .accurate
        textRequest.recognitionLanguages = ["en-US"]
        textRequest.usesLanguageCorrection = false
        textRequest.customWords = ["CA", "NY", "TX", "FL", "IL", "PA", "OH", "GA", "NC", "MI"]
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        do {
            try handler.perform([textRequest])
            
            guard let observations = textRequest.results else {
                return nil
            }
            
            for observation in observations {
                guard let topCandidate = observation.topCandidates(1).first else { continue }
                
                let text = topCandidate.string.uppercased()
                    .replacingOccurrences(of: " ", with: "")
                    .replacingOccurrences(of: "-", with: "")
                
                if isValidLicensePlate(text) {
                    let plateBox = CGRect(
                        x: region.minX + observation.boundingBox.minX * region.width,
                        y: region.minY + observation.boundingBox.minY * region.height,
                        width: observation.boundingBox.width * region.width,
                        height: observation.boundingBox.height * region.height
                    )
                    
                    return LicensePlate(
                        number: formatLicensePlate(text),
                        confidence: observation.confidence,
                        boundingBox: plateBox,
                        firstAppearance: 0,
                        lastAppearance: 0
                    )
                }
            }
            
            let rectangleRequest = VNDetectRectanglesRequest()
            rectangleRequest.minimumAspectRatio = 2.0
            rectangleRequest.maximumAspectRatio = 5.0
            rectangleRequest.minimumSize = 0.1
            rectangleRequest.maximumObservations = 5
            
            try handler.perform([rectangleRequest])
            
            if let rectangles = rectangleRequest.results {
                for rectangle in rectangles {
                    let plateRegion = CGRect(
                        x: rectangle.boundingBox.minX * enhancedImage.extent.width,
                        y: rectangle.boundingBox.minY * enhancedImage.extent.height,
                        width: rectangle.boundingBox.width * enhancedImage.extent.width,
                        height: rectangle.boundingBox.height * enhancedImage.extent.height
                    )
                    
                    let plateCrop = enhancedImage.cropped(to: plateRegion)
                    guard let plateCGImage = context.createCGImage(plateCrop, from: plateCrop.extent) else {
                        continue
                    }
                    
                    let plateTextRequest = VNRecognizeTextRequest()
                    plateTextRequest.recognitionLevel = .accurate
                    
                    let plateHandler = VNImageRequestHandler(cgImage: plateCGImage, options: [:])
                    try plateHandler.perform([plateTextRequest])
                    
                    if let textObservations = plateTextRequest.results {
                        for textObs in textObservations {
                            guard let candidate = textObs.topCandidates(1).first else { continue }
                            
                            let plateText = candidate.string.uppercased()
                                .replacingOccurrences(of: " ", with: "")
                                .replacingOccurrences(of: "-", with: "")
                            
                            if isValidLicensePlate(plateText) {
                                let plateBox = CGRect(
                                    x: region.minX + rectangle.boundingBox.minX * region.width,
                                    y: region.minY + rectangle.boundingBox.minY * region.height,
                                    width: rectangle.boundingBox.width * region.width,
                                    height: rectangle.boundingBox.height * region.height
                                )
                                
                                return LicensePlate(
                                    number: formatLicensePlate(plateText),
                                    confidence: textObs.confidence * rectangle.confidence,
                                    boundingBox: plateBox,
                                    firstAppearance: 0,
                                    lastAppearance: 0
                                )
                            }
                        }
                    }
                }
            }
        } catch {
            print("License plate detection failed: \(error)")
        }
        
        return nil
    }
    
    private func enhanceImage(_ image: CIImage) -> CIImage {
        var enhanced = image
        
        if let filter = CIFilter(name: "CIColorControls") {
            filter.setValue(enhanced, forKey: kCIInputImageKey)
            filter.setValue(1.2, forKey: kCIInputContrastKey)
            filter.setValue(0.1, forKey: kCIInputBrightnessKey)
            filter.setValue(1.1, forKey: kCIInputSaturationKey)
            if let output = filter.outputImage {
                enhanced = output
            }
        }
        
        if let filter = CIFilter(name: "CISharpenLuminance") {
            filter.setValue(enhanced, forKey: kCIInputImageKey)
            filter.setValue(0.4, forKey: kCIInputSharpnessKey)
            if let output = filter.outputImage {
                enhanced = output
            }
        }
        
        if let filter = CIFilter(name: "CINoiseReduction") {
            filter.setValue(enhanced, forKey: kCIInputImageKey)
            filter.setValue(0.02, forKey: "inputNoiseLevel")
            filter.setValue(0.4, forKey: "inputSharpness")
            if let output = filter.outputImage {
                enhanced = output
            }
        }
        
        return enhanced
    }
    
    private func isValidLicensePlate(_ text: String) -> Bool {
        let length = text.count
        guard length >= 5 && length <= 8 else { return false }
        
        let hasLetters = text.rangeOfCharacter(from: .letters) != nil
        let hasNumbers = text.rangeOfCharacter(from: .decimalDigits) != nil
        
        guard hasLetters && hasNumbers else { return false }
        
        let patterns = [
            "^[A-Z0-9]{5,8}$",
            "^[0-9][A-Z]{3}[0-9]{3}$",
            "^[A-Z]{3}[0-9]{3,4}$",
            "^[0-9]{1,3}[A-Z]{1,3}[0-9]{1,3}$",
            "^[A-Z]{2}[0-9]{2}[A-Z]{3}$"
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) != nil {
                return true
            }
        }
        
        return false
    }
    
    private func formatLicensePlate(_ text: String) -> String {
        if text.count == 7 {
            let index3 = text.index(text.startIndex, offsetBy: 3)
            return String(text[..<index3]) + " " + String(text[index3...])
        } else if text.count == 6 {
            let index3 = text.index(text.startIndex, offsetBy: 3)
            return String(text[..<index3]) + "-" + String(text[index3...])
        }
        return text
    }
}