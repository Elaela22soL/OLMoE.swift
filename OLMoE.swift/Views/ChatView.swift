//
//  ChatView.swift
//  OLMoE.swift
//
//  Created by Stanley Jovel on 11/20/24.
//

import SwiftUI
import MarkdownUI

public struct UserChatBubble: View {
    var text: String
    var maxWidth: CGFloat

    public var body: some View {
        HStack(alignment: .top) {
            Spacer()
            Text(text.trimmingCharacters(in: .whitespacesAndNewlines))
                .padding(12)
                .background(Color("Surface"))
                .cornerRadius(12)
                .frame(maxWidth: maxWidth * 0.75, alignment: .trailing)
                .font(.body())
        }
    }
}

public struct BotChatBubble: View {
    var text: String
    var maxWidth: CGFloat
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
                Markdown(text)
                    .padding(.top, -2)
                    .background(Color("BackgroundColor"))
                    .frame(maxWidth: maxWidth * 0.75, alignment: .leading)
                    .font(.body())
                    .markdownTextStyle(\.code) {
                        FontFamilyVariant(.monospaced)
                        FontSize(.em(0.85))
                        BackgroundColor(Color("Surface").opacity(0.35))
                    }
                    .markdownBlockStyle(\.codeBlock) { configuration in
                        configuration.label
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color("Surface").opacity(0.35))
                            .markdownTextStyle {
                                FontFamilyVariant(.monospaced)
                                FontSize(.em(0.85))
                            }
                            .markdownMargin(top: 8, bottom: 8)
                    }
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

    public var contentHeight: CGFloat = 0
    public var isAtBottom: Bool = true
    public var scrollOffset: CGFloat = 0
    public var scrollViewHeight: CGFloat = 0

    mutating func onContentResized(contentHeight: CGFloat) {
        self.contentHeight = contentHeight
        updateState()
    }

    mutating func onScroll(scrollOffset: CGFloat) {
        self.scrollOffset = scrollOffset
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
    @Binding var stopSubmitted: Bool

    @State private var contentHeight: CGFloat = 0
    @State private var newHeight: CGFloat = 0
    @State private var outerHeight: CGFloat = 0
    @State private var scrollState = ScrollState()

    @StateObject private var keyboardResponder = KeyboardResponder()

    public var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { proxy in
                ScrollView {
                    chatContent(proxy, parentWidth: geometry.size.width)
                }
                .background(scrollHeightTracker())
                .coordinateSpace(name: ScrollState.ScrollSpaceName)
                .onChange(of: history) { _, newHistory in
                    handleHistoryChange(newHistory, proxy)
                }
                .onChange(of: stopSubmitted) { _, _ in
                    self.newHeight = scrollState.contentHeight
                }
                .onChange(of: keyboardResponder.keyboardHeight) { _, newHeight in
                    handleKeyboardChange(newHeight, proxy)
                }
                .preferredColorScheme(.dark)
            }
            .onAppear {
                self.outerHeight = geometry.size.height
            }
        }
    }

    @ViewBuilder
    private func chatContent(_ proxy: ScrollViewProxy, parentWidth: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(Array(history.enumerated()), id: \.element.id) { index, chat in
                if !chat.content.isEmpty {
                    chatBubble(for: chat, at: index, parentWidth: parentWidth)
                }
            }

            generatingBubble(parentWidth: parentWidth)
            Color.clear.frame(height: 1).id(ChatView.BottomID)
        }
        .font(.body.monospaced())
        .foregroundColor(Color("TextColor"))
        .background(scrollTracker())
        .frame(minHeight: self.newHeight, alignment: .top)
    }

    @ViewBuilder
    private func chatBubble(for chat: Chat, at index: Int, parentWidth: CGFloat) -> some View {
        Group {
            switch chat.role {
                case .user:
                    UserChatBubble(text: chat.content, maxWidth: parentWidth)
                        .id(chat.id)
                case .bot:
                    BotChatBubble(text: chat.content, maxWidth: parentWidth)
            }
        }
    }

    @ViewBuilder
    private func generatingBubble(parentWidth: CGFloat) -> some View {
        if isGenerating {
            BotChatBubble(text: output, maxWidth: parentWidth, isGenerating: isGenerating)
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

    private func getLatestUserChat() -> Chat? {
        return getUserChats(history: self.history).last
    }

    private func getUserChats(history: [Chat]) -> [Chat] {
        return history.filter { $0.role == .user }
    }

    private func handleHistoryChange(_ newHistory: [Chat], _ proxy: ScrollViewProxy) {
        if let lastMessage = getLatestUserChat() {
            let newMessagesCount = getUserChats(history: newHistory).count
            if newMessagesCount > 1 {
                // Set new height based on current content plus outer height
                self.newHeight = self.contentHeight + self.outerHeight

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation {
                        proxy.scrollTo(lastMessage.id, anchor: .top)
                    }
                }
            }
        }
    }

    private func handleKeyboardChange(_ newKeyboardHeight: CGFloat, _ proxy: ScrollViewProxy) {
        self.contentHeight = scrollState.contentHeight
        if newKeyboardHeight > 0 {
            let newHeight = self.newHeight - newKeyboardHeight
            self.newHeight = max(newHeight, self.outerHeight)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                withAnimation {
                    proxy.scrollTo(ChatView.BottomID, anchor: .bottom)
                }
            }
        }
    }
}

