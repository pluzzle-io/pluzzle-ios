import SwiftUI

/// A view that represents a single letter tile on the word wheel.
///
/// Conform to this protocol to supply a custom letter tile to `WordWheelView`
/// via the `.letterCell(cell:)` modifier.
///
/// - `letter`  — The letter displayed on this tile (always uppercased).
/// - `isMain`  — `true` when this tile is the centre/main letter.
/// - `isUsed`  — `true` when this specific tile has already been tapped as part
///               of the word currently being built, so it cannot be tapped again.
/// - `onTap`   — Call this when the tile is tapped.
public protocol WordWheelLetterCellProtocol: View {
    init(letter: String, isMain: Bool, isUsed: Bool, onTap: @escaping () -> Void)
}
