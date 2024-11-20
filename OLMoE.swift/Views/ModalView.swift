import SwiftUI

struct ModalView<Content: View>: View {
    let content: Content
    @Binding var isPresented: Bool
    let showCloseButton: Bool
    let allowOutsideTapDismiss: Bool

    init(isPresented: Binding<Bool>,
        showCloseButton: Bool = true,
        allowOutsideTapDismiss: Bool = true,
        @ViewBuilder content: () -> Content) {
        self.content = content()
        self._isPresented = isPresented
        self.showCloseButton = showCloseButton
        self.allowOutsideTapDismiss = allowOutsideTapDismiss
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .edgesIgnoringSafeArea(.all)
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
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(Color("TextColor"))
                        }
                    }
                  .padding()
                .background(Color("Surface"))
                }

                ScrollView {
                    content
                        .padding()
                        .frame(maxWidth: .infinity)
                }
                .background(Color("Surface"))
            }
            .frame(maxWidth: 300, maxHeight: 600)
            .background(Color("Surface"))
            .cornerRadius(12)
            .padding(.horizontal, 20)
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
                .padding()
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(8)
        }
        .padding()
    }
}

#Preview("Modal with No Close Button") {
    ModalView(
        isPresented: .constant(true),
        showCloseButton: false,
        allowOutsideTapDismiss: false
    ) {
      VStack(spacing: 16) {
          Text("Complex Title")
                .font(.title)
        Text("This modal can only be closed programmatically")
            .padding()
        }
    }
}
