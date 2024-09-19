import SwiftUI
import Combine

class BackgroundDownloadManager: NSObject, ObservableObject, URLSessionDownloadDelegate {
    static let shared = BackgroundDownloadManager()
    
    @Published var downloadProgress: Float = 0
    @Published var isDownloading = false
    @Published var downloadError: String?
    @Published var isModelReady = false
    @Published var downloadedSize: Int64 = 0
    @Published var totalSize: Int64 = 0
    
    private var backgroundSession: URLSession!
    private var downloadTask: URLSessionDownloadTask?
    private var lastUpdateTime: Date = Date()
    private let updateInterval: TimeInterval = 0.5 // Update UI every 0.5 seconds
    
    private override init() {
        super.init()
        let config = URLSessionConfiguration.background(withIdentifier: "ai.olmo.OLMoE.backgroundDownload")
        config.isDiscretionary = false
        config.sessionSendsLaunchEvents = true
        backgroundSession = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }
    
    func startDownload() {
        guard let url = URL(string: "https://dolma-artifacts.org/app/olmoe-1b-7b-0924-instruct-q4_k_m.gguf") else { return }
        
        isDownloading = true
        downloadError = nil
        downloadedSize = 0
        totalSize = 0
        
        downloadTask = backgroundSession.downloadTask(with: url)
        downloadTask?.resume()
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let destination = Bot.modelFileURL
        
        do {
            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }
            try FileManager.default.moveItem(at: location, to: destination)
            DispatchQueue.main.async {
                self.isModelReady = true
                self.isDownloading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.downloadError = "Failed to save file: \(error.localizedDescription)"
                self.isDownloading = false
            }
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        DispatchQueue.main.async {
            if let error = error {
                self.downloadError = "Download failed: \(error.localizedDescription)"
                self.isDownloading = false
            }
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let currentTime = Date()
        if currentTime.timeIntervalSince(lastUpdateTime) >= updateInterval {
            DispatchQueue.main.async {
                self.downloadProgress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
                self.downloadedSize = totalBytesWritten
                self.totalSize = totalBytesExpectedToWrite
                self.lastUpdateTime = currentTime
            }
        }
    }
    
    func flushModel() {
        do {
            try FileManager.default.removeItem(at: Bot.modelFileURL)
            isModelReady = false
        } catch {
            downloadError = "Failed to flush model: \(error.localizedDescription)"
        }
    }
}

struct ModelDownloadView: View {
    @StateObject private var downloadManager = BackgroundDownloadManager.shared
    
    private func formatSize(_ size: Int64) -> String {
        let sizeInGB = Double(size) / 1_000_000_000.0
        return String(format: "%.2f GB", sizeInGB)
    }
    
    var body: some View {
        ZStack {
            Color("BackgroundColor")
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                if downloadManager.isModelReady {
                    Text("Model is ready to use!")
                        .foregroundColor(Color("TextColor"))
                    Button("Flush Model", action: downloadManager.flushModel)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .font(.manrope())
                } else if downloadManager.isDownloading {
                    ProgressView("Downloading...", value: downloadManager.downloadProgress, total: 1.0)
                        .progressViewStyle(LinearProgressViewStyle())
                        .padding()
                        .foregroundColor(Color("TextColor"))
                    Text("\(Int(downloadManager.downloadProgress * 100))% - \(formatSize(downloadManager.downloadedSize)) / \(formatSize(downloadManager.totalSize))")
                        .foregroundColor(Color("TextColor"))
                        .font(.manrope())
                } else {
                    Button("Download Model", action: downloadManager.startDownload)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(Color.textColorButton)
                        .cornerRadius(8)
                        .font(.manrope(.bold))
                }

                if let error = downloadManager.downloadError {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                }
            }
        }
        .onAppear {
            if FileManager.default.fileExists(atPath: Bot.modelFileURL.path) {
                downloadManager.isModelReady = true
            }
        }
    }
}
