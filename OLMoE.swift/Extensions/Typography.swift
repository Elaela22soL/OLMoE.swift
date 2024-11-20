import SwiftUI

extension Font {
    static func modalTitle() -> Font {
        .system(size: 28, weight: .medium)
    }

    static func modalBody() -> Font {
        .system(size: 16, weight: .regular)
    }

    static func modalButton() -> Font {
        .system(size: 17, weight: .semibold)
    }
}