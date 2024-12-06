import Foundation
import llama

public typealias Token = llama_token
public typealias Model = OpaquePointer

public struct Chat: Identifiable {
    public var id: UUID? // Optional unique identifier
    public var role: Role
    public var content: String

    public init(id: UUID? = UUID(), role: Role, content: String) {
        self.id = id
        self.role = role
        self.content = content
    }
}

@globalActor public actor InferenceActor {
    static public let shared = InferenceActor()
}

open class LLM: ObservableObject {
    public var model: Model
    public var history: [Chat]
    public var preprocess: (_ input: String, _ history: [Chat]) -> String = { input, _ in return input }
    public var postprocess: (_ output: String) -> Void                    = { print($0) }
    public var update: (_ outputDelta: String?) -> Void                   = { _ in }
    public var template: Template? = nil {
        didSet {
            guard let template else {
                preprocess = { input, _ in return input }
                stopSequence = nil
                stopSequenceLength = 0
                return
            }
            preprocess = template.preprocess
            if let stopSequence = template.stopSequence?.utf8CString {
                self.stopSequence = stopSequence
                stopSequenceLength = stopSequence.count - 1
            } else {
                stopSequence = nil
                stopSequenceLength = 0
            }
        }
    }

    public var topK: Int32
    public var topP: Float
    public var temp: Float
    private var sampler: UnsafeMutablePointer<llama_sampler>?
    public var historyLimit: Int
    public var path: [CChar]

    public var loopBackTestResponse: Bool = false

    @Published public private(set) var output = ""
    @MainActor public func setOutput(to newOutput: consuming String) {
        output = newOutput.trimmingCharacters(in: .whitespaces)
    }

    private var context: Context!
    private var batch: llama_batch!
    private let maxTokenCount: Int
    private let totalTokenCount: Int
    private let newlineToken: Token
    private var stopSequence: ContiguousArray<CChar>?
    private var stopSequenceLength: Int
    private var params: llama_context_params
    private var isFull = false
    private var updateProgress: (Double) -> Void = { _ in }
    private var nPast: Int32 = 0 // Track number of tokens processed
private var savedState: Data?

    public init(
        from path: String,
        stopSequence: String? = nil,
        history: [Chat] = [],
        seed: UInt32 = .random(in: .min ... .max),
        topK: Int32 = 40,
        topP: Float = 0.95,
        temp: Float = 0.8,
        historyLimit: Int = 8,
        maxTokenCount: Int32 = 2048
    ) {
        self.path = path.cString(using: .utf8)!
        var modelParams = llama_model_default_params()
#if targetEnvironment(simulator)
        modelParams.n_gpu_layers = 0
#endif
        let model = llama_load_model_from_file(self.path, modelParams)!
        params = llama_context_default_params()
        let processorCount = Int32(ProcessInfo().processorCount)
        self.maxTokenCount = Int(min(maxTokenCount, llama_n_ctx_train(model)))
//        params.seed = seed
        params.n_ctx = UInt32(self.maxTokenCount)
        params.n_batch = params.n_ctx
        params.n_threads = processorCount
        params.n_threads_batch = processorCount
        self.topK = topK
        self.topP = topP
        self.temp = temp
        self.historyLimit = historyLimit
        self.model = model
        self.history = history
        self.totalTokenCount = Int(llama_n_vocab(model))
        self.newlineToken = model.newLineToken
        self.stopSequence = stopSequence?.utf8CString
        self.stopSequenceLength = (self.stopSequence?.count ?? 1) - 1
        batch = llama_batch_init(Int32(self.maxTokenCount), 0, 1)

        // sampler to run with default parameters
        let sparams = llama_sampler_chain_default_params()
        self.sampler = llama_sampler_chain_init(sparams)

        if let sampler = self.sampler {
            llama_sampler_chain_add(sampler, llama_sampler_init_top_k(topK))
            llama_sampler_chain_add(sampler, llama_sampler_init_top_p(topP, 1))
            llama_sampler_chain_add(sampler, llama_sampler_init_temp(temp))
            llama_sampler_chain_add(sampler, llama_sampler_init_dist(seed))
        }

    }

