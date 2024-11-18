//
//  llama_batch.swift
//  OLMoE.swift
//
//  Created by Ken Adamson on 11/17/24.
//


import Foundation
import llama

extension llama_batch {
    mutating func clear() {
        self.n_tokens = 0
    }
    
    mutating func add(_ token: Token, _ position: Int32, _ ids: [Int], _ logit: Bool) {
        let i = Int(self.n_tokens)
        self.token[i] = token
        self.pos[i] = position
        self.n_seq_id[i] = Int32(ids.count)
        if let seq_id = self.seq_id[i] {
            for (j, id) in ids.enumerated() {
                seq_id[j] = Int32(id)
            }
        }
        self.logits[i] = logit ? 1 : 0
        self.n_tokens += 1
    }
}