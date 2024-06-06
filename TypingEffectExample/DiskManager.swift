import UIKit

class DiskManager {
    enum E: Error {
        case directoryAccessFailed,
             creatingSubdirectoryFailed(Error)
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
    
    static func removeAllImages(in url: URL) throws {
        let fileManager = FileManager.default
        let fileURLs = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
        
        for fileURL in fileURLs {
            try fileManager.removeItem(at: fileURL)
        }
    }
    
    static func createNewCustomDate() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd-HH-mm"
        let dateString = dateFormatter.string(from: Date())
        return dateString
    }
    
    lazy var customDate: String = {
        Self.createNewCustomDate()
    }()
    
    var _customIndex = 0
    var customIndex: Int {
        defer {
            _customIndex += 1
        }
        
        return _customIndex
    }
    
    func resetSubdirectory() throws {
        _customIndex = 0
        customDate = Self.createNewCustomDate()
        try Self.removeAllImages(in: Self.customSubdirectory)
    }
    
    func save(imageData: Data) throws {
        let subdirectoryURL = try Self.customSubdirectory
        let fileName = "\(customDate)-Image-\(String(format: "%03d", customIndex)).png"
        let fileURL = subdirectoryURL.appendingPathComponent(fileName)
        try imageData.write(to: fileURL)
    }
}
