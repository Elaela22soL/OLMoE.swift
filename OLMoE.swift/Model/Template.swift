//
//  Template.swift
//  OLMoE.swift
//
//  Created by Ken Adamson on 11/17/24.
//


import Foundation
import llama

public struct Template {
    public typealias Attachment = (prefix: String, suffix: String)
    public let system: Attachment
    public let user: Attachment
    public let bot: Attachment
    public let systemPrompt: String?
    public let stopSequence: String?
    public let prefix: String
    public let shouldDropLast: Bool

    public init(
        prefix: String = "",
        system: Attachment? = nil,
        user: Attachment? = nil,
        bot: Attachment? = nil,
        stopSequence: String? = nil,
        systemPrompt: String?,
        shouldDropLast: Bool = false
    ) {
        self.system = system ?? ("", "")
        self.user = user  ?? ("", "")
        self.bot = bot ?? ("", "")
        self.stopSequence = stopSequence
        self.systemPrompt = systemPrompt
        self.prefix = prefix
        self.shouldDropLast = shouldDropLast
    }
    
    public var preprocess: (_ input: String, _ history: [Chat], _ llmInstance: LLM) -> String {
        return { [self] input, history, llmInstance in
            // If the state is restored, only preprocess the new input
            if llmInstance.savedState != nil {
                
                // Return only the new user input formatted
                var processed = prefix
                processed += "\(user.prefix)\(input)\(user.suffix)"
                processed += bot.prefix
                
                return processed
            } else {
                // Full preprocessing for the first input or reset state
                var processed = prefix
                if let systemPrompt {
                    processed += "\(system.prefix)\(systemPrompt)\(system.suffix)"
                }
                for chat in history {
                    if chat.role == .user {
                        processed += "\(user.prefix)\(chat.content)\(user.suffix)"
                    } else {
                        processed += "\(bot.prefix)\(chat.content)\(bot.suffix)"
                    }
                }
                // Add the current user input
                processed += "\(user.prefix)\(input)\(user.suffix)"
                // Handle bot prefix for the new response
                if shouldDropLast {
                    processed += bot.prefix.dropLast()
                } else {
                    processed += bot.prefix
                }
                return processed
            }
        }
    }

    
    public static func OLMoE(_ systemPrompt: String? = nil) -> Template {
        return Template(
            prefix: "<|endoftext|>",
            system: ("<|system|>\n", "\n"),
            user: ("<|user|>\n", "\n"),
            bot: ("<|assistant|>\n", "\n"),
            stopSequence: "<|endoftext|>",
            systemPrompt: systemPrompt
        )
    }
    
    public static func chatML(_ systemPrompt: String? = nil) -> Template {
        return Template(
            system: ("<|im_start|>system\n", "<|im_end|>\n"),
            user: ("<|im_start|>user\n", "<|im_end|>\n"),
            bot: ("<|im_start|>assistant\n", "<|im_end|>\n"),
            stopSequence: "<|im_end|>",
            systemPrompt: systemPrompt
        )
    }
    
    public static func alpaca(_ systemPrompt: String? = nil) -> Template {
        return Template(
            system: ("", "\n\n"),
            user: ("### Instruction:\n", "\n\n"),
            bot: ("### Response:\n", "\n\n"),
            stopSequence: "###",
            systemPrompt: systemPrompt
        )
    }
    
    public static func llama(_ systemPrompt: String? = nil) -> Template {
        return Template(
            prefix: "[INST] ",
            system: ("<<SYS>>\n", "\n<</SYS>>\n\n"),
            user: ("", " [/INST]"),
            bot: (" ", "</s><s>[INST] "),
            stopSequence: "</s>",
            systemPrompt: systemPrompt,
            shouldDropLast: true
        )
    }
    
    public static let mistral = Template(
        user: ("[INST] ", " [/INST]"),
        bot: ("", "</s> "),
        stopSequence: "</s>",
        systemPrompt: nil
    )
}
