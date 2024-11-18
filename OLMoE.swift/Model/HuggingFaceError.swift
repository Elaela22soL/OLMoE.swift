//
//  HuggingFaceError.swift
//  OLMoE.swift
//
//  Created by Ken Adamson on 11/17/24.
//


import Foundation
import llama

public enum HuggingFaceError: Error {
    case network(statusCode: Int)
    case noFilteredURL
    case urlIsNilForSomeReason
}