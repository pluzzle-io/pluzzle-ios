import SwiftUI

/// A zero-based row/column coordinate identifying a single cell in a ``StreaksGameView`` grid.
public struct StreaksCoord: Hashable, Equatable, Sendable {
    /// Zero-based row index (top = 0).
    public let row: Int
    /// Zero-based column index (left = 0).
    public let col: Int

    /// Creates a coordinate at the given row and column.
    public init(row: Int, col: Int) {
        self.row = row
        self.col = col
    }
}

/// Data model for a Streaks puzzle.
///
/// Pass a `StreaksModel` to ``StreaksGameView`` to define the grid dimensions and which cells
/// are permanently blocked. Blocked cells are skipped by the player's path and do not count
/// toward the total cell count.
///
/// ```swift
/// let model = StreaksModel(
///     rows: 5,
///     columns: 5,
///     blockedCells: [StreaksCoord(row: 2, col: 2)]
/// )
/// ```
public struct StreaksModel: Sendable {
    /// Number of rows in the grid.
    public let rows: Int
    /// Number of columns in the grid.
    public let columns: Int
    /// Cells that cannot be visited and do not count toward completion.
    public let blockedCells: Set<StreaksCoord>
    /// The number of cells the player must connect to complete the puzzle (total minus blocked).
    public var totalCells: Int { rows * columns - blockedCells.count }

    /// Creates a new Streaks model.
    ///
    /// - Parameters:
    ///   - rows: Number of rows in the grid.
    ///   - columns: Number of columns in the grid.
    ///   - blockedCells: Cells that are permanently impassable. Defaults to an empty set.
    public init(rows: Int, columns: Int, blockedCells: Set<StreaksCoord> = []) {
        self.rows = rows
        self.columns = columns
        self.blockedCells = blockedCells
    }

    /// Returns `true` if the cell at the given row and column is blocked.
    public func isBlocked(row: Int, col: Int) -> Bool {
        blockedCells.contains(StreaksCoord(row: row, col: col))
    }

    /// A 5×5 ready-made puzzle with four blocked corner-adjacent cells, for use in previews and testing.
    public static let example = StreaksModel(
        rows: 5,
        columns: 5,
        blockedCells: [
            StreaksCoord(row: 1, col: 1),
            StreaksCoord(row: 1, col: 3),
            StreaksCoord(row: 3, col: 1),
            StreaksCoord(row: 3, col: 3)
        ]
    )
}
