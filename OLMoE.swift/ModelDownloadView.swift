import SwiftUI

struct ModelDownloadView: View {
    @Binding var isModelReady: Bool
    @State private var downloadProgress: Float = 0
    @State private var isDownloading = false
    @State private var downloadError: String?
    @State private var observation: NSKeyValueObservation?

    private let modelURL = URL(string: "https://dolma-artifacts.org/app/olmoe-1b-7b-0924-instruct-q4_k_m.gguf")!

    var body: some View {
        VStack {
            if isModelReady {
                Text("Model is ready to use!")
                Button("Flush Model", action: flushModel)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            } else if isDownloading {
                ProgressView("Downloading...", value: downloadProgress, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle())
                    .padding()
                Text("\(Int(downloadProgress * 100))%")
            } else {
                Button("Download Model", action: startDownload)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }

            if let error = downloadError {
                Text(error)
                    .foregroundColor(.red)
                    .padding()
            }
        }
        .onAppear(perform: checkModelExists)
    }

    private func checkModelExists() {
        if FileManager.default.fileExists(atPath: Bot.modelFileURL.path) {
            isModelReady = true
        }
    }

    private func startDownload() {
           isDownloading = true
           downloadError = nil
           
           let destination = Bot.modelFileURL
           
           let task = URLSession.shared.downloadTask(with: modelURL) { localURL, response, error in
               if let error = error {
                   DispatchQueue.main.async {
                       self.downloadError = "Download failed: \(error.localizedDescription)"
                       self.isDownloading = false
                   }
                   return
               }
            
            guard let localURL = localURL else {
                DispatchQueue.main.async {
                    self.downloadError = "Download failed: No local file URL"
                    self.isDownloading = false
                }
                return
            }
            
            do {
                if FileManager.default.fileExists(atPath: destination.path) {
                    try FileManager.default.removeItem(at: destination)
                }
                try FileManager.default.moveItem(at: localURL, to: destination)
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
        
        task.resume()

        // Observe download progress
        observation = task.progress.observe(\.fractionCompleted) { progress, _ in
            DispatchQueue.main.async {
                self.downloadProgress = Float(progress.fractionCompleted)
            }
        }
    }
    
    private func flushModel() {
            do {
                try FileManager.default.removeItem(at: Bot.modelFileURL)
                isModelReady = false
            } catch {
                downloadError = "Failed to flush model: \(error.localizedDescription)"
            }
        }
    }
