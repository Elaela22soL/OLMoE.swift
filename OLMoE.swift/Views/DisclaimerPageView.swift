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
                
                HStack(spacing: 12) {
                    if let cancel = cancel {
                        Button(cancel.text) {
                            cancel.onTap()
                        }
                        .buttonStyle(.SecondaryButton)
                    }
                    
                    Button(confirm.text) {
                        confirm.onTap()
                    }
                    .buttonStyle(.PrimaryButton)
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

#Preview("DisclaimerPage") {
    DisclaimerPage(
        title: "Title",
        message: "Message",
        isPresented: .constant(true),
        confirm: (text: "Confirm", onTap: { print("Confirmed") }),
        cancel: (text: "Cancel", onTap: { print("Cancelled") })
    )
}
