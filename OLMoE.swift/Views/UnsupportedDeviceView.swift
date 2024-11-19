//
//  UnsupportedDeviceView.swift
//  OLMoE.swift
//
//  Created by Ken Adamson on 11/17/24.
//


import SwiftUI
import os
import UIKit

struct UnsupportedDeviceView: View {
    
    let proceedAnyway: () -> Void
    let proceedMocked: () -> Void
    
    var body: some View {
        let availableMemoryInGB = Double(os_proc_available_memory()) / (1024 * 1024 * 1024)
        let formattedMemory = String(format: "%.2f", availableMemoryInGB)
        
        VStack {
            Text("Device Not Supported")
                .font(.telegraf(textStyle: .title))
                .padding()
            Text("This app requires a device with at least 8GB of RAM.")
                .multilineTextAlignment(.center)
                .padding()
            
            if availableMemoryInGB > 0 {
                Text("(The model requires ~4 GB and this device has: \(formattedMemory) GB available.)")
                    .multilineTextAlignment(.center)
                    .padding()
            }
            
            if FeatureFlags.allowDeviceBypass {
                Button("Proceed Anyway") {
                    proceedAnyway()
                }
                .padding(.vertical, 5)
            }
            if FeatureFlags.allowMockedModel {
                Button("Proceed With Mocked Model") {
                    proceedMocked()
                }
                .padding(.vertical, 5)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("BackgroundColor"))
    }
}
