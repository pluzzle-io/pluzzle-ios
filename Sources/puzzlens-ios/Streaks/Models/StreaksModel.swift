import SwiftUI

/// A coordinate identifying a single cell in a Streaks grid.
public struct StreaksCoord: Hashable, Equatable {
    public let row: Int
    public let col: Int

    public init(row: Int, col: Int) {
        self.row = row
        self.col = col
    }
}

/// Data model for a Streaks puzzle.
public struct StreaksModel {
    /// Number of rows in the grid.
    public let rows: Int
    /// Number of columns in the grid.
    public let columns: Int
    /// Cells that cannot be visited and do not count toward completion.
    public let blockedCells: Set<StreaksCoord>
    /// Number of cells the player must connect (total minus blocked).
    public var totalCells: Int { rows * columns - blockedCells.count }

    public init(rows: Int, columns: Int, blockedCells: Set<StreaksCoord> = []) {
        self.rows = rows
        self.columns = columns
        self.blockedCells = blockedCells
    }

    /// Returns `true` if the given coordinate is blocked.
    public func isBlocked(row: Int, col: Int) -> Bool {
        blockedCells.contains(StreaksCoord(row: row, col: col))
    }

    @MainActor public static let example = StreaksModel(
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
