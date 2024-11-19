//
//  InfoPageView.swift
//  OLMoE.swift
//
//  Created by Thomas Jones on 11/14/24.
//

import SwiftUI

enum InfoText {

    static let infoTitle = "About"
    static let infoContent =
        """
        Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aenean ante ante, molestie ac dui in, ornare euismod mauris. In fringilla metus orci, a commodo lorem lacinia ut. Duis sodales felis a arcu efficitur, sit amet consectetur ante ultricies. Cras a mattis magna. Ut sit amet euismod elit. Duis vestibulum nibh at dapibus eleifend. Vestibulum metus nibh, efficitur in ante quis, interdum feugiat ipsum. Nullam in odio facilisis augue dapibus lacinia ut nec nisi.
        """

    static let faqTitle = "FAQ"
    static let faq =
        """
        Lorem ipsum dolor sit amet, consectetur adipiscing elit. 

        Q: Lorem?
        A: Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aenean ante ante, molestie ac dui in, ornare euismod mauris.

        Q: Ipsum?    
        A: Curabitur nec scelerisque magna. Donec et felis sit amet velit scelerisque condimentum scelerisque a sapien. Donec finibus magna eu justo aliquam consectetur. 

        Q: Dolor?
        A: Donec tellus nulla, ultricies et sagittis sit amet, consectetur ac elit. In sodales nunc justo, a malesuada ex hendrerit sit amet. Suspendisse ligula nulla, faucibus at tincidunt id, efficitur condimentum nibh. 
        """
}

struct InfoButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "info.circle")
                .foregroundColor(Color("TextColor"))
                .padding()
        }
        .clipShape(Circle())
        .background(
            RadialGradient(
                gradient: Gradient(colors: [
                    Color("BackgroundColor").opacity(0.9), Color.clear,
                ]),
                center: .center,
                startRadius: 20,
                endRadius: 40)
        )
    }
}

struct InfoView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Spacer()

                        Image("Splash")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 150, height: 120)

                        Spacer()
                    }

                    Text(InfoText.infoTitle)
                        .font(.title)
                        .font(.manrope())
                        .bold()
                        .padding(.horizontal)

                    Text(InfoText.infoContent)
                        .font(.manrope())
                        .padding(.horizontal)

                    Text(InfoText.faqTitle)
                        .font(.title)
                        .font(.manrope())
                        .bold()
                        .padding(.horizontal)

                    Text(InfoText.faq)
                        .font(.manrope())
                        .padding(.horizontal)
                }
                .padding()
            }
            .background(Color("BackgroundColor"))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle")
                            .font(.system(size: 20))
                            .frame(width: 40, height: 40)
                            .foregroundColor(Color("TextColor"))
                    }
                    .clipShape(Circle())
                }
            }.toolbarBackground(
                Color("BackgroundColor"), for: .navigationBar
            )
        }
    }
}
