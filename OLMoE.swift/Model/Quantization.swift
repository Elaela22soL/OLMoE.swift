//
//  Quantization.swift
//  OLMoE.swift
//
//  Created by Ken Adamson on 11/17/24.
//


import Foundation
import llama

public enum Quantization: String {
    case IQ1_S
    case IQ1_M
    case IQ2_XXS
    case IQ2_XS
    case IQ2_S
    case IQ2_M
    case Q2_K_S
    case Q2_K
    case IQ3_XXS
    case IQ3_XS
    case IQ3_S
    case IQ3_M
    case Q3_K_S
    case Q3_K_M
    case Q3_K_L
    case IQ4_XS
    case IQ4_NL
    case Q4_0
    case Q4_1
    case Q4_K_S
    case Q4_K_M
    case Q5_0
    case Q5_1
    case Q5_K_S
    case Q5_K_M
    case Q6_K
    case Q8_0
}