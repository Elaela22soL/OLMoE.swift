//
//  ContentView.swift
//  OLMoE.swift
//
//  Created by Luca Soldaini on 2024-09-16.
//

import SwiftUI
import os

class Bot: LLM {
    static let modelFileName = "olmoe-1b-7b-0924-instruct-q4_k_m.gguf"
    static let modelFileURL = URL.modelsDirectory.appendingPathComponent(modelFileName)

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
    @State private var isGenerating = false
    @State private var scrollToBottom = false
    @State private var isSharing = false
    @State private var shareURL: URL?
    @State private var showShareSheet = false
    @State private var isSharingConfirmationVisible = false
    @State private var isDeleteHistoryConfirmationVisible = false
    @FocusState private var isTextEditorFocused: Bool
    let disclaimerHandlers: DisclaimerHandlers

    private var hasValidInput: Bool {
        !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var isInputDisabled: Bool {
        isGenerating || isSharing
    }

    private var isDeleteButtonDisabled: Bool {
        isInputDisabled || bot.history.isEmpty
    }

    init(_ bot: Bot, disclaimerHandlers: DisclaimerHandlers) {
        _bot = StateObject(wrappedValue: bot)
        self.disclaimerHandlers = disclaimerHandlers
    }

    func respond() {
        isGenerating = true
        Task {
            let originalInput = input
            input = "" // Clear the input after sending
            await bot.respond(to: originalInput)
            scrollToBottom = true
            await MainActor.run {
                isGenerating = false
            }
        }
    }

    func stop() {
        bot.stop()
        input = "" // Clear the input
        isGenerating = false
    }

    func deleteHistory() {
        Task { @MainActor in
            await bot.clearHistory()
            bot.setOutput(to: "")
        }
    }

    func shareConversation() {
        isSharing = true
        disclaimerHandlers.setShowDisclaimerPage(false)
        Task {
            do {
                let challengeString = Configuration.challenge
                let attestationResult = try await AppAttestManager.performAttest(challengeString: challengeString)
                
                // Prepare payload
                let apiKey = Configuration.apiKey
                let apiUrl = Configuration.apiUrl

                let modelName = "olmoe-1b-7b-0924-instruct-q4_k_m"
                let systemFingerprint = "\(modelName)-\(AppInfo.shared.appId)"

                let messages = bot.history.map { chat in
                    ["role": chat.role == .user ? "user" : "assistant", "content": chat.content]
                }

                let payload: [String: Any] = [
                    "model": modelName,
                    "system_fingerprint": systemFingerprint,
                    "created": Int(Date().timeIntervalSince1970),
                    "messages": messages,
                    "key_id": attestationResult.keyID,
                    "attestation_object": attestationResult.attestationObjectBase64
                ]

                let jsonData = try JSONSerialization.data(withJSONObject: payload)

                guard let url = URL(string: apiUrl), !apiUrl.isEmpty else {
                    print("Invalid URL")
                    await MainActor.run {
                        isSharing = false
                    }
                    return
                }

                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
                request.httpBody = jsonData
                let (data, response) = try await URLSession.shared.data(for: request)

                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    let responseString = String(data: data, encoding: .utf8)!
                    if let jsonData = responseString.data(using: .utf8),
                       let jsonResult = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any],
                       let body = jsonResult["body"] as? String,
                       let bodyData = body.data(using: .utf8),
                       let bodyJson = try JSONSerialization.jsonObject(with: bodyData, options: []) as? [String: Any],
                       let urlString = bodyJson["url"] as? String,
                       let url = URL(string: urlString) {
                        await MainActor.run {
                            self.shareURL = url
                            self.showShareSheet = true
                        }
                        print("Conversation shared successfully")
                    } else {
                        print("Failed to parse response")
                    }
                } else {
                    print("Failed to share conversation")
                }
            } catch {
                let attestError = error as NSError
                if attestError.domain == "AppAttest" {
                    print("Error: \(attestError.localizedDescription)")
                } else {
                    print("Error sharing conversation: \(error)")
                }
            }

            await MainActor.run {
                isSharing = false
            }
        }
    }

    @ViewBuilder
    func shareButton() -> some View {
        Button(action: {
            isTextEditorFocused = false
            disclaimerHandlers.setActiveDisclaimer(Disclaimers.ShareDisclaimer())
            disclaimerHandlers.setCancelAction({ disclaimerHandlers.setShowDisclaimerPage(false) })
            disclaimerHandlers.setAllowOutsideTapDismiss(true)
            disclaimerHandlers.setConfirmAction({ shareConversation() })
            disclaimerHandlers.setShowDisclaimerPage(true)
        }) {
            HStack {
                if isSharing {
                    SpinnerView(color: Color("AccentColor"))
                } else {
                    Image(systemName: "square.and.arrow.up")
                }
            }
            .foregroundColor(Color("TextColor"))
        }
        .disabled(isSharing || bot.history.isEmpty || isGenerating)
        .opacity(isSharing || bot.history.isEmpty || isGenerating ? 0.5 : 1)
    }

    @ViewBuilder
    func trashButton() -> some View {
        Button(action: {
            isTextEditorFocused = false
            isDeleteHistoryConfirmationVisible = true
            stop()
        }) {
            Image(systemName: "trash.fill")
                .foregroundColor(Color("TextColor"))
        }.alert("Delete history?", isPresented: $isDeleteHistoryConfirmationVisible, actions: {
            Button("Delete", action: deleteHistory)
            Button("Cancel", role: .cancel) {
                isDeleteHistoryConfirmationVisible = false
            }
        })
        .disabled(isDeleteButtonDisabled)
        .opacity(isDeleteButtonDisabled ? 0.5 : 1)
    }

    var body: some View {
        GeometryReader { geometry in
            contentView(in: geometry)
        }
        .sheet(isPresented: $showShareSheet, content: {
            if let url = shareURL {
                ActivityViewController(activityItems: [url])
            }
        })
    }

    private func contentView(in geometry: GeometryProxy) -> some View {
        ZStack {
            Color("BackgroundColor")
                .edgesIgnoringSafeArea(.all)

            VStack(alignment: .leading) {
                if !bot.output.isEmpty || isGenerating || !bot.history.isEmpty {
                    ScrollViewReader { proxy in
                        ChatView(history: bot.history, output: bot.output, isGenerating: $isGenerating)
                        .onChange(of: bot.output) { _, _ in
                            if isGenerating {
                                withAnimation {
                                    proxy.scrollTo("bottomID", anchor: .bottom)
                                }
                            } else {
                                withAnimation {
                                    proxy.scrollTo("bottomID2", anchor: .bottom)
                                }
                            }

                        }
                        .onChange(of: scrollToBottom) { _, newValue in
                            if newValue {
                                withAnimation {
                                    proxy.scrollTo("bottomID", anchor: .bottom)
                                }
                                scrollToBottom = false
                            }
                        }
                        .gesture(TapGesture().onEnded({
                            isTextEditorFocused = false
                        }))
                    }
                } else {
                    ZStack {
                        VStack{
                            Spacer()
                                .frame(height: geometry.size.height * 0.1)
                            Image("Splash")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: max(140, min(geometry.size.width - 160, 290)))
                            Spacer()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                Spacer()

                MessageInputView(
                    input: $input,
                    isGenerating: $isGenerating,
                    isTextEditorFocused: $isTextEditorFocused,
                    isInputDisabled: isInputDisabled,
                    hasValidInput: hasValidInput,
                    respond: respond,
                    stop: stop
                )
            }
            .padding(12)
        }
        .sheet(isPresented: $showShareSheet, content: {
            if let url = shareURL {
                ActivityViewController(activityItems: [url])
            }
        })
        .gesture(TapGesture().onEnded({
            isTextEditorFocused = false
        }))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                shareButton()
                trashButton()
            }
        }
    }
}

