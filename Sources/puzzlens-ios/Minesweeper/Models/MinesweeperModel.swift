import Foundation

/// A zero-based row/column coordinate identifying a cell in a ``MinesweeperModel`` grid.
public struct MinesweeperCoord: Hashable, Equatable, Sendable {
    /// Zero-based row index (top = 0).
    public let row: Int
    /// Zero-based column index (left = 0).
    public let col: Int

    public init(row: Int, col: Int) {
        self.row = row
        self.col = col
    }
}

/// Immutable data model for a Minesweeper game.
///
/// Pass a `MinesweeperModel` to ``MinesweeperGameView`` to configure the grid size and mine count.
/// Mines can be pre-placed via `mines`, or omitted to let the view auto-generate them on the player's
/// first tap (guaranteeing a safe opening).
///
/// ```swift
/// // Auto-generated mines — safe start guaranteed
/// let model = MinesweeperModel(rows: 9, columns: 9, mineCount: 10)
///
/// // Pre-placed mines for a deterministic layout
/// let model = MinesweeperModel(rows: 5, columns: 5, mineCount: 3, mines: [
///     MinesweeperCoord(row: 0, col: 2),
///     MinesweeperCoord(row: 3, col: 1),
///     MinesweeperCoord(row: 4, col: 4),
/// ])
/// ```
public struct MinesweeperModel: Sendable {
    /// Number of rows in the grid.
    public let rows: Int
    /// Number of columns in the grid.
    public let columns: Int
    /// Total number of mines to place. Ignored when `mines` is non-empty.
    public let mineCount: Int
    /// Pre-placed mine positions. Leave empty to auto-generate on the first tap (safe-start guaranteed).
    public let mines: Set<MinesweeperCoord>

    /// Creates a new model.
    ///
    /// - Parameters:
    ///   - rows: Number of rows.
    ///   - columns: Number of columns.
    ///   - mineCount: How many mines to place when auto-generating. Ignored if `mines` is non-empty.
    ///   - mines: Optional pre-placed mine positions. Pass an empty set (the default) to auto-generate.
    public init(
        rows: Int,
        columns: Int,
        mineCount: Int,
        mines: Set<MinesweeperCoord> = []
    ) {
        self.rows = rows
        self.columns = columns
        self.mineCount = mineCount
        self.mines = mines
    }

    /// Returns all valid 8-directional neighbors of `coord` that lie within the grid bounds.
    public func neighbors(of coord: MinesweeperCoord) -> [MinesweeperCoord] {
        var result: [MinesweeperCoord] = []
        for dr in -1...1 {
            for dc in -1...1 {
                guard dr != 0 || dc != 0 else { continue }
                let r = coord.row + dr
                let c = coord.col + dc
                guard r >= 0, r < rows, c >= 0, c < columns else { continue }
                result.append(MinesweeperCoord(row: r, col: c))
            }
        }
        return result
    }

    /// Returns the number of mines from `mines` that are directly adjacent to `coord`.
    ///
    /// - Parameters:
    ///   - coord: The cell to check.
    ///   - mines: The active mine set to count against.
    public func adjacentMineCount(for coord: MinesweeperCoord, in mines: Set<MinesweeperCoord>) -> Int {
        neighbors(of: coord).filter { mines.contains($0) }.count
    }

    /// Randomly places `mineCount` mines across the grid, excluding every coord in `safeZone`.
    ///
    /// Used internally by ``MinesweeperGameView`` on the first tap to guarantee a safe opening.
    /// - Parameter safeZone: Cells that must not receive a mine (typically the tapped cell + its neighbors).
    /// - Returns: A set of mine coordinates of size `min(mineCount, eligibleCells.count)`.
    public func generateMines(avoiding safeZone: Set<MinesweeperCoord>) -> Set<MinesweeperCoord> {
        var candidates: [MinesweeperCoord] = []
        for r in 0..<rows {
            for c in 0..<columns {
                let coord = MinesweeperCoord(row: r, col: c)
                if !safeZone.contains(coord) { candidates.append(coord) }
            }
        }
        candidates.shuffle()
        return Set(candidates.prefix(min(mineCount, candidates.count)))
    }

    /// A 9×9 beginner-level example with 10 mines. Mines are auto-generated on first tap.
    @MainActor public static let example = MinesweeperModel(rows: 9, columns: 9, mineCount: 10)
}
