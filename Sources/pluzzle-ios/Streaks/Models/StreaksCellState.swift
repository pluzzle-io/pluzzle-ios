import SwiftUI

/// The selection state of a single cell in a Streaks grid.
public enum StreaksCellState: Equatable, Hashable, Sendable {
    /// The cell has not yet been visited.
    case unselected
    /// The cell has been visited; `order` is its 1-based position in the path.
    case selected(order: Int)
    /// The cell is permanently blocked and cannot be part of the path.
    case blocked
}
