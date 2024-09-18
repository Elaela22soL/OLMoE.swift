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
        
        let systemPrompt = "You are OLMoE (Open Language Mixture of Expert), a small language model running on \(deviceName). You have been developed at the Allen Institute for AI (Ai2) in Seattle, WA, USA. Today is \(currentDate). The time is \(currentTime)."
    
        guard FileManager.default.fileExists(atPath: Bot.modelFileURL.path) else {
            fatalError("Model file not found. Please download it first.")
        }
        
//        self.init(from: Bot.modelFileURL, template: .OLMoE(systemPrompt))
        self.init(from: Bot.modelFileURL, template: .OLMoE())
    }
}


struct BotView: View {
    @StateObject var bot: Bot
    @State var input = ""
    @State private var textEditorHeight: CGFloat = 40
    @State private var isGenerating = false
    
    init(_ bot: Bot) {
        _bot = StateObject(wrappedValue: bot)
    }
    
    func respond() {
        isGenerating = true
        Task {
            await bot.respond(to: input)
        }
        isGenerating = false
    }
    
    func stop() {
        bot.stop()
        input = "" // Clear the input
        isGenerating = false
        Task { @MainActor in
            await bot.clearHistory()
            bot.setOutput(to: "")
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            contentView(in: geometry)
        }
    }
    
    private func contentView(in geometry: GeometryProxy) -> some View {
        ZStack {
            Color("BackgroundColor")
                .edgesIgnoringSafeArea(.all)
            
            VStack(alignment: .leading) {
                if !bot.output.isEmpty || isGenerating || !bot.history.isEmpty {
                    ScrollView {
                        Text(bot.output)
                            .monospaced()
                            .foregroundColor(Color("TextColor"))
                    }
                } else {
                    ZStack {
                        VStack{
                            Spacer()
                                .frame(height: geometry.size.height * 0.1)
                            Image("Splash")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: min(geometry.size.width - 160, 290))
                            Spacer()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                Spacer()
                
                ///
                HStack(alignment: .bottom, spacing: 8) {
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
                            .font(.manrope())
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
                                .font(.system(size: 24))
                                .frame(width: 40, height: 40)
                        }
                        .disabled(isGenerating)
                        Button(action: stop) {
                            Image(systemName: "trash.fill")
                                .foregroundColor(Color("TextColor"))
                                .font(.system(size: 24))
                                .frame(width: 40, height: 40)
                        }
                        .disabled(!isGenerating)
                    }
                }
                .padding(.horizontal)
                .frame(maxWidth: .infinity)
            
            
            
            
            ///
            
            }
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
