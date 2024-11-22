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
                .padding()
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

    init(isPresented: Binding<Bool>) {
        self._isPresented = isPresented
    }

    var body: some View {
        ModalView(
            isPresented: $isPresented,
            allowOutsideTapDismiss: true,
            showCloseButton: true
        ) {
            VStack(alignment: .leading, spacing: 16) {
                Ai2Logo()
                    .frame(maxWidth: .infinity, alignment: .center)

                Text(.init(InfoText.body))
                    .font(.body())
            }
        }
    }
}

#Preview("InfoView") {
    InfoView(isPresented: .constant(true))
}
