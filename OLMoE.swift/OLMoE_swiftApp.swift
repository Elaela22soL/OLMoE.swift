//
//  OLMoE_swiftApp.swift
//  OLMoE.swift
//
//  Created by Luca Soldaini on 2024-09-16.
//

import SwiftUI

import UIKit

func isDeviceSupported() -> Bool {
    #if targetEnvironment(macCatalyst)
    return macHasEnoughRAM(minimumGB: 8) // Check RAM on Mac
    #else
    let deviceModel = UIDevice.current.modelName
    
    // Model identifiers for devices with 8GB of RAM or more (iPhones and iPads)
    let supportedModels = [
        // iPhone models with 8GB RAM
        "iPhone16,1", "iPhone16,2", "iPhone17,1", "iPhone17,2", "iPhone17,3", "iPhone17,4",
        
        // iPad models with 8GB or more RAM
        "iPad14,3", "iPad14,4", // iPad Pro 11" 4th Gen
        "iPad14,5", "iPad14,6", // iPad Pro 12.9" 6th Gen
        "iPad14,8", "iPad14,9", // iPad Air 6th Gen
        
        "iPad16,3", "iPad16,4", // iPad Pro 11" 5th Gen
        "iPad16,5", "iPad16,6", // iPad Pro 12.9" 7th Gen
    ]
    
    return supportedModels.contains(deviceModel)
    #endif
}

func macHasEnoughRAM(minimumGB: UInt64) -> Bool {
    let physicalMemory = ProcessInfo.processInfo.physicalMemory
    let minimumBytes = minimumGB * 1024 * 1024 * 1024 // Convert GB to bytes
    return physicalMemory >= minimumBytes
}

extension UIDevice {
    var modelName: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        return String(bytes: Data(bytes: &systemInfo.machine, count: Int(_SYS_NAMELEN)), encoding: .ascii)?.trimmingCharacters(in: .controlCharacters) ?? "unknown"
    }
}


@main
struct OLMoE_swiftApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var isSupportedDevice = isDeviceSupported()
    
    var body: some Scene {
        WindowGroup {
            if isSupportedDevice {
                ContentView()
                    .font(.manrope())
            } else {
                UnsupportedDeviceView() // A custom SwiftUI view for unsupported devices
            }
        }
    }
}


class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        print("Background URL session: \(identifier)")
        completionHandler()
    }
}
