import UIKit
import AVFoundation

class DiskManager {
    static let width = 1920
    static let height = 1080
    
    enum E: Error {
        case directoryAccessFailed,
             creatingSubdirectoryFailed(Error),
             imageNotFoundAtIndex(Int),
             imageNotFound(URL),
             pixelBufferCreationFailed
    }
    
    static var documentDirectoryURL: URL? {
        let fileManager = FileManager.default
        
        if let directory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            return directory
        }
        
        return nil
    }

    static func documentSubdirectoryURL(named subdirectoryName: String) throws -> URL {
        guard let directoryURL = documentDirectoryURL else {
            throw E.directoryAccessFailed
        }
        
        let subdirectoryURL = directoryURL.appendingPathComponent(subdirectoryName)
        var isDirectory: ObjCBool = false
        let fileExists = FileManager.default.fileExists(atPath: subdirectoryURL.path(percentEncoded: false), isDirectory: &isDirectory)
        
        if isDirectory.boolValue, fileExists {
            return subdirectoryURL
        }
        
        do {
            try FileManager.default.createDirectory(at: subdirectoryURL, withIntermediateDirectories: true, attributes: nil)
            return subdirectoryURL
        } catch {
            throw E.creatingSubdirectoryFailed(error)
        }
    }
    
    static var customSubdirectory: URL {
        get throws {
            try Self.documentSubdirectoryURL(named: "TypingEffectApp-Images-Cache")
        }
    }
    
    static func image(at index: Int) throws -> CIImage {
        let subdirectoryURL = try Self.customSubdirectory
        
        // Define the index pattern to match
        let fileName = String(format: "Image-\(index)")
        let fileURL = subdirectoryURL.appendingPathComponent(fileName, conformingTo: .png)
        let imageData = try Data(contentsOf: fileURL)
        
        guard let image = CIImage(data: imageData) else {
            throw E.imageNotFound(fileURL)
        }
        
        return image
    }
    
    static func removeAllImages(in url: URL) throws {
        let fileManager = FileManager.default
        let fileURLs = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
        
        let imageExtensions: Set<String> = ["jpeg", "jpg", "gif", "bmp", "tiff", "heic"]

        for fileURL in fileURLs {
            let fileExtension = fileURL.pathExtension.lowercased()
            if imageExtensions.contains(fileExtension) {
                try fileManager.removeItem(at: fileURL)
            }
        }
    }

    static func remove(fileURL url: URL) throws {
        let fileManager = FileManager.default
        
        let fileExists = FileManager.default.fileExists(atPath: url.path(percentEncoded: false), isDirectory: nil)
        if fileExists {
            try fileManager.removeItem(at: url)
        }
    }

    
    static func createNewCustomDate() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd-HH-mm"
        let dateString = dateFormatter.string(from: Date())
        return dateString
    }
    
    var _customIndex = 0
    var customIndex: Int {
        defer {
            _customIndex += 1
        }
        
        return _customIndex
    }
    
    func resetSubdirectory() throws {
        _customIndex = 0
        try Self.removeAllImages(in: Self.customSubdirectory)
    }
    
    func save(imageData: Data) throws {
        let subdirectoryURL = try Self.customSubdirectory
        let fileName = "Image-\(customIndex).png"
        let fileURL = subdirectoryURL.appendingPathComponent(fileName)
        try imageData.write(to: fileURL)
    }
    
    let context = CIContext()
    let background = {
        let url = Bundle.main.bundleURL.appending(path: "Background.jpg")
        let data = try! Data(contentsOf: url)
        return CIImage(data: data)!
    }()
    
    func getPixelBufferForImage(at index: Int, pool: CVPixelBufferPool) throws -> CVPixelBuffer {
        var pixelBuffer: CVPixelBuffer?
        
        try autoreleasepool {
            let staticImage = try Self.image(at: index)
            let finalImage = staticImage.composited(over: background)
            
            CVPixelBufferPoolCreatePixelBuffer(nil, pool, &pixelBuffer)
            
            guard let pixelBuffer = pixelBuffer else {
                throw E.pixelBufferCreationFailed
            }
            
            context.render(finalImage, to: pixelBuffer)
        }
        
        return pixelBuffer!
    }
    
    func createVideo() async throws -> URL {
        let outputMovieURL = try Self.customSubdirectory.appendingPathComponent("TypingVideoResult.mov")
        try Self.remove(fileURL: outputMovieURL)
        
        let assetwriter = try AVAssetWriter(outputURL: outputMovieURL, fileType: .mov)
        
        let settings = [
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: 15000000,
                AVVideoExpectedSourceFrameRateKey: 60,
                AVVideoH264EntropyModeKey: AVVideoH264EntropyModeCABAC,
                AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel,
            ],
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey : Self.width,
            AVVideoHeightKey: Self.height,
            AVVideoScalingModeKey: AVVideoScalingModeResizeAspect,
        ] as [String : Any]
        let assetWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
        
        let attributes = [
            kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue!,
            kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue!,
            kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey: Self.width,
            kCVPixelBufferHeightKey: Self.height,
        ] as Dictionary<String, Any>
        
        let assetWriterAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: assetWriterInput, sourcePixelBufferAttributes: attributes)
        assetwriter.add(assetWriterInput)
        
        assetwriter.startWriting()
        assetwriter.startSession(atSourceTime: CMTime.zero)
        
        let framesPerSecond = 60
        let totalFrames = customIndex
        var frameCount = 0
        while frameCount < totalFrames {
          if assetWriterInput.isReadyForMoreMediaData {
            let frameTime = CMTimeMake(value: Int64(frameCount), timescale: Int32(framesPerSecond))
              let pixelBuffer = try getPixelBufferForImage(at: frameCount, pool: assetWriterAdaptor.pixelBufferPool!)
            assetWriterAdaptor.append(pixelBuffer, withPresentationTime: frameTime)
            frameCount+=1
          }
        }
        
        // close everything
        assetWriterInput.markAsFinished()
        
        try DiskManager.removeAllImages(in: DiskManager.customSubdirectory)
        
        return await withCheckedContinuation { (continuation: CheckedContinuation<URL, Never>) in
            assetwriter.finishWriting {
                continuation.resume(returning: outputMovieURL)
            }
        }
    }
}

extension DiskManager.E: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .directoryAccessFailed:
            return "Directory access failed"
        case .creatingSubdirectoryFailed(let error):
            return "Creating subdirectory failed: \(error.localizedDescription)"
        case .imageNotFoundAtIndex(let index):
            return "Image is not found at the index \(index)"
        case .imageNotFound(let url):
            return "Image is not found at \(url.absoluteString)"
        case .pixelBufferCreationFailed:
            return "Pixel buffer creation failed"
        }
    }
}
