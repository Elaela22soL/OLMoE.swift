//
//  [String].swift
//  OLMoE.swift
//
//  Created by Ken Adamson on 11/17/24.
//


extension [String] {
    mutating func scoup(_ count: Int) {
        guard 0 < count else { return }
        let firstIndex = count
        let lastIndex = count * 2
        self.removeSubrange(firstIndex..<lastIndex)
    }
}
