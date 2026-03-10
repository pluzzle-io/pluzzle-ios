import SwiftUI

/// A view that represents a single cell in the Streaks grid.
///
/// Conform to this protocol to supply a custom cell to `StreaksGameView`
/// via the `.grid(spacing:cell:)` modifier.
///
/// - `row` — Zero-based row index.
/// - `column` — Zero-based column index.
/// - `state` — The current selection state of the cell.
public protocol StreaksCellProtocol: View {
    init(row: Int, column: Int, state: StreaksCellState)
}
