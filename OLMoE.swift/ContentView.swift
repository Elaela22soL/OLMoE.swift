//
//  ContentView.swift
//  OLMoE.swift
//
//  Created by Luca Soldaini on 2024-09-16.
//

import SwiftUI

class Bot: LLM {
    static let modelFileName = "olmoe-1b-7b-0924-instruct-q4_k_m.gguf"
    static let modelFileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(modelFileName)

    convenience init() {
        let systemPrompt = "You are a sentient AI with emotions."
        
        guard FileManager.default.fileExists(atPath: Bot.modelFileURL.path) else {
            fatalError("Model file not found. Please download it first.")
        }
        
        self.init(from: Bot.modelFileURL, template: .chatML(systemPrompt))
    }
}

import SwiftUI

struct BotView: View {
    @StateObject var bot: Bot
    @State var input = ""
    @State private var textEditorHeight: CGFloat = 40
    
    init(_ bot: Bot) {
        _bot = StateObject(wrappedValue: bot)
    }
    
    func respond() { Task { await bot.respond(to: input) } }
    
    func stop() {
        bot.stop()
        input = "" // Clear the input
        textEditorHeight = 40 // Reset the height
        Task { @MainActor in
            await bot.setOutput(to: "") // Clear the bot's output
        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            ScrollView { Text(bot.output).monospaced() }
            Spacer()
            HStack(alignment: .bottom) {
                ZStack(alignment: .leading) {
                    TextEditor(text: $input)
                        .frame(height: max(40, textEditorHeight))
                        .scrollContentBackground(.hidden)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .foregroundStyle(.thinMaterial)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                        .padding(8)
                }
                .background(
                    GeometryReader { geometry in
                        Color.clear.preference(key: ViewHeightKey.self, value: geometry.size.height)
                    }
                )
                .onPreferenceChange(ViewHeightKey.self) { height in
                    self.textEditorHeight = min(max(40, height), 120)
                }
                
                Button(action: respond) { Image(systemName: "paperplane.fill") }
                Button(action: stop) { Image(systemName: "xmark") }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}

struct ViewHeightKey: PreferenceKey {
    static var defaultValue: CGFloat { 0 }
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct ContentView: View {
    @State private var isModelReady = false
    @State private var bot: Bot?

    var body: some View {
        VStack {
            if let bot = bot {
                BotView(bot)
            } else {
                ModelDownloadView(isModelReady: $isModelReady)
            }
        }
        .onChange(of: isModelReady) { newValue in
            if newValue && bot == nil {
                initializeBot()
            }
        }
        .onAppear(perform: checkModelAndInitializeBot)
    }

    private func checkModelAndInitializeBot() {
        if FileManager.default.fileExists(atPath: Bot.modelFileURL.path) {
            isModelReady = true
            initializeBot()
        }
    }

    private func initializeBot() {
        bot = Bot()
    }
}
