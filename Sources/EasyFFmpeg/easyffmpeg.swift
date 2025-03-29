// FCRMLK - haid3rawan@icloud.com

import ffmpegkit
import SwiftUI

public class FFmpegViewModel: ObservableObject {
    
    public init() {
        // Enable FFmpeg log callback
        FFmpegKitConfig.enableLogCallback { log in
            if let logMessage = log?.getMessage() {
                print("📜 FFmpeg Log: \(logMessage)")
            }
        }
    }

    public func createRemoteFileList(videoURLs: [String]) -> URL? {
        let fileListContent = videoURLs.map { "file '\($0)'" }.joined(separator: "\n")
        
        let fileListURL = FileManager.default.temporaryDirectory.appendingPathComponent("file_list.txt")
        
        do {
            try fileListContent.write(to: fileListURL, atomically: true, encoding: .utf8)
            return fileListURL
        } catch {
            print("❌ Error writing file list: \(error)")
            return nil
        }
    }

    public func downloadAndConcatenateVideos(videoURLs: [String], completion: @escaping (URL?) -> Void) {
        guard let fileList = createRemoteFileList(videoURLs: videoURLs) else {
            completion(nil)
            return
        }
        
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).mp4")
        var command: String

        if videoURLs.count == 1, let firstVideoUrl = videoURLs.first {
            command = """
            -i "\(firstVideoUrl)" -c copy "\(outputURL.path)"
            """
        } else {
            command = """
            -protocol_whitelist file,http,https,tcp,tls -f concat -safe 0 -i "\(fileList.path)" -c copy "\(outputURL.path)"
            """
        }
        
        print("🔹 Processing \(videoURLs.count) video(s) with FFmpeg.")
        
        FFmpegKit.executeAsync(command) { session in
            if let returnCode = session?.getReturnCode(), returnCode.isValueSuccess() {
                print("✅ Download & Merge Successful: \(outputURL.path)")
                completion(outputURL)
            } else {
                print("❌ FFmpeg Error: \(session?.getFailStackTrace() ?? "Unknown error")")
                completion(nil)
            }
        }
    }
}
