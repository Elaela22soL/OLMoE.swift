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
    
    func getDownloadURLStrings() async throws -> [String] {
        let url = URL(string: "https://huggingface.co/\(name)/tree/main")!
        let data = try await url.getData()
        let content = String(data: data, encoding: .utf8)!
        let downloadURLPattern = #"(?<=href=").*\.gguf\?download=true"#
        let matches = try! downloadURLPattern.matches(in: content)
        let root = "https://huggingface.co"
        return matches.map { match in root + match }
    }

    func getDownloadURL() async throws -> URL? {
        let urlStrings = try await getDownloadURLStrings()
        for urlString in urlStrings {
            let found = try filterRegexPattern.hasMatch(in: urlString)
            if found { return URL(string: urlString)! }
        }
        return nil
    }
    
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
    
    public static func tinyLLaMA(_ quantization: Quantization = .Q4_K_M, _ systemPrompt: String) -> HuggingFaceModel {
        HuggingFaceModel("TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF", quantization, template: .chatML(systemPrompt))
    }
}