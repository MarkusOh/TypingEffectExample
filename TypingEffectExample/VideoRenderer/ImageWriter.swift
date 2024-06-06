//
//  ImageWriter.swift
//  TypingEffectExample
//
//  Created by Seungsub Oh on 6/6/24.
//

import PhotosUI

class ImageAnimator {
    enum E: Error {
        case photoLibraryNoAccess
        case unableToSave
        case unableToSaveWithError(Error)
    }
    
    // Apple suggests a timescale of 600 because it's a multiple of standard video rates 24, 25, 30, 60 fps etc.
    static let kTimescale: Int32 = 600
    let settings: RenderSettings
    let videoWriter: VideoWriter
    var images = [UIImage]()
    var frameNum = 0
    
    static func saveToLibrary(videoURL: URL) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            PHPhotoLibrary.requestAuthorization { status in
                guard status == .authorized else {
                    continuation.resume(throwing: E.photoLibraryNoAccess)
                    return
                }
                
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoURL)
                }) { success, error in
                    if success == false, error == nil {
                        continuation.resume(throwing: E.unableToSave)
                        return
                    }
                    
                    if let error {
                        continuation.resume(throwing: E.unableToSaveWithError(error))
                        return
                    }
                    
                    continuation.resume()
                }
            }
        }
    }
    
    static func removeFileAtURL(fileURL: URL) throws {
        if FileManager.default.fileExists(atPath: fileURL.path(percentEncoded: false)) {
            try FileManager.default.removeItem(atPath: fileURL.path)
        }
    }
    
    init(renderSettings: RenderSettings) {
        settings = renderSettings
        videoWriter = VideoWriter(renderSettings: settings)
    }
    
    func render() async throws {
        try Self.removeFileAtURL(fileURL: settings.outputURL)
        
        videoWriter.start()
        await videoWriter.render(appendPixelBuffers: appendPixelBuffers)
    }
    
    // This is the callback function for VideoWriter.render()
    func appendPixelBuffers(writer: VideoWriter) -> Bool {
        
        let frameDuration = CMTimeMake(value: Int64(ImageAnimator.kTimescale / settings.fps), timescale: ImageAnimator.kTimescale)
        
        while !images.isEmpty {
            
            if writer.isReadyForData == false {
                // Inform writer we have more buffers to write.
                return false
            }
            
            let image = images.removeFirst()
            let presentationTime = CMTimeMultiply(frameDuration, multiplier: Int32(frameNum))
            let success = videoWriter.addImage(image: image, withPresentationTime: presentationTime)
            if success == false {
                fatalError("addImage() failed")
            }
            
            frameNum += 1
        }
        
        // Inform writer all buffers have been written.
        return true
    }
}

extension ImageAnimator.E : LocalizedError {
    var errorDescription: String? {
        switch self {
        case .photoLibraryNoAccess:
            return "Please grant access to your photo library for saving"
        case .unableToSave:
            return "For some reason, the app could not save the video"
        case .unableToSaveWithError(let saveError):
            return "Due to \"\(saveError.localizedDescription)\" error, the app could not save the video"
        }
    }
}
