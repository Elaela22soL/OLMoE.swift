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
        let deviceName = UIDevice.current.model
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM d, yyyy"
        let currentDate = dateFormatter.string(from: Date())
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        let currentTime = timeFormatter.string(from: Date())
        
//        let systemPrompt = "You are OLMoE (Open Language Mixture of Expert), a small language model running on \(deviceName). You have been developed at the Allen Institute for AI (Ai2) in Seattle, WA, USA. Today is \(currentDate). The time is \(currentTime)."
        
        
        guard FileManager.default.fileExists(atPath: Bot.modelFileURL.path) else {
            fatalError("Model file not found. Please download it first.")
        }
        
//        self.init(from: Bot.modelFileURL, template: .chatML(systemPrompt))
        self.init(from: Bot.modelFileURL, template: .chatML())
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
        Task { @MainActor in
            await bot.setOutput(to: "") // Clear the bot's output
        }
    }
    
    var body: some View {
        ZStack {
            Color("BackgroundColor")
                .edgesIgnoringSafeArea(.all)
            
            VStack(alignment: .leading) {
                ScrollView {
                    Text(bot.output)
                        .monospaced()
                        .foregroundColor(Color("TextColor"))
                }
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
                                    .stroke(Color("TextColor").opacity(0.2), lineWidth: 1)
                            )
                            .padding(8)
                            .foregroundColor(Color("TextColor"))
                    }
                    .background(
                        GeometryReader { geometry in
                            Color.clear.preference(key: ViewHeightKey.self, value: geometry.size.height)
                        }
                    )
                    .onPreferenceChange(ViewHeightKey.self) { height in
                        self.textEditorHeight = min(max(40, height), 120)
                    }
                    
                    VStack {
                        Button(action: respond) {
                            Image(systemName: "paperplane.fill")
                                .foregroundColor(Color("AccentColor"))
                                .font(.system(size: 24))  // Increase icon size
                                .frame(width: 40, height: 40)  // Set a larger frame
                        }
                        .padding(.bottom, 8)  // Increase spacing between buttons
                        
                        Button(action: stop) {
                            Image(systemName: "xmark")
                                .foregroundColor(Color("TextColor"))
                                .font(.system(size: 24))  // Increase icon size
                                .frame(width: 40, height: 40)  // Set a larger frame
                        }
                    }
                    .padding(.leading, 8)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
        }
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
