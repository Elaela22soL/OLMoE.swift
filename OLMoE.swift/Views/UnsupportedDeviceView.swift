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

    @State private var mockedModelButtonWidth: CGFloat = 100
    @State private var notSupportedWidth: CGFloat = 100

    var body: some View {
        let availableMemoryInGB = Double(os_proc_available_memory()) / (1024 * 1024 * 1024)
        let formattedMemory = String(format: "%.2f", availableMemoryInGB)

        VStack {
            Image("Exclamation")
                .foregroundColor(Color("AccentColor"))

            Text("Device Not Supported")
                .id(UUID()) // Force unique ID so onAppear gets updated width
                .font(.title())
                .foregroundColor(Color("AccentColor"))
                .background(GeometryReader { geometry in
                    Color.clear.onAppear {
                        notSupportedWidth = geometry.size.width + 24
                    }
                })

            Text("This app requires a device with at least 8GB of RAM.")
                .frame(width: notSupportedWidth)
                .multilineTextAlignment(.center)
                .padding([.horizontal], 32)
                .padding([.vertical], 2)
                .font(.body())

            if FeatureFlags.allowDeviceBypass {
                if availableMemoryInGB > 0 {
                    Text("(The model requires ~6 GB and this device has: \(formattedMemory) GB available.)")
                        .frame(width: notSupportedWidth)
                        .multilineTextAlignment(.center)
                        .padding()
                        .font(.body())
                }

                Button("Proceed Anyway") {
                    proceedAnyway()
                }
                .buttonStyle(PrimaryButton(minWidth: mockedModelButtonWidth))
                .padding(.vertical, 5)
            }

            if FeatureFlags.allowMockedModel {
                Button("Proceed With Mocked Model") {
                    proceedMocked()
                }
                .id(UUID()) // Force unique ID so onAppear gets updated width
                .buttonStyle(.PrimaryButton)
                .padding(.vertical, 5)
                .background(GeometryReader { geometry in
                    Color.clear.onAppear {
                        mockedModelButtonWidth = geometry.size.width - 24
                    }
                })
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
    .background(Color("BackgroundColor"))
}
