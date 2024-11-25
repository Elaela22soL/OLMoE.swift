import SwiftUI

struct ModalView<Content: View>: View {
    let allowOutsideTapDismiss: Bool
    let content: Content
    @Binding var isPresented: Bool
    let showCloseButton: Bool
    @State var contentHeight: CGFloat = .infinity

    init(isPresented: Binding<Bool>,
         allowOutsideTapDismiss: Bool = true,
         showCloseButton: Bool = true,
         @ViewBuilder content: () -> Content) {
        self.allowOutsideTapDismiss = allowOutsideTapDismiss
        self.content = content()
        self._isPresented = isPresented
        self.showCloseButton = showCloseButton
    }

    var body: some View {
        if isPresented {
            GeometryReader { proxy in
                ZStack {
                    Color.black.opacity(0.5)
                        .edgesIgnoringSafeArea(.all)
                        .contentShape(Rectangle())  // Make entire overlay tappable
                        .onTapGesture {
                            if allowOutsideTapDismiss {
                                isPresented = false
                            }
                        }

                    VStack(spacing: 0) {
                        if showCloseButton {
                            HStack {
                                Spacer()
                                Button(action: { isPresented = false }) {
                                    Image(systemName: "xmark.circle")
                                        .font(.system(size: 20))
                                        .frame(width: 40, height: 40)
                                        .foregroundColor(Color("TextColor"))
                                }
                                .clipShape(Circle())
                            }
                        }

                        ScrollView {
                            content
                                .padding(.top, showCloseButton ? 0 : 24)
                                .background(
                                    GeometryReader { geo in
                                        Color.clear
                                            .onAppear() {
                                                contentHeight = geo.size.height
                                            }
                                    })
                        }
                        .id(UUID()) // Force unique ID so onAppear gets updated height and scrolls to top
                        .frame(maxHeight: min(contentHeight, proxy.size.height - 100))
                        .padding(.bottom, 24)
                    }
                    .frame(minWidth: 300, maxWidth: min(600, proxy.size.width - 48))
                    .padding(.horizontal, 12)
                    .background(Color("Surface"))
                    .cornerRadius(12)
                }
            }
        }
    }
}

#Preview("Basic Modal") {
    ModalView(isPresented: .constant(true)) {
      VStack(spacing: 16) {
        Text("Sample Title")
            .font(.title)
        Text("This is a sample modal content with some text that might wrap to multiple lines.")
            .padding()
      }
    }
}

#Preview("Complex Modal") {
    ModalView(isPresented: .constant(true)) {
        VStack(spacing: 16) {
            Image(systemName: "star.fill")
                .font(.system(size: 50))
                .foregroundColor(.yellow)

            Text("Complex Title")
                .font(.title)

            Text("This is a more complex modal with multiple elements.")

            Button("Sample Action") { }
                .buttonStyle(.PrimaryButton)
        }
        .padding()
    }
}

#Preview("Modal with No Close Button") {
    ModalView(
        isPresented: .constant(true),
        allowOutsideTapDismiss: false,
        showCloseButton: false
    ) {
      VStack(spacing: 16) {
          Text("Complex Title")
                .font(.title)
          Text("This modal can only be closed programmatically")
              .padding()
        }
    }
}
