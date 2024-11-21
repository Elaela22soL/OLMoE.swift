//
//  ChatView.swift
//  OLMoE.swift
//
//  Created by Stanley Jovel on 11/20/24.
//

import SwiftUI

public struct ChatBubble: View {
    var isUser: Bool
    var text: String

    public var body: some View {
        HStack {
            if isUser {
                Spacer()
            }

            Text(text)
                .padding(12)
                .background(isUser ? Color("Surface") : Color("BackgroundColor"))
                .cornerRadius(12)
                .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
                .font(.body())

            if !isUser {
                Spacer()
            }
        }
    }
}

public struct ChatView: View {
    public var history: [Chat]
    public var output: String

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 4) {
                // History
                ForEach(history, id: \.content) { chat in
                    if chat.content != output {
                        ChatBubble(
                            isUser: chat.role == .user,
                            text: chat.content
                        )
                    }
                }
                
                // Current output
                ChatBubble(
                    isUser: false,
                    text: output
                )
                .id("bottomID") // Unique ID for scrolling

                Color.clear.frame(height: 1).id("bottomID2")
            }
            .font(.body.monospaced())
            .foregroundColor(Color("TextColor"))
        }
        .preferredColorScheme(.dark)
    }
}

#Preview("ChatView") {
    let exampleOutput = "This is a bot response."
    let exampleHistory: [Chat] = [
        (role: .user, content: "Hi there!"),
        (role: .bot, content: "Hello! How can I help you?")
    ]

    ChatView(history: exampleHistory, output: exampleOutput)
}
