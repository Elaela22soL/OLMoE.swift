//
//  MessageInput.swift
//  OLMoE.swift
//
//  Created by Stanley Jovel on 11/19/24.
//

import SwiftUI

struct MessageInputView: View {
    @Binding var input: String
    @Binding var isGenerating: Bool
    @FocusState private var isTextEditorFocused: Bool
    
    let isInputDisabled: Bool
    let hasValidInput: Bool
    let respond: () -> Void
    let stop: () -> Void
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ZStack(alignment: .topLeading) {
                TextField("Message", text: $input, axis: .vertical)
                    .scrollContentBackground(.hidden)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color("Surface"))
                            .foregroundStyle(.thinMaterial)
                            .padding(-12)
                    )
                    .multilineTextAlignment(.leading)
                    .lineLimit(5)
                    .foregroundColor(Color("TextColor"))
                    .font(.system(size: 14, weight: .regular))
                    .focused($isTextEditorFocused)
                    .onChange(of: isTextEditorFocused) { _, isFocused in
                        if !isFocused {
                            hideKeyboard()
                        }
                    }
                    .disabled(isInputDisabled)
                    .opacity(isInputDisabled ? 0.6 : 1)
                    .padding(12)
            }
            
            VStack(spacing: 8) {
                ZStack {
                    if isGenerating {
                        Button(action: stop) {
                            Image(systemName: "stop.fill")
                        }
                    } else {
                        Button(action: respond) {
                            Image(systemName: "paperplane.fill")
                        }
                        .disabled(!hasValidInput)
                        .foregroundColor(hasValidInput ? Color("AccentColor") : Color("AccentColor").opacity(0.5))
                    }
                }
                .onTapGesture {
                    isTextEditorFocused = false
                }
                .font(.system(size: 24))
                .frame(width: 40, height: 40)
            }
        }
        .padding(.horizontal)
        .frame(maxWidth: .infinity)
    }
}
