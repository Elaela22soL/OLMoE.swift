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
                .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: .trailing)
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

            if isGenerating && text.isEmpty {
                TypingIndicator()
            } else {
                Text(text)
                    .padding(.top, -2)
                    .background(Color("BackgroundColor"))
                    .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: .leading)
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

struct ScrollState {
    static let BottomScrollThreshold = 40.0
    static let ScrollSpaceName: String = "scrollSpace"

    public var scrollViewHeight: CGFloat = 0
    public var contentHeight: CGFloat = 0
    public var scrollOffset: CGFloat = 0
    public var isAtBottom: Bool = true

    mutating func onScroll(scrollOffset: CGFloat) {
        self.scrollOffset = scrollOffset
        updateState()
    }

    mutating func onContentResized(contentHeight: CGFloat) {
        self.contentHeight = contentHeight
        updateState()
    }

    private mutating func updateState() {
        let needsScroll = contentHeight > scrollViewHeight
        let sizeDelta = contentHeight - scrollViewHeight
        let offsetDelta = abs(sizeDelta) + scrollOffset
        let isAtBottom = !needsScroll || offsetDelta < ScrollState.BottomScrollThreshold
        self.isAtBottom = isAtBottom
    }
}

public struct ChatView: View {
    public static let BottomID = "bottomID"

    public var history: [Chat]
    public var output: String
    @Binding var isGenerating: Bool
    @Binding var isScrolledToBottom: Bool
    @State private var contentHeight: CGFloat = 0
    @State private var newHeight: CGFloat = 0
    @State private var previousHeight: CGFloat = 0
    @State private var outerHeight: CGFloat = 0
    @State private var scrollState = ScrollState()
    @State private var lastAdjustedUserCount: Int = 0
    @StateObject private var keyboardResponder = KeyboardResponder()

    public var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        // History
                        ForEach(history) { chat in
                            if !chat.content.isEmpty {
                                switch chat.role {
                                    case .user:
                                        UserChatBubble(text: chat.content)
                                            .id(chat.id)
                                    case .bot:
                                        BotChatBubble(text: chat.content)
                                }
                            }
                        }

                        // Current output
                        if isGenerating {
                            BotChatBubble(text: output, isGenerating: isGenerating)
                        }

                        Color.clear.frame(height: 1).id(ChatView.BottomID)
                    }
                    .font(.body.monospaced())
                    .foregroundColor(Color("TextColor"))
                    .background(scrollTracker())
                    .frame(minHeight: newHeight, alignment: .top)
                }
                .background(scrollHeightTracker())
                .coordinateSpace(name: ScrollState.ScrollSpaceName)
                .preferredColorScheme(.dark)
                .onChange(of: history) { oldHistory, newHistory in
                    if let lastMessage = getLatestUserChat() {
                        if oldHistory.count < newHistory.count && lastMessage.role == .user {
                            let userMessagesCount = newHistory.filter { $0.role == .user }.count

                            // Only adjust height if this is a new user message count we haven't handled yet
                            if userMessagesCount > 1 && userMessagesCount > lastAdjustedUserCount {
                                // Set new height based on current content plus outer height
                                self.newHeight = self.contentHeight + self.outerHeight
                                self.lastAdjustedUserCount = userMessagesCount
                            }

                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                withAnimation {
                                    proxy.scrollTo(lastMessage.id, anchor: .top)
                                }
                            }
                        }
                    }
                }
                .onChange(of: keyboardResponder.keyboardHeight) { oldKeyboardHeight, newKeyboardHeight in
                    self.previousHeight = self.newHeight
                    self.contentHeight = scrollState.contentHeight
                    let keyboardIsVisible = newKeyboardHeight > 0
                    if keyboardIsVisible {
                        let newHeight = self.newHeight - newKeyboardHeight
                        self.newHeight = max(newHeight, self.outerHeight)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation {
                                proxy.scrollTo(ChatView.BottomID, anchor: .bottom)
                            }
                        }
                    } else {
                        self.newHeight = self.previousHeight
                    }
                }
            }
            .onAppear {
                self.outerHeight = geometry.size.height
            }
        }
    }

    @ViewBuilder
    private func scrollTracker() -> some View {
        GeometryReader { geo in
            Color.clear
                .onChange(of: geo.frame(in: .named(ScrollState.ScrollSpaceName)).origin.y) { _, offset in
                    scrollState.onScroll(scrollOffset: offset)
                    isScrolledToBottom = scrollState.isAtBottom
                }
                .onAppear {
                    scrollState.onContentResized(contentHeight: geo.size.height)
                }
                .onChange(of: geo.size.height) { _, newHeight in
                    scrollState.onContentResized(contentHeight: newHeight)
                    isScrolledToBottom = scrollState.isAtBottom
                }
        }
    }

    @ViewBuilder
    private func scrollHeightTracker() -> some View {
        GeometryReader { proxy in
            Color.clear
                .onAppear {
                    scrollState.scrollViewHeight = proxy.size.height
                }
                .onChange(of: proxy.size.height) { _, newHeight in
                    scrollState.scrollViewHeight = newHeight
                }
        }
    }

    private func getLatestUserChat() -> Chat? {
        return self.history.last(where: { $0.role == .user })
    }
}

#Preview("Replying") {
    let exampleOutput = "This is a bot response that spans multiple lines to better test spacing and alignment in the chat view during development previews in Xcode. This is a bot response that spans multiple lines to better test spacing and alignment in the chat view during development previews in Xcode."
    let exampleHistory: [Chat] = [
        Chat(role: .user, content: "Hi there!"),
        Chat(role: .bot, content: "Hello! How can I help you?"),
        Chat(role: .user, content: "Give me a very long answer (this question has a whole lot of text!)"),
    ]

    ChatView(
        history: exampleHistory,
        output: exampleOutput,
        isGenerating: .constant(true),
        isScrolledToBottom: .constant(true)
    )
    .padding(12)
    .background(Color("BackgroundColor"))
}

#Preview("Thinking") {
    let exampleOutput = ""
    let exampleHistory: [Chat] = [
        Chat(role: .user, content: "Hi there!"),
        Chat(role: .bot, content: "Hello! How can I help you?"),
        Chat(role: .user, content: "Give me a very long answer"),
    ]

    ChatView(
        history: exampleHistory,
        output: exampleOutput,
        isGenerating: .constant(true),
        isScrolledToBottom: .constant(true)
    )
    .padding(12)
    .background(Color("BackgroundColor"))
}

#Preview("BotChatBubble") {
    BotChatBubble(text: "Welcome chat message")
}

#Preview("UserChatBubble") {
    UserChatBubble(text: "Hello Ai, please help me with your knowledge.")
}
