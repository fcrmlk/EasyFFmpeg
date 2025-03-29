import ffmpegkit
import SwiftUI

class FFmpegViewModel: ObservableObject {
    
    func createRemoteFileList(videoURLs: [String]) -> URL? {
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
    
    func downloadAndConcatenateVideos(videoURLs: [String], completion: @escaping (URL?) -> Void) {
        guard let fileList = createRemoteFileList(videoURLs: videoURLs) else {
            completion(nil)
            return
        }
        
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID()).mp4")
        let command = """
        -protocol_whitelist file,http,https,tcp,tls -f concat -safe 0 -i \(fileList.path) -c copy \(outputURL.path)
        """
        
        FFmpegKitConfig.enableLogCallback { log in
            if let logMessage = log?.getMessage() {
                print("📜 FFmpeg Log: \(logMessage)")
            }
        }
        
        FFmpegKit.executeAsync(command) { session in
            if let returnCode = session?.getReturnCode(), returnCode.isValueSuccess() {
                print("✅ Download & Merge Successful: \(outputURL)")
                completion(outputURL)
            } else {
                print("❌ Error: \(session?.getFailStackTrace() ?? "Unknown error")")
                completion(nil)
            }
        }
    }
}
