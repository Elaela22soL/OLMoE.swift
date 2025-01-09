//
//  Typography.swift
//  OLMoE.swift
//
//  Created by Jon Ryser on 2024-11-20.
//


import SwiftUI

extension Font {
    static func title() -> Font {
        .telegraf(.medium, size: 24)
    }

    static func body() -> Font {
        .manrope(.medium, size: 17)
    }

    static func subheader() -> Font {
        .manrope(.medium, size: 22)
    }
}
