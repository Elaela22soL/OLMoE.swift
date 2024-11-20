//
//  ButtonStyles.swift
//  OLMoE.swift
//
//  Created by Stanley Jovel on 11/20/24.
//

import SwiftUI

struct PrimaryButton: ButtonStyle {
    func makeBody(configuration: ButtonStyle.Configuration) -> some View {
        configuration.label
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .background(Color.accentColor)
            .cornerRadius(12)
            .font(.manrope(size: 14))
            .fontWeight(.semibold)
            .foregroundColor(Color("TextColorButton"))
            .frame(maxWidth: .infinity)
    }
}

extension ButtonStyle where Self == PrimaryButton {
    static var PrimaryButton: Self {
        .init()
    }
}

struct SecondaryButton: ButtonStyle {
    func makeBody(configuration: ButtonStyle.Configuration) -> some View {
        configuration.label
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .background(Color.background)
            .cornerRadius(12)
            .font(.manrope(size: 14))
            .fontWeight(.semibold)
            .foregroundColor(Color("AccentColor"))
            .frame(maxWidth: .infinity)
            .preferredColorScheme(.dark)
    }
}

extension ButtonStyle where Self == SecondaryButton {
    static var SecondaryButton: Self {
        .init()
    }
}


#Preview("Primary") {
    Button("Button") { print("Tapped") }
        .buttonStyle(.PrimaryButton)
}

#Preview("Secondary") {
    Button("Button") { print("Tapped") }
        .buttonStyle(.SecondaryButton)
}