struct ViewHeightKey: PreferenceKey {
    static var defaultValue: CGFloat { 0 }
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}


// Add this struct to handle the UIActivityViewController
struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: UIViewControllerRepresentableContext<ActivityViewController>) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: UIViewControllerRepresentableContext<ActivityViewController>) {}
}

struct ContentView: View {
    @StateObject private var downloadManager = BackgroundDownloadManager.shared
    @StateObject private var disclaimerState = DisclaimerState()
    @State private var bot: Bot?
    @State private var showInfoPage : Bool = false
    @State private var isSupportedDevice: Bool = isDeviceSupported()
    @State private var useMockedModelResponse: Bool = false

    let logger = Logger(subsystem: "com.allenai.olmoe", category: "ContentView")

    var body: some View {
        ZStack {
            NavigationStack {
                VStack {
                    if !isSupportedDevice && !useMockedModelResponse {
                        UnsupportedDeviceView(
                            proceedAnyway: { isSupportedDevice = true },
                            proceedMocked: {
                                bot?.loopBackTestResponse = true
                                useMockedModelResponse = true
                            }
                        )
                    } else if let bot = bot {
                        BotView(bot, disclaimerHandlers: DisclaimerHandlers(
                            setActiveDisclaimer: { self.disclaimerState.activeDisclaimer = $0 },
                            setAllowOutsideTapDismiss: { self.disclaimerState.allowOutsideTapDismiss = $0 },
                            setCancelAction: { self.disclaimerState.onCancel = $0 },
                            setConfirmAction: { self.disclaimerState.onConfirm = $0 },
                            setShowDisclaimerPage: { self.disclaimerState.showDisclaimerPage = $0 }
                        ))
                    } else {
                        ModelDownloadView()
                    }
                }
                .onChange(of: downloadManager.isModelReady) { newValue in
                    if newValue && bot == nil {
                        initializeBot()
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    AppToolbar(
                        leadingContent: {
                            InfoButton(action: { showInfoPage = true })
                        }
                    )
                }
            }
            .onAppear {
                disclaimerState.showInitialDisclaimer()
            }

            InfoView(isPresented: $showInfoPage)

            DisclaimerPage(
                allowOutsideTapDismiss: disclaimerState.allowOutsideTapDismiss,
                isPresented: $disclaimerState.showDisclaimerPage,
                message: disclaimerState.activeDisclaimer?.text ?? "",
                title: disclaimerState.activeDisclaimer?.title ?? "",
                confirm: DisclaimerPage.PageButton(
                    text: disclaimerState.activeDisclaimer?.buttonText ?? "",
                    onTap: {
                        disclaimerState.onConfirm?()
                    }
                ),
                cancel: disclaimerState.onCancel.map { cancelAction in
                    DisclaimerPage.PageButton(
                        text: "Cancel",
                        onTap: {
                            cancelAction()
                            disclaimerState.activeDisclaimer = nil
                        }
                    )
                }
            )
        }
    }

    private func checkModelAndInitializeBot() {
        if FileManager.default.fileExists(atPath: Bot.modelFileURL.path) {
            downloadManager.isModelReady = true
            initializeBot()
        }
    }

    private func initializeBot() {
        bot = Bot()
        bot?.loopBackTestResponse = useMockedModelResponse
    }
}
