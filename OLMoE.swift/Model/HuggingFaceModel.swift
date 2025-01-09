//
//  HuggingFaceModel.swift
//  OLMoE.swift
//
//  Created by Ken Adamson on 11/17/24.
//


import Foundation
import llama

public struct HuggingFaceModel {
    public let name: String
    public let template: Template
    public let filterRegexPattern: String

    public init(_ name: String, template: Template, filterRegexPattern: String) {
        self.name = name
        self.template = template
        self.filterRegexPattern = filterRegexPattern
    }

    public init(_ name: String, _ quantization: Quantization = .Q4_K_M, template: Template) {
        self.name = name
        self.template = template
        self.filterRegexPattern = "(?i)\(quantization.rawValue)"
    }

    /// Asynchronously retrieves an array of download URLs for the model from Hugging Face.
    /// - Throws: An error if the URL retrieval fails or if the content cannot be parsed.
    /// - Returns: An array of download URLs as strings.
    func getDownloadURLStrings() async throws -> [String] {
        let url = URL(string: "https://huggingface.co/\(name)/tree/main")!
        let data = try await url.getData()
        let content = String(data: data, encoding: .utf8)!
        let downloadURLPattern = #"(?<=href=").*\.gguf\?download=true"#
        let matches = try! downloadURLPattern.matches(in: content)
        let root = "https://huggingface.co"
        return matches.map { match in root + match }
    }

    /// Asynchronously retrieves the first valid download URL that matches the filter regex pattern.
    /// - Throws: An error if no valid URL is found or if the retrieval fails.
    /// - Returns: The first matching download URL as a URL object, or nil if no match is found.
    func getDownloadURL() async throws -> URL? {
        let urlStrings = try await getDownloadURLStrings()
        for urlString in urlStrings {
            let found = try filterRegexPattern.hasMatch(in: urlString)
            if found { return URL(string: urlString)! }
        }
        return nil
    }

    /// Downloads the model to a specified directory and reports progress.
    /// - Parameters:
    ///   - directory: The directory to which the model will be downloaded. Defaults to `.modelsDirectory`.
    ///   - name: An optional name for the downloaded file. If provided, it will be used as the filename.
    ///   - updateProgress: A closure that receives a `Double` representing the download progress (0.0 to 1.0).
    /// - Throws: An error if the download fails or if the destination already exists.
    /// - Returns: The URL of the downloaded model file.
    public func download(to directory: URL = .modelsDirectory, as name: String? = nil, _ updateProgress: @escaping (Double) -> Void) async throws -> URL {
        var destination: URL
        if let name {
            destination = directory.appending(path: name)
            guard !destination.exists else { updateProgress(1); return destination }
        }
        guard let downloadURL = try await getDownloadURL() else { throw HuggingFaceError.noFilteredURL }
        destination = directory.appending(path: downloadURL.lastPathComponent)
        guard !destination.exists else { return destination }
        try await downloadURL.downloadData(to: destination, updateProgress)
        return destination
    }

    /// Creates a HuggingFaceModel instance configured for the TinyLLaMA model.
    /// - Parameters:
    ///   - quantization: The quantization level to use. Defaults to `.Q4_K_M`.
    ///   - systemPrompt: The system prompt to use for the model.
    /// - Returns: A configured HuggingFaceModel instance.
    public static func tinyLLaMA(_ quantization: Quantization = .Q4_K_M, _ systemPrompt: String) -> HuggingFaceModel {
        HuggingFaceModel("TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF", quantization, template: .chatML(systemPrompt))
    }
}