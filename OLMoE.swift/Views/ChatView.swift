//
//  ChatView.swift
//  OLMoE.swift
//
//  Created by Stanley Jovel on 11/20/24.
//

import SwiftUI

public struct UserChatBubble: View {
    var text: String

    public var body: some View {
        HStack(alignment: .top) {
            Spacer()

            Text(text.trimmingCharacters(in: .whitespacesAndNewlines))
                .padding(12)
                .background(Color("Surface"))
                .cornerRadius(12)
                .frame(maxWidth: 296, alignment: .trailing)
                .font(.body())
        }
    }
}

public struct BotChatBubble: View {
    var text: String
    var isGenerating: Bool = false

    public var body: some View {
        HStack(alignment: .top, spacing: 6) {
            
            Image("BotProfilePicture")
                .resizable()
                .frame(width: 20, height: 20)
                .padding(4)
                .background(Color("Surface"))
                .clipShape(Circle())
            
            if isGenerating && text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                TypingIndicator()
            } else {
                Text(text.trimmingCharacters(in: .whitespacesAndNewlines))
                    .padding(.top, -2)
                    .background(Color("BackgroundColor"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.body())
            }

            Spacer()
        }
    }
}

public struct TypingIndicator: View {
    @State private var dotCount = 0

    public var body: some View {
        HStack() {
            Text(String(repeating: ".", count: dotCount))
        }
        .onAppear {
            // Animate dots
            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                self.dotCount = (self.dotCount + 1) % 4 // Cycle through 0-3 dots
            }
        }
    }
}


public struct ChatView: View {
    public var history: [Chat]
    public var output: String
    @Binding var isGenerating: Bool

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                // History
                ForEach(history, id: \.content) { chat in
                    if chat.content != output {
                        switch chat.role {
                        case .user:
                            UserChatBubble(text: chat.content)
                        case .bot:
                            BotChatBubble(text: chat.content)
                        }
                    }
                }
                
                // Current output
                BotChatBubble(text: output, isGenerating: isGenerating)
                .id("bottomID") // Unique ID for scrolling

                Color.clear.frame(height: 1).id("bottomID2")
            }
            .font(.body.monospaced())
            .foregroundColor(Color("TextColor"))
        }
        .preferredColorScheme(.dark)
    }
}

#Preview("Replying") {
    let exampleOutput = "This is a bot response that spans multiple lines to better test spacing and alignment in the chat view during development previews in Xcode. This is a bot response that spans multiple lines to better test spacing and alignment in the chat view during development previews in Xcode."
    let exampleHistory: [Chat] = [
        (role: .user, content: "Hi there!"),
        (role: .bot, content: "Hello! How can I help you?"),
        (role: .user, content: "Give me a very long answer (this question has a whole lot of text!)"),
    ]

    ChatView(
        history: exampleHistory,
        output: exampleOutput,
        isGenerating: .constant(true)
    )
    .padding(12)
    .background(Color("BackgroundColor"))
}

#Preview("Thinking") {
    let exampleOutput = ""
    let exampleHistory: [Chat] = [
        (role: .user, content: "Hi there!"),
        (role: .bot, content: "Hello! How can I help you?"),
        (role: .user, content: "Give me a very long answer"),
    ]

    ChatView(
        history: exampleHistory,
        output: exampleOutput,
        isGenerating: .constant(true)
    )
    .padding(12)
    .background(Color("BackgroundColor"))
}
