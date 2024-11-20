//
//  DisclaimerPageView.swift
//  OLMoE.swift
//
//  Created by Thomas Jones on 11/13/24.
//

import SwiftUI

struct DisclaimerHandlers {
    var setActiveDisclaimer: (Disclaimer?) -> Void
    var setConfirmAction: (@escaping () -> Void) -> Void
    var setCancelAction: ((() -> Void)?) -> Void
}

class DisclaimerState: ObservableObject {
#if DEBUG
    @Published private var hasSeenDisclaimer: Bool = false
#else
    @AppStorage("hasSeenDisclaimer") private var hasSeenDisclaimer : Bool = false
#endif
    @Published var showDisclaimerPage : Bool = false
    @Published var activeDisclaimer: Disclaimer? = nil
    var onConfirm: (() -> Void)?
    var onCancel: (() -> Void)?
    private var disclaimerPageIndex: Int = 0
    
    let disclaimers: [Disclaimer] = [
        Disclaimers.LimitationDisclaimer(),
        Disclaimers.PrivacyDisclaimer(),
        Disclaimers.AcknowledgementDisclaimer()
    ]
    
    func showInitialDisclaimer() {
        if !hasSeenDisclaimer {
            activeDisclaimer = disclaimers[disclaimerPageIndex]
            onCancel = nil
            onConfirm = nextDisclaimerPage
            showDisclaimerPage = true
        }
    }

    private func nextDisclaimerPage() {
        disclaimerPageIndex += 1
        if disclaimerPageIndex >= disclaimers.count {
            activeDisclaimer = nil
            disclaimerPageIndex = 0
            onConfirm = nil
            showDisclaimerPage = false
            hasSeenDisclaimer = true
        } else {
            activeDisclaimer = disclaimers[disclaimerPageIndex]
            onConfirm = nextDisclaimerPage
            onCancel = nil
            showDisclaimerPage = true
        }
    }
}

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

                Text(.init(message))
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
