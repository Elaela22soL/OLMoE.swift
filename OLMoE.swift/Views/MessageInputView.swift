//
//  MessageInputView.swift
//  OLMoE.swift
//
//  Created by Stanley Jovel on 11/19/24.
//

import SwiftUI

struct MessageInputView: View {
    @Binding var input: String
    @Binding var isGenerating: Bool
    @FocusState.Binding var isTextEditorFocused: Bool
    let isInputDisabled: Bool
    let hasValidInput: Bool
    let respond: () -> Void
    let stop: () -> Void
    
    var body: some View {
        HStack(alignment: .top) {
            TextField("Message", text: $input, axis: .vertical)
                .scrollContentBackground(.hidden)
                .multilineTextAlignment(.leading)
                .lineLimit(10)
                .foregroundColor(Color("TextColor"))
                .font(.body())
                .focused($isTextEditorFocused)
                .onChange(of: isTextEditorFocused) { _, isFocused in
                    if !isFocused {
                        hideKeyboard()
                    }
                }
                .disabled(isInputDisabled)
                .opacity(isInputDisabled ? 0.6 : 1)
                .padding(12)
            
            ZStack {
                if isGenerating {
                    Button(action: stop) {
                        Image("StopIcon")
                    }
                } else {
                    Button(action: respond) {
                        Image("SendIcon")
                    }
                    .disabled(!hasValidInput)
                    .opacity(hasValidInput ? 1 : 0.5)

                }
            }
            .onTapGesture {
                isTextEditorFocused = false
            }
            .font(.system(size: 24))
            .frame(width: 40, height: 40)
            .padding(.top, 2)
            .padding(.trailing, 4)
            
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color("Surface"))
                .foregroundStyle(.thinMaterial)
        )
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    @FocusState var isTextEditorFocused: Bool
    
    MessageInputView(
        input: .constant("Message"),
        isGenerating: .constant(false),
        isTextEditorFocused: $isTextEditorFocused,
        isInputDisabled: false,
        hasValidInput: true,
        respond: {
            print("Send")
        },
        stop: {
            print("Stop")
        }
    )
    .preferredColorScheme(.dark)
}