#Preview("Markdown Features") {
    let exampleHistory: [Chat] = [
        Chat(role: .user, content: "Show me what markdown features you support"),
        Chat(role: .bot, content: """
        # Markdown Showcase
        Let me demonstrate the various markdown features I support:

        ## Text Formatting
        You can use **bold**, *italic*, or ***both***. You can also ~~strikethrough~~ text.

        ## Code Examples
        Here's a code sample:
        ```swift
        struct Example {
            let value: String
            func process() -> String {
                return "Processed: \\(value)"
            }
        }
        ```
        You can also use `inline code` or ``nested `backticks` ``.

        ## Lists and Tasks
        Here's what I can do:
        1. Ordered lists
           * Nested bullets
             * Deep nesting

        And task lists:
        - [x] Completed task
        - [ ] Pending task
          - [x] Nested task
        """),

        Chat(role: .user, content: "That's cool! What about tables and quotes?"),
        Chat(role: .bot, content: """
        ## Tables
        | Feature | Support | Notes |
        |---------|:-------:|-------|
        | Tables  | ✅ | With alignment |
        | Lists   | ✅ | Nested too |

        ## Blockquotes
        > Single quote
        >> Nested quote
        >>> Triple nested with **bold** and *italic*

        ## Links and References
        [External Link](https://example.com)
        <https://auto-link.com>

        Reference-style [link][ref] and footnotes[^1]

        [^1]: This is a footnote
        [ref]: https://example.com
        """),

        Chat(role: .user, content: "Any special features?"),
        Chat(role: .bot, content: """
        ## Special Elements
        <details>
        <summary>Expandable Section</summary>

        * Hidden content
        * More items
        </details>

        ## Math and Diagrams
        Math: $E = mc^2$

        ```mermaid
        graph TD;
            A-->B;
            B-->C;
            C-->D;
        ```

        ## Definition Lists
        Term 1
        : First definition
        : Another definition

        Term 2
        : With nested list
          * Item 1
          * Item 2
        """)
    ]

    ChatView(
        history: exampleHistory,
        output: "",
        isGenerating: .constant(false),
        isScrolledToBottom: .constant(true),
        stopSubmitted: .constant(false)
    )
    .padding(12)
    .background(Color("BackgroundColor"))
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
        isScrolledToBottom: .constant(true),
        stopSubmitted: .constant(false)
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
        isScrolledToBottom: .constant(true),
        stopSubmitted: .constant(false)
    )
    .padding(12)
    .background(Color("BackgroundColor"))
}

#Preview("BotChatBubble") {
    BotChatBubble(text: "Welcome chat message", maxWidth: UIScreen.main.bounds.width)
}

#Preview("UserChatBubble") {
    UserChatBubble(text: "Hello Ai, please help me with your knowledge.", maxWidth: UIScreen.main.bounds.width)
}