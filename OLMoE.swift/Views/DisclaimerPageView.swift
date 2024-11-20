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
    @Binding var isPresented: Bool

    init(title: String,
         message: String,
         isPresented: Binding<Bool>,
         confirm: PageButton,
         cancel: PageButton? = nil) {
        self.title = title
        self.message = message
        self._isPresented = isPresented
        self.confirm = confirm
        self.cancel = cancel
    }

    var body: some View {
        ModalView(
            isPresented: $isPresented,
            showCloseButton: false,
            allowOutsideTapDismiss: false
        ) {
            VStack(spacing: 20) {
                Text(title)
                    .font(.modalTitle())
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(.modalBody())
                    .padding(.horizontal, 20)

                VStack(spacing: 12) {
                    Button(confirm.text) {
                        confirm.onTap()
                    }
                    .font(.modalButton())
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(8)

                if let cancel = cancel {
                        Button(cancel.text) {
                            cancel.onTap()
                        }
                        .font(.modalButton())
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color("BackgroundColor"))
                        .foregroundColor(Color("TextColor"))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}
