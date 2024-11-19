//
//  ContentView.swift
//  OLMoE.swift
//
//  Created by Luca Soldaini on 2024-09-16.
//

import SwiftUI
import DeviceCheck
import CryptoKit

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
    @State private var textEditorHeight: CGFloat = 40
    @State private var isGenerating = false
    @State private var scrollToBottom = false
    @State private var isSharing = false
    @State private var shareURL: URL?
    @State private var showShareSheet = false
    @State private var isSharingConfirmationVisible = false
    @State private var isDeleteHistoryConfirmationVisible = false
    @FocusState private var isTextEditorFocused: Bool

    private var hasValidInput: Bool {
        !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var isInputDisabled: Bool {
        isGenerating || isSharing
    }
    
    private var isDeleteButtonDisabled: Bool {
        isInputDisabled || bot.history.isEmpty
    }
    
    init(_ bot: Bot) {
        _bot = StateObject(wrappedValue: bot)
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
        Task {
            do {
                // App Attest Service
                let service = DCAppAttestService.shared
                
                // TODO: Move attest logic into it's own class
                // TODO: Make attest available on simulator
                // TODO: Deploy lambda to prod
                let challengeString = Configuration.challenge
                let clientDataHash = Data(SHA256.hash(data: Data(challengeString.utf8)))
                let userDefaults = UserDefaults.standard
                let keyIDKey = "appAttestKeyID"
                var keyID: String? = nil //userDefaults.string(forKey: keyIDKey)
                let attestationDoneKey = "appAttestAttestationDone"
                let attestationDone = userDefaults.bool(forKey: attestationDoneKey)
                var attestationObjectBase64: String? = nil

                #if targetEnvironment(simulator)
                // Simulator bypass
                keyID = "simulatorTest-\(keyIDKey)"
                userDefaults.set(true, forKey: attestationDoneKey)
                // Create a mock assertion
                attestationObjectBase64 = "mock_attestation".data(using: .utf8)?.base64EncodedString()

                #else
                guard service.isSupported else {
                    print("App Attest not supported on this device")
                    isSharing = false
                    return
                }

                if keyID == nil {
                    // Generate a new key
                    keyID = try await withCheckedThrowingContinuation { continuation in
                        service.generateKey { newKeyID, error in
                            if let error = error {
                                continuation.resume(throwing: error)
                            } else if let newKeyID = newKeyID {
                                continuation.resume(returning: newKeyID)
                            } else {
                                continuation.resume(throwing: NSError(domain: "AppAttest", code: -1, userInfo: nil))
                            }
                        }
                    }
                    // Store key ID in local storage
                    userDefaults.set(keyID, forKey: keyIDKey)
                    userDefaults.set(false, forKey: attestationDoneKey)
                }

                if !attestationDone {
                    let attestationObject: Data = try await withCheckedThrowingContinuation { continuation in
                        // attestation happens here
                        service.attestKey(keyID!, clientDataHash: clientDataHash) { attestation, error in
                            if let error = error {
                                continuation.resume(throwing: error)
                            } else if let attestation = attestation {
                                continuation.resume(returning: attestation)
                            } else {
                                continuation.resume(throwing: NSError(domain: "AppAttest", code: -1, userInfo: nil))
                            }
                        }
                    }
                    attestationObjectBase64 = attestationObject.base64EncodedString()
                    userDefaults.set(true, forKey: attestationDoneKey)
                }

                #endif

                // Prepare payload
                let apiKey = Configuration.apiKey
                let apiUrl = Configuration.apiUrl
                
                let modelName = "olmoe-1b-7b-0924-instruct-q4_k_m"
                let systemFingerprint = "\(modelName)-\(AppInfo.shared.appId)"

                let messages = bot.history.map { chat in
                    ["role": chat.role == .user ? "user" : "assistant", "content": chat.content]
                }

                var payload: [String: Any] = [
                    "model": modelName,
                    "system_fingerprint": systemFingerprint,
                    "created": Int(Date().timeIntervalSince1970),
                    "messages": messages,
                    "key_id": keyID!
                ]

                if let attestationObjectBase64 = attestationObjectBase64 {
                    payload["attestation_object"] = attestationObjectBase64
                }
                
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
                print("Error sharing conversation: \(error)")
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
            isSharingConfirmationVisible = true
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
        .popover(isPresented: $isSharingConfirmationVisible, content: {
            DisclaimerPage(
                title: Disclaimers.ShareDisclaimer().title,
                message: Disclaimers.ShareDisclaimer().text,
                confirm: DisclaimerPage.PageButton(
                    text: Disclaimers.ShareDisclaimer().buttonText,
                    onTap: {
                        shareConversation()
                        isSharingConfirmationVisible = false
                   }
               ),
               cancel: DisclaimerPage.PageButton(
                    text: "Cancel",
                    onTap: {
                        isSharingConfirmationVisible = false
                    }
               )
           )
           .presentationBackground(Color("BackgroundColor"))
        })
        .disabled(isSharing || bot.history.isEmpty)
        .opacity(isSharing || bot.history.isEmpty ? 0.5 : 1)
    }
    
    @ViewBuilder
    func trashButton() -> some View {
        return Button(action: {
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
                        ScrollView {
                            VStack(alignment: .leading, spacing: 10) {
                                // Display history
                                ForEach(bot.history, id: \.content) { chat in
                                    if chat.content != bot.output {
                                        Text(chat.role == .user ? "User: " : "Bot: ")
                                            .fontWeight(.bold)
                                            .foregroundColor(Color("TextColor"))
                                        + Text(chat.content)
                                            .foregroundColor(Color("TextColor"))
                                    }
                                }
                                .opacity(0.5)
                                .font(.manrope().monospaced())
                                
                                // Display current output
                                Text(bot.output)
                                    .monospaced()
                                    .foregroundColor(Color("TextColor"))
                                    .id("bottomID") // Unique ID for scrolling
                                Color.clear.frame(height: 1).id("bottomID2")
                            }
                        }
                        .onChange(of: bot.output) { _ in
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
                        .onChange(of: scrollToBottom) { newValue in
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
                                .frame(width: min(geometry.size.width - 160, 290))
                            Spacer()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                Spacer()
                
                HStack(alignment: .bottom, spacing: 8) {
                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $input)
                            .frame(height: max(40, textEditorHeight))
                            .scrollContentBackground(.hidden)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color("Surface"))
                                    .foregroundStyle(.thinMaterial)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .foregroundColor(Color("TextColor"))
                            .font(.manrope())
                            .focused($isTextEditorFocused)
                            .onChange(of: isTextEditorFocused, { _, isFocused in
                                if isFocused {
                                    textEditorHeight = 120
                                } else {
                                    textEditorHeight = 40
                                    self.hideKeyboard()
                                }
                            })
                            .disabled(isInputDisabled)
                            .opacity(isInputDisabled ? 0.6 : 1)
                        
                        if input.isEmpty {
                            Text("Message")
                                .padding([.horizontal], 4)
                                .padding([.vertical], 8)
                                .foregroundColor(.gray)
                        }
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
            .padding()
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
    @State private var bot: Bot?
    @AppStorage("hasSeenDisclaimer") private var hasSeenDisclaimer : Bool = false
    @State private var showDisclaimerPage : Bool = false
    @State private var showInfoPage : Bool = false
    @State private var disclaimerPageIndex: Int = 0
    @State private var isSupportedDevice: Bool = isDeviceSupported()
    @State private var useMockedModelResponse: Bool = false
    
    let disclaimers: [Disclaimer] = [
        Disclaimers.MainDisclaimer(),
        Disclaimers.AdditionalDisclaimer()
    ]
    
    var body: some View {
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
                    BotView(bot)
                } else {
                    ModelDownloadView()
                }
            }
            .onChange(of: downloadManager.isModelReady) { newValue in
                if newValue && bot == nil {
                    initializeBot()
                }
            }
            .popover(isPresented: $showDisclaimerPage) {
                let page = disclaimers[disclaimerPageIndex]
                DisclaimerPage(
                    title: page.title,
                    message: page.text,
                    confirm: DisclaimerPage.PageButton(
                        text: page.buttonText,
                        onTap: {
                            nextDisclaimerPage()
                        })
                )
                .interactiveDismissDisabled(true)
                .presentationBackground(Color("BackgroundColor"))
            }
            .onAppear(perform: checkModelAndInitializeBot)
            .onAppear {
                if !hasSeenDisclaimer {
                    showDisclaimerPage = true
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
            .sheet(isPresented: $showInfoPage) {
                InfoView()
            }
        }
    }

    private func nextDisclaimerPage() {
        disclaimerPageIndex = min(disclaimers.count, disclaimerPageIndex + 1)
        if disclaimerPageIndex >= disclaimers.count {
            disclaimerPageIndex = 0
            showDisclaimerPage = false
            hasSeenDisclaimer = true
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
