//
//  TelegrafFont.swift
//  OLMoE.swift
//
//  Created by Stanley Jovel on 11/18/24.
//

import SwiftUI

extension Font {
    static func telegraf(_ weight: Weight = .regular, textStyle: TextStyle = .body) -> Font {
        custom("PP Telegraf", size: UIFont.preferredFont(forTextStyle: textStyle.uiTextStyle).pointSize)
            .weight(weight)
    }
    
    static func telegraf(_ weight: Weight = .regular, size: CGFloat) -> Font {
        custom("PP Telegraf", size: size)
            .weight(weight)
    }
    
}
