// FCRMLK - haid3rawan@icloud.com

import ffmpegkit
import SwiftUI

public class FFmpegViewModel: ObservableObject {
    
    private var currentFFmpegSession: FFmpegSession? // Store the reference to the session
    
    public init() {
        // Enable FFmpeg log callback
        FFmpegKitConfig.enableLogCallback { log in
            if let logMessage = log?.getMessage() {
                print("📜 FFmpeg Log: \(logMessage)")
            }
        }
    }

    public func downloadSingleVideo(from url: String, completion: @escaping (URL?) -> Void) {
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).mp4")

        let command = """
        -i "\(url)" -c copy "\(outputURL.path)"
        """

        print("📥 Starting single video download with FFmpeg.")

        currentFFmpegSession = FFmpegKit.executeAsync(command) { session in
            self.currentFFmpegSession = nil

            if let returnCode = session?.getReturnCode(), returnCode.isValueSuccess() {
                print("✅ Single video download successful: \(outputURL.path)")
                completion(outputURL)
            } else {
                print("❌ FFmpeg Error (Single Download): \(session?.getFailStackTrace() ?? "Unknown error")")
                completion(nil)
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
        
        currentFFmpegSession = FFmpegKit.executeAsync(command) { session in
            self.currentFFmpegSession = nil // clear the session reference when the task completes
            
            if let returnCode = session?.getReturnCode(), returnCode.isValueSuccess() {
                print("✅ Download & Merge Successful: \(outputURL.path)")
                completion(outputURL)
            } else {
                print("❌ FFmpeg Error: \(session?.getFailStackTrace() ?? "Unknown error")")
                completion(nil)
            }
        }
    }
    
    public func mergeAudioAndVideo(videoURL: String, audioUrl: String, completion: @escaping (URL?) -> Void) {
        
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).mp4")
        
        var command: String
        
        command = """
             -i "\(videoURL)" -i "\(audioUrl)" -c:v copy -map 0:v -map 1:a -c:a aac -strict experimental -shortest "\(outputURL.path)"
        """
        
        currentFFmpegSession = FFmpegKit.executeAsync(command) { session in
            self.currentFFmpegSession = nil // clear the session reference when the task completes
            
            if let returnCode = session?.getReturnCode(), returnCode.isValueSuccess() {
                print("✅ Download & Merge Successful: \(outputURL.path)")
                completion(outputURL)
            } else {
                print("❌ FFmpeg Error: \(session?.getFailStackTrace() ?? "Unknown error")")
                completion(nil)
            }
        }
    }
    
    public func generateSRT(from subtitles: [String], durationPerLine: Int = 6) -> URL? {
        var srtContent = ""
        
        for (index, line) in subtitles.enumerated() {
            let startSeconds = index * durationPerLine
            let endSeconds = (index + 1) * durationPerLine
            
            let startTime = formatToSRTTime(seconds: startSeconds)
            let endTime = formatToSRTTime(seconds: endSeconds)
            
            srtContent += """
            \(index + 1)
            \(startTime) --> \(endTime)
            \(line)
            
            """
        }

        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("generated_\(UUID().uuidString).srt")
        do {
            try srtContent.write(to: fileURL, atomically: true, encoding: .utf8)
            print("✅ SRT file created: \(fileURL.path)")
            return fileURL
        } catch {
            print("❌ Failed to write SRT: \(error)")
            return nil
        }
    }
    
    public func addSubtitlesToVideo(videoURL: String, subtitleURL: String, completion: @escaping (URL?) -> Void) {
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString)_subtitled.mp4")

        let command = """
        -i "\(videoURL)" -vf subtitles='\(subtitleURL)' -c:a copy "\(outputURL.path)"
        """

        print("🎬 Adding subtitles to video...")

        currentFFmpegSession = FFmpegKit.executeAsync(command) { session in
            self.currentFFmpegSession = nil
            
            if let returnCode = session?.getReturnCode(), returnCode.isValueSuccess() {
                print("✅ Subtitles added successfully: \(outputURL.path)")
                completion(outputURL)
            } else {
                print("❌ FFmpeg subtitle error: \(session?.getFailStackTrace() ?? "Unknown error")")
                completion(nil)
            }
        }
    }
    
    private func formatToSRTTime(seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d:%02d,000", hours, minutes, secs)
    }
    
    
    // Function to cancel the FFmpeg operation
    public func cancelFFmpegDownload() {
        currentFFmpegSession?.cancel()
        print("⛔️ FFmpeg process cancelled.")
    }
}