    deinit {
        llama_free_model(model)
    }

    public convenience init(
        from url: URL,
        stopSequence: String? = nil,
        history: [Chat] = [],
        seed: UInt32 = .random(in: .min ... .max),
        topK: Int32 = 40,
        topP: Float = 0.95,
        temp: Float = 0.8,
        historyLimit: Int = 8,
        maxTokenCount: Int32 = 2048
    ) {
        self.init(
            from: url.path,
            stopSequence: stopSequence,
            history: history,
            seed: seed,
            topK: topK,
            topP: topP,
            temp: temp,
            historyLimit: historyLimit,
            maxTokenCount: maxTokenCount
        )
    }

    public convenience init(
        from huggingFaceModel: HuggingFaceModel,
        to url: URL = .modelsDirectory,
        as name: String? = nil,
        history: [Chat] = [],
        seed: UInt32 = .random(in: .min ... .max),
        topK: Int32 = 40,
        topP: Float = 0.95,
        temp: Float = 0.8,
        historyLimit: Int = 8,
        maxTokenCount: Int32 = 2048,
        updateProgress: @escaping (Double) -> Void = { print(String(format: "downloaded(%.2f%%)", $0 * 100)) }
    ) async throws {
        let url = try await huggingFaceModel.download(to: url, as: name) { progress in
            Task { await MainActor.run { updateProgress(progress) } }
        }
        self.init(
            from: url,
            template: huggingFaceModel.template,
            history: history,
            seed: seed,
            topK: topK,
            topP: topP,
            temp: temp,
            historyLimit: historyLimit,
            maxTokenCount: maxTokenCount
        )
        self.updateProgress = updateProgress
    }

    public convenience init(
        from url: URL,
        template: Template,
        history: [Chat] = [],
        seed: UInt32 = .random(in: .min ... .max),
        topK: Int32 = 40,
        topP: Float = 0.95,
        temp: Float = 0.8,
        historyLimit: Int = 8,
        maxTokenCount: Int32 = 2048
    ) {
        self.init(
            from: url.path,
            stopSequence: template.stopSequence,
            history: history,
            seed: seed,
            topK: topK,
            topP: topP,
            temp: temp,
            historyLimit: historyLimit,
            maxTokenCount: maxTokenCount
        )
        self.preprocess = template.preprocess
        self.template = template
    }

    private var inferenceTask: Task<Void, Never>?

    public func stop() {
        inferenceTask?.cancel()
        inferenceTask = nil
    }

    @InferenceActor
    private func predictNextToken() async -> Token {
        // Ensure context exists; otherwise, return end token
        guard let context = self.context else { return model.endToken }

        // Check if the task has been canceled
        guard !Task.isCancelled else { return model.endToken }

        guard let sampler = self.sampler else {
            fatalError("Sampler not initialized")
        }

        // Sample the next token with a valid context
        let token = llama_sampler_sample(sampler, context.pointer, batch.n_tokens - 1) // Use batch token count for correct context


        batch.clear()
        batch.add(token, currentCount, [0], true)
        nPast += 1 // Increment the token count after predicting a new token
context.decode(batch)
        return token
    }




    private var currentCount: Int32!
    private var decoded = ""

    open func recoverFromLengthy(_ input: borrowing String, to output:  borrowing AsyncStream<String>.Continuation) {
        output.yield("tl;dr")
    }

    @InferenceActor
    public func clearHistory() async {
        history.removeAll()
        nPast = 0 // Reset token count when clearing history
        await setOutput(to: "")
        context = nil
        savedState = nil
        // Reset any other state variables if necessary
        // For example, if you have a variable tracking the current conversation context:
        // currentContext = nil
    }

