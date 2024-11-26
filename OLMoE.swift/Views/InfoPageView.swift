//
//  InfoPageView.swift
//  OLMoE.swift
//
//  Created by Thomas Jones on 11/14/24.
//

import SwiftUI

struct InfoButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "info.circle")
                .foregroundColor(Color("TextColor"))
        }
        .clipShape(Circle())
        .background(
            RadialGradient(
                gradient: Gradient(colors: [
                    Color("BackgroundColor").opacity(0.9), Color.clear,
                ]),
                center: .center,
                startRadius: 20,
                endRadius: 40)
        )
    }
}

struct InfoView: View {
    @Binding var isPresented: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Spacer()
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark.circle")
                        .font(.system(size: 20))
                        .frame(width: 40, height: 40)
                        .foregroundColor(Color("TextColor"))
                }
                .clipShape(Circle())
            }
            Ai2Logo()
                .frame(maxWidth: .infinity, alignment: .center)

            Text(.init(InfoText.body))
                .font(.body())
        }
        .onTapGesture {
            isPresented = false
        }
    }
}

#Preview("InfoView") {
    InfoView(isPresented: .constant(true))
}
