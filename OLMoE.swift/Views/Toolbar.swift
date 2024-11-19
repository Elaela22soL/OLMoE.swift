//
//  ToolBar.swift
//  OLMoE.swift
//
//  Created by Thomas Jones on 11/18/24.
//

import SwiftUI

struct AppToolbar<Content: View>: ToolbarContent {

    let leadingContent: Content
    
    init(
        @ViewBuilder leadingContent: () -> Content = { EmptyView() }
    ) {
        self.leadingContent = leadingContent()
    }
    
    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarLeading) {
            self.leadingContent
        }
        
        ToolbarItem(placement: .principal) {
            Image("Splash")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)  // Adjust size as needed
        }
    }
}

