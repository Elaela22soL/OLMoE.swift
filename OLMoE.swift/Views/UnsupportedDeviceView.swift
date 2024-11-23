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
            Image("Exclamation")
                .foregroundColor(Color("AccentColor"))

            Text("Device Not Supported")
                .font(.title())
                .foregroundColor(Color("AccentColor"))

            Text("This app requires a device with at least 8GB of RAM.")
                .multilineTextAlignment(.center)
                .padding([.horizontal], 32)
                .padding([.vertical], 2)
                .font(.body())

            if FeatureFlags.allowDeviceBypass {
                if availableMemoryInGB > 0 {
                    Text("(The model requires ~6 GB and this device has: \(formattedMemory) GB available.)")
                        .multilineTextAlignment(.center)
                        .padding()
                        .font(.body())
                }

                Button("Proceed Anyway") {
                    proceedAnyway()
                }
                .padding(.vertical, 5)
                .font(.body())
            }

            if FeatureFlags.allowMockedModel {
                Button("Proceed With Mocked Model") {
                    proceedMocked()
                }
                .padding(.vertical, 5)
                .font(.body())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("BackgroundColor"))
    }
}

#Preview("Unsupported Device View") {
    UnsupportedDeviceView(
        proceedAnyway: {
            print("Proceeding anyway")
        },
        proceedMocked: {
            print("Proceeding with mocked model")
        }
    )
    .preferredColorScheme(.dark)
    .padding()
    .background(Color("BackgroundColor"))
}