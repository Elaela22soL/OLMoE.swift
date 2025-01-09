//
//  SpinnerView.swift
//  OLMoE.swift
//
//  Created by Jon Ryser on 11/13/24.
//


import SwiftUI

struct SpinnerView: View {
    let color: Color
    let size: CGFloat
    @State private var isAnimating = false

    init(color: Color = .accentColor, size: CGFloat = 24) {
        self.color = color
        self.size = size
    }

    var body: some View {
        Circle()
            .trim(from: 0, to: 0.7)
            .stroke(color, style: StrokeStyle(lineWidth: size/8, lineCap: .round))
            .frame(width: size, height: size)
            .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
            .animation(
                Animation.linear(duration: 1)
                    .repeatForever(autoreverses: false),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}

#Preview {
    VStack(spacing: 20) {
        SpinnerView()
        SpinnerView(color: .red, size: 40)
        SpinnerView(color: .blue, size: 60)
    }
    .padding()
}