    private func prepare(from input: borrowing String, to output: borrowing AsyncStream<String>.Continuation) -> Bool {
        guard !input.isEmpty else { return false }
        context = .init(model, params)
        var tokens = encode(input)
        var initialCount = tokens.count
        currentCount = Int32(initialCount)
        if maxTokenCount <= currentCount {
            while !history.isEmpty && maxTokenCount <= currentCount {
                history.removeFirst(min(2, history.count))
                tokens = encode(preprocess(self.input, history))
                initialCount = tokens.count
                currentCount = Int32(initialCount)
            }
            if maxTokenCount <= currentCount {
                isFull = true
                recoverFromLengthy(input, to: output)
                return false
            }
        }
        for (i, token) in tokens.enumerated() {
            batch.n_tokens = Int32(i)
            batch.add(token, batch.n_tokens, [0], i == initialCount - 1)
        }
        context.decode(batch)
        return true
    }

    @InferenceActor
    private func finishResponse(from response: inout [String], to output: borrowing AsyncStream<String>.Continuation) async {
        multibyteCharacter.removeAll()
        var input = ""
        if !history.isEmpty {
            history.removeFirst(min(2, history.count))
            input = preprocess(self.input, history)
        } else {
            response.scoup(response.count / 3)
            input = preprocess(self.input, history)
            input += response.joined()
        }
        let rest = getResponse(from: input)
        for await restDelta in rest {
            output.yield(restDelta)
        }
    }

    private func process(_ token: Token, to output: borrowing AsyncStream<String>.Continuation) -> Bool {
        struct saved {
            static var stopSequenceEndIndex = 0
            static var letters: [CChar] = []
        }
        guard token != model.endToken else { return false }

        let word = decode(token) // Decode the token directly

        guard let stopSequence else {
            output.yield(word)
            return true
        }

        // Existing stop sequence handling logic
        var found = 0 < saved.stopSequenceEndIndex
        var letters: [CChar] = []
        for letter in word.utf8CString {
            guard letter != 0 else { break }
            if letter == stopSequence[saved.stopSequenceEndIndex] {
                saved.stopSequenceEndIndex += 1
                found = true
                saved.letters.append(letter)
                guard saved.stopSequenceEndIndex == stopSequenceLength else { continue }
                saved.stopSequenceEndIndex = 0
                saved.letters.removeAll()
                return false
            } else if found {
                saved.stopSequenceEndIndex = 0
                if !saved.letters.isEmpty {
                    let prefix = String(cString: saved.letters + [0])
                    output.yield(prefix + word)
                    saved.letters.removeAll()
                }
                output.yield(word)
                return true
            }
            letters.append(letter)
        }
        if !letters.isEmpty {
            output.yield(found ? String(cString: letters + [0]) : word)
        }
        return true
    }


    private func getResponse(from input: String) -> AsyncStream<String> {
        AsyncStream<String> { output in
            Task { [weak self] in
                guard let self = self else { return output.finish() } // Safely unwrap `self`
                defer { self.context = nil }  // Use `self` safely now that it's unwrapped

                guard self.prepare(from: input, to: output) else {
                    return output.finish()
                }

                var response: [String] = []
                while self.currentCount < self.maxTokenCount {
                    let token = await self.predictNextToken()
                    if !self.process(token, to: output) { return output.finish() }
                    self.currentCount += 1
                }

                await self.finishResponse(from: &response, to: output)
                output.finish()
            }
        }
    }



    private var input: String = ""
    private var isAvailable = true

    @InferenceActor
    public func getCompletion(from input: borrowing String) async -> String {
        guard isAvailable else { fatalError("LLM is being used") }
        isAvailable = false
        let response = getResponse(from: input)
        var output = ""
        for await responseDelta in response {
            output += responseDelta
        }
        isAvailable = true
        return output
    }

    private func getTestLoopbackResponse() -> AsyncStream<String> {
        return AsyncStream { continuation  in
            Task {
                continuation.yield("This is a test loop-back response:\n")
                for i in 0...5 {
                    try? await Task.sleep(nanoseconds: 1_000_000_000 / 2)
                    continuation.yield("\(i) - \(input)\n")
                }
                continuation.finish()
            }
        }
    }

