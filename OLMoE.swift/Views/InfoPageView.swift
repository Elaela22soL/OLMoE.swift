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
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {

                    Ai2Logo()
                        .frame(maxWidth: .infinity, alignment: .center)
                                 
                    Text(.init(InfoText.body))
                        .font(.body())
                        .padding(.horizontal)
                }
                .padding()
            }
            .background(Color("BackgroundColor"))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle")
                            .font(.system(size: 20))
                            .frame(width: 40, height: 40)
                            .foregroundColor(Color("TextColor"))
                    }
                    .clipShape(Circle())
                }
            }.toolbarBackground(
                Color("BackgroundColor"), for: .navigationBar
            )
        }
    }
}

#Preview("InfoView") {
    InfoView()
}
