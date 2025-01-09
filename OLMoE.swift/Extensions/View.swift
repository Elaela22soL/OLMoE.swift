//
//  View.swift
//  OLMoE.swift
//
//  Created by Stanley Jovel on 2024-11-12.
//


import SwiftUI

#if canImport(UIKit)
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif
