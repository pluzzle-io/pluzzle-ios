import SwiftUI

/// A view that displays the word currently being built by the player.
///
/// Conform to this protocol to supply a custom input display to ``WordWheelView``
/// via the `.inputView(cell:)` modifier.
///
/// ```swift
/// struct MyInputView: WordWheelInputViewProtocol {
///     let word: String
///     let isValid: Bool
///     let letterCount: Int
///
///     init(word: String, isValid: Bool, letterCount: Int) {
///         self.word = word
///         self.isValid = isValid
///         self.letterCount = letterCount
///     }
///
///     var body: some View { … }
/// }
///
/// WordWheelView(model: model)
///     .inputView(MyInputView.self)
/// ```
public protocol WordWheelInputViewProtocol: View {
    /// Creates an input view for the current word-building state.
    ///
    /// - Parameters:
    ///   - word: The word currently being built (uppercased). Empty string when no letters are selected.
    ///   - isValid: `true` when the current word is present in `acceptableAnswers` and has not yet
    ///     been found. Recomputed live on every letter tap.
    ///   - letterCount: Total number of letters on the wheel — surrounding letters plus the main letter.
    init(word: String, isValid: Bool, letterCount: Int)
}
