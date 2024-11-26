//
//  SheetWrapperView.swift
//  OLMoE.swift
//
//  Created by Jon Ryser on 11/26/24.
//

import SwiftUI

struct SheetWrapper<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            Color("Surface") // Set the background color for the entire sheet
                .edgesIgnoringSafeArea(.all)
            VStack {
                content
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 24)
        }
    }
}

#Preview("Sheet Wrapper in Sheet Preview") {
    @Previewable @State var showSheet = true

    VStack {
        Button("Show Sheet") {
            showSheet.toggle()
        }
        .buttonStyle(.PrimaryButton)
        .sheet(isPresented: $showSheet) {
            SheetWrapper {
                VStack(spacing: 16) {
                    Text("Sheet Title")
                        .font(.title)
                        .foregroundColor(Color("TextColor"))

                    Text("This content is wrapped in the SheetWrapper and displayed in a sheet.")
                        .font(.body)
                        .padding()

                    Button("Close") {
                        showSheet = false
                    }
                    .buttonStyle(.PrimaryButton)
                }
            }
        }
    }
}
