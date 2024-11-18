//
//  Kind.swift
//  OLMoE.swift
//
//  Created by Ken Adamson on 11/17/24.
//


import Foundation
import llama

extension Token {
    enum Kind {
        case end
        case couldBeEnd
        case normal
    }
}