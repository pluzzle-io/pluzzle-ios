import SwiftUI

/// A view that represents a single letter tile on the word wheel.
///
/// Conform to this protocol to supply a custom letter tile to ``WordWheelView``
/// via the `.input(cell:)` modifier.
///
/// ```swift
/// struct MyTile: WordWheelLetterCellProtocol {
///     let letter: String
///     let isMain: Bool
///     let isUsed: Bool
///     let onTap: () -> Void
///
///     init(letter: String, isMain: Bool, isUsed: Bool, onTap: @escaping () -> Void) {
///         self.letter = letter; self.isMain = isMain
///         self.isUsed = isUsed; self.onTap = onTap
///     }
///
///     var body: some View { … }
/// }
///
/// WordWheelView(model: model)
///     .input(cell: MyTile.self)
/// ```
public protocol WordWheelLetterCellProtocol: View {
    /// Creates a letter tile for the given letter and interaction state.
    ///
    /// - Parameters:
    ///   - letter: The letter displayed on this tile (always uppercased).
    ///   - isMain: `true` when this tile is the centre/main letter.
    ///   - isUsed: `true` when this tile has already been selected for the current word attempt
    ///     and therefore cannot be tapped again until the word is submitted or cleared.
    ///   - onTap: Call this closure when the tile is tapped (only when `isUsed` is `false`).
    init(letter: String, isMain: Bool, isUsed: Bool, onTap: @escaping () -> Void)
}
