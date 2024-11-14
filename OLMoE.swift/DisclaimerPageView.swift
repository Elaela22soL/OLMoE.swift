//
//  DisclaimerPageView.swift
//  OLMoE.swift
//
//  Created by Thomas Jones on 11/13/24.
//

import SwiftUI

struct DisclaimerPageData {
    let title: String
    let text: String
    let buttonText: String
}

// Placeholder disclaimer text displayed at app start
enum Disclaimer {
    static let pages = [
        
        DisclaimerPageData(title: "[TODO] Disclaimers",
                           text: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nullam odio urna, porta vel eleifend volutpat, porta vitae justo. Aenean sit amet sem id urna consectetur feugiat. Morbi in sem gravida orci rutrum maximus. Donec pretium accumsan orci quis elementum. Sed a tempor libero. Cras tempus nisl ut mattis pretium. Fusce in congue arcu. Vivamus nec sollicitudin est. Cras id eleifend nisl. Phasellus quis neque in leo accumsan fermentum et quis diam. Integer non lectus blandit, hendrerit ante sed, bibendum sapien. Etiam quis facilisis ante. Donec lacinia tincidunt est, quis volutpat est tincidunt et. Nullam nibh risus, tempor quis lacinia ac, dictum et arcu. Curabitur sit amet mauris id mi facilisis laoreet a non metus.",
                           buttonText: "Next"),
        
        DisclaimerPageData(title: "[TODO] Additional Disclaimers",
                           text: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nullam odio urna, porta vel eleifend volutpat, porta vitae justo. Aenean sit amet sem id urna consectetur feugiat. Morbi in sem gravida orci rutrum maximus. Donec pretium accumsan orci quis elementum. Sed a tempor libero. Cras tempus nisl ut mattis pretium. Fusce in congue arcu. Vivamus nec sollicitudin est. Cras id eleifend nisl. Phasellus quis neque in leo accumsan fermentum et quis diam. Integer non lectus blandit, hendrerit ante sed, bibendum sapien. Etiam quis facilisis ante. Donec lacinia tincidunt est, quis volutpat est tincidunt et. Nullam nibh risus, tempor quis lacinia ac, dictum et arcu. Curabitur sit amet mauris id mi facilisis laoreet a non metus.",
                           buttonText: "I Agree")
    ]
}

struct DisclaimerPage: View {
    typealias PageButton = (text: String, onDismiss: () -> Void)
    
    let title: String
    let message: String
    let confirm: PageButton
    
    var body: some View {
        VStack(spacing: 20) {
            
            Text(title)
                .font(.headline)
                .padding(.top, 20)
            
            Text(message)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            Button(confirm.text) {
                confirm.onDismiss()
            }
            .padding(.bottom, 20)
        }
    }
}
