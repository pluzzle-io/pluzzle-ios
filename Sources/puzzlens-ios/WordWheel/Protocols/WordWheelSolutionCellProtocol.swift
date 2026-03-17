import SwiftUI

/// A view that represents a single found word in the solutions list.
///
/// Conform to this protocol to supply a custom solution cell to ``WordWheelView``
/// via the `.solutionCell(cell:)` modifier.
///
/// ```swift
/// struct MySolutionCell: WordWheelSolutionCellProtocol {
///     let word: String
///
///     init(word: String) { self.word = word }
///
///     var body: some View { … }
/// }
///
/// WordWheelView(model: model)
///     .solutionCell(cell: MySolutionCell.self)
/// ```
public protocol WordWheelSolutionCellProtocol: View {
    /// Creates a solution cell for the given found word.
    ///
    /// - Parameter word: The found word to display (always lowercased).
    init(word: String)
}
