//
//  AppInfo.swift
//  OLMoE.swift
//
//  Created by Luca Soldaini on 2024-09-25.
//


import Foundation

struct AppInfo {
    static let shared = AppInfo()
    private init() {}

    var name: String {
        Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "Unknown"
    }

    var displayName: String {
        Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String ?? name
    }

    var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }

    var build: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }

    var appId: String {
        "\(name)_\(version)_\(build)"
    }
}