    @InferenceActor
    public func respond(to input: String, with makeOutputFrom: @escaping (AsyncStream<String>) async -> String) async {
        inferenceTask?.cancel() // Cancel any ongoing inference task
        inferenceTask = Task { [weak self] in
            guard let self = self else { return }

            let historyBeforeInput = self.history
            await MainActor.run {
                // Append user's message to history prior to response generation
                self.history.append(Chat(role: .user, content: input))
            }

            self.input = input
            let processedInput = self.preprocess(input, historyBeforeInput)
            let responseStream = loopBackTestResponse ? self.getTestLoopbackResponse() : self.getResponse(from: processedInput)

            // Generate the output string using the async closure
            let output = (await makeOutputFrom(responseStream)).trimmingCharacters(in: .whitespacesAndNewlines)

            await MainActor.run {
                if !output.isEmpty {
                    // Update history and process the final output on the main actor
                    self.history.append(Chat(role: .bot, content: output))
                }

                // Maintain the history limit
                if self.history.count > self.historyLimit {
                    self.history.removeFirst(min(2, self.history.count))
                }

                self.postprocess(output)
            }
        }
        // Save the state after generating a response
            self.savedState = saveState()

        await inferenceTask?.value
    }
    
    open func respond(to input: String) async {
        // Restore the state before generating a response
        if let savedState = self.savedState {
            restoreState(from: savedState)
        }

        // Restore the state before generating a response
        if let savedState = self.savedState {
            restoreState(from: savedState)
            nPast = Int32(history.reduce(0) { $0 + $1.content.count }) // Restore token count from history
        }

        await respond(to: input) { [self] response in
            await setOutput(to: "")
            for await responseDelta in response {
                update(responseDelta)
                await setOutput(to: output + responseDelta)
            }
            update(nil)
            let trimmedOutput = output.trimmingCharacters(in: .whitespacesAndNewlines)
            await setOutput(to: trimmedOutput.isEmpty ? "..." : trimmedOutput)
            return output
        }

        // Save the state after generating a response
        self.savedState = saveState()
    }


    private var multibyteCharacter: [CUnsignedChar] = []
    private func decode(_ token: Token) -> String {
        multibyteCharacter.removeAll(keepingCapacity: true) // Reset multibyte buffer
        return model.decode(token, with: &multibyteCharacter)
    }


    public func decode(_ tokens: [Token]) -> String {
        return tokens.map({model.decodeOnly($0)}).joined()
    }

    @inlinable
    public func encode(_ text: borrowing String) -> [Token] {
        model.encode(text)
    }
}


extension LLM {
    public func saveState() -> Data? {
        // Ensure the context exists
        guard let contextPointer = self.context?.pointer else {
            print("Error: llama_context pointer is nil.")
            return nil
        }

        // Get the size of the state
        let stateSize = llama_state_get_size(contextPointer)
        guard stateSize > 0 else {
            print("Error: Unable to retrieve state size.")
            return nil
        }

        // Allocate a buffer for the state data
        var stateData = Data(count: stateSize)
        stateData.withUnsafeMutableBytes { (pointer: UnsafeMutableRawBufferPointer) in
            if let baseAddress = pointer.baseAddress {
                let bytesWritten = llama_state_get_data(contextPointer, baseAddress.assumingMemoryBound(to: UInt8.self), stateSize)
                assert(bytesWritten == stateSize, "Error: Written state size does not match expected size.")
            }
        }
        return stateData
    }

    public func restoreState(from stateData: Data) {
        // Ensure the context exists
        guard let contextPointer = self.context?.pointer else {
            print("Error: llama_context pointer is nil.")
            return
        }

        // Set the state data
        stateData.withUnsafeBytes { (pointer: UnsafeRawBufferPointer) in
            if let baseAddress = pointer.baseAddress {
                let bytesRead = llama_state_set_data(contextPointer, baseAddress.assumingMemoryBound(to: UInt8.self), stateData.count)
                assert(bytesRead == stateData.count, "Error: Read state size does not match expected size.")
            }
        }
    }
}

