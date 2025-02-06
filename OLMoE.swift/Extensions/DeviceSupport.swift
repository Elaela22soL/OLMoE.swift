//
//  DeviceSupport.swift
//  OLMoE.swift
//
//  Created by Ken Adamson on 11/15/24.
//


import SwiftUI
import os

// Device support check function
func isDeviceSupported() -> Bool {
    #if targetEnvironment(simulator)
    return true
    #else
    let deviceModel = UIDevice.current.modelName

    // Model identifiers for devices with 8GB of RAM or more (iPhones and iPads)
    let supportedModels = [
        // iPhone models with 8GB RAM
        "iPhone16,1", "iPhone16,2", // iPhone 15 Pro and Pro Max
        "iPhone17,1", "iPhone17,2", "iPhone17,3", "iPhone17,4", // all iPhone 16 models

        // iPad models with 8GB or more RAM
        "iPad14,3", "iPad14,4", // iPad Pro 11" 4th Gen
        "iPad14,5", "iPad14,6", // iPad Pro 12.9" 6th Gen
        "iPad16,3", "iPad16,4", // iPad Pro 11" 5th Gen
        "iPad16,5", "iPad16,6", // iPad Pro 12.9" 7th Gen
        "iPad13,16", "iPad13,17", // iPad Air 5th Gen
        "iPad14,8", "iPad14,9", // iPad Air 6th Gen
        "iPad15,1", "iPad15,2", // Hypothetical future iPad models with 8GB RAM
    ]

    return supportedModels.contains(deviceModel)
    #endif
}

#if canImport(UIKit)
import UIKit

extension UIDevice {
    var modelName: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        return String(bytes: Data(bytes: &systemInfo.machine, count: Int(_SYS_NAMELEN)), encoding: .ascii)?.trimmingCharacters(in: .controlCharacters) ?? "unknown"
    }
}
#endif

// SwiftUI View for unsupported devices

