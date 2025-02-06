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
    @State private var showWebView = false
    let proceedAnyway: () -> Void
    let proceedMocked: () -> Void

    @State private var mockedModelButtonWidth: CGFloat = 100
    @State private var notSupportedWidth: CGFloat = 100

    var body: some View {
        let availableMemoryInGB = Double(os_proc_available_memory()) / (1024 * 1024 * 1024)
        let formattedMemory = String(format: "%.2f", availableMemoryInGB)

        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 20) {
                    Image("Exclamation")
                        .foregroundColor(Color("AccentColor"))

                    Text("On-Device OLMoE Not Available")
                        .id(UUID())
                        .font(.title())
                        .foregroundColor(Color("AccentColor"))
                        .background(GeometryReader { geometry in
                            Color.clear.onAppear {
                                notSupportedWidth = geometry.size.width + 24
                            }
                        })
                        .multilineTextAlignment(.center)

                    Text("This device does not have the 8GB physical RAM required to run OLMoE locally.")
                        .multilineTextAlignment(.center)
                        .font(.body())

                    Text("OLMoE can run locally on iPhone 15 Pro/Max, iPhone 16 models, iPad Pro 4th Gen and newer, or iPad Air 5th Gen and newer.")
                        .multilineTextAlignment(.center)
                        .font(.body())

                    Text("However, you can try using OLMoE at the Ai2 Playground. This option does not download the model file to your device, but instead submits user input to a hosted version of OLMoE to remotely generate responses.")
                        .multilineTextAlignment(.center)
                        .font(.body())

                    Button("Try OLMoE at the Ai2 Playground") {
                        showWebView = true
                    }
                    .buttonStyle(PrimaryButton(minWidth: mockedModelButtonWidth))
                    .padding(.top, 12)
                    .sheet(isPresented: $showWebView, onDismiss: nil) {
                        SheetWrapper {
                            WebViewWithBanner(
                                url: URL(string: "https://playground.allenai.org/?model=olmoe-0125")!,
                                onDismiss: { showWebView = false }
                            )
                        }
                        .interactiveDismissDisabled(false)
                    }

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
                        .id(UUID())
                        .buttonStyle(.PrimaryButton)
                        .padding(.vertical, 5)
                        .background(GeometryReader { geometry in
                            Color.clear.onAppear {
                                mockedModelButtonWidth = geometry.size.width - 24
                            }
                        })
                    }

                }
                .frame(minHeight: geometry.size.height)
                .frame(maxWidth: 512)
                .padding(.horizontal, 24)
            }
            .frame(maxWidth: .infinity)
            .frame(height: geometry.size.height)
        }
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
