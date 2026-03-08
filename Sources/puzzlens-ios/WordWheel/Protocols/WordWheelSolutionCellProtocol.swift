import SwiftUI

/// A view that represents a single found word in the solutions list.
///
/// Conform to this protocol to supply a custom solution cell to `WordWheelView`
/// via the `.solutionCell(cell:)` modifier.
///
/// - `word` — The found word to display (lowercased).
public protocol WordWheelSolutionCellProtocol: View {
    init(word: String)
}
