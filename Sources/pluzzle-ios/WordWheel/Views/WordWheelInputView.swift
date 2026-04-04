import SwiftUI

/// The default input display for ``WordWheelView``.
///
/// Shows the word currently being built in a bold title font inside a rounded
/// glass-material banner. When no letters have been selected the banner renders
/// a non-breaking space so its height stays constant.
///
/// Replace this with a custom view via the `.inputView(cell:)` modifier:
///
/// ```swift
/// WordWheelView(model: model)
///     .inputView(MyInputView.self)
/// ```
public struct WordWheelInputView: View, WordWheelInputViewProtocol {
    public let word: String
    public let isValid: Bool
    public let letterCount: Int

    public init(word: String, isValid: Bool, letterCount: Int) {
        self.word = word
        self.isValid = isValid
        self.letterCount = letterCount
    }

    public var body: some View {
        Text(word.isEmpty ? " " : word)
            .font(.title.bold())
            .kerning(4)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
