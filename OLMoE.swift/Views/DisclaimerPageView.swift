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

struct DisclaimerPage: View {
    typealias PageButton = (text: String, onTap: () -> Void)
    
    let title: String
    let message: String
    let confirm: PageButton
    let cancel: PageButton?
    
    init(title: String, message: String, confirm: PageButton, cancel: PageButton? = nil) {
        self.title = title
        self.message = message
        self.confirm = confirm
        self.cancel = cancel
    }
    
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
                confirm.onTap()
            }
            .padding(.vertical, 5)
            
            if let cancel = cancel {
                Button(cancel.text) {
                    cancel.onTap()
                }
                .padding(.vertical, 5)
            }
        }
    }
}
