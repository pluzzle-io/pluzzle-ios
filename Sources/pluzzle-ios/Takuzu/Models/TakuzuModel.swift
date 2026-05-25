import Foundation

/// An immutable data model for a Takuzu (Binairo) binary puzzle.
///
/// Takuzu is played on an even-sided square grid. Each cell holds one of two binary
/// values — represented as `true` (e.g. "1") or `false` (e.g. "0") — or is empty (`nil`).
/// A valid solution satisfies three constraints:
///
/// 1. **Balance** — each row and each column contains an equal number of `true` and `false` values.
/// 2. **No triples** — no more than two consecutive identical values in any row or column.
/// 3. **Uniqueness** — all rows are distinct, and all columns are distinct.
///
/// Create a model by providing `size`, the fixed (given) cells, and the complete solution:
///
/// ```swift
/// let model = TakuzuModel(
///     size: 6,
///     cells: [
///         [true,  nil,  false, nil,  nil,  true ],
///         [nil,   false, nil,  true, nil,  nil  ],
///         // …
///     ],
///     solution: [
///         [true,  true,  false, false, true,  false],
///         [true,  false, true,  true,  false, false],
///         // …
///     ]
/// )
/// ```
///
/// Use `TakuzuModel.example` for a ready-made 6×6 puzzle.
public struct TakuzuModel: Sendable {

    // MARK: - Configuration

    /// The side length of the square grid. Must be a positive even number (e.g. 4, 6, 8, 10).
    public let size: Int

    /// The starting puzzle state. `nil` cells are blank and player-editable;
    /// non-`nil` cells are fixed givens that cannot be changed.
    /// Dimensions: `size × size`.
    public let cells: [[Bool?]]

    /// The complete correct solution. All cells must be non-`nil`.
    /// Dimensions: `size × size`.
    public let solution: [[Bool?]]

    // MARK: - Live state

    /// The player's current grid. Fixed cells retain their given values; empty cells start as `nil`.
    /// Updated as the player taps cells. Dimensions: `size × size`.
    public var state: [[Bool?]]

    // MARK: - Computed helpers

    /// Returns `true` if every cell in `state` is non-`nil`.
    public var isComplete: Bool {
        state.allSatisfy { row in row.allSatisfy { $0 != nil } }
    }

    /// Returns `true` if `state` matches `solution` exactly.
    public var isCorrect: Bool {
        guard isComplete else { return false }
        return (0..<size).allSatisfy { r in
            (0..<size).allSatisfy { c in state[r][c] == solution[r][c] }
        }
    }

    /// Returns the set of coordinates that currently violate a Takuzu rule.
    ///
    /// A coordinate is flagged when:
    /// - Its row or column has more than `size/2` copies of either value, or
    /// - It is part of three or more consecutive identical values in its row or column, or
    /// - Its completed row or column is a duplicate of another row or column.
    ///
    /// Only cells that have been filled in are checked; `nil` cells are never flagged.
    public var violations: Set<TakuzuCoord> {
        var result: Set<TakuzuCoord> = []
        let half = size / 2

        // Per-row checks
        for r in 0..<size {
            let row = state[r]
            // Balance
            let trueCount  = row.compactMap { $0 }.filter { $0  }.count
            let falseCount = row.compactMap { $0 }.filter { !$0 }.count
            if trueCount > half || falseCount > half {
                for c in 0..<size where row[c] != nil {
                    result.insert(TakuzuCoord(row: r, col: c))
                }
            }
            // No-triples
            for c in 0..<(size - 2) {
                if let a = row[c], let b = row[c+1], let cc = row[c+2], a == b, b == cc {
                    result.insert(TakuzuCoord(row: r, col: c))
                    result.insert(TakuzuCoord(row: r, col: c + 1))
                    result.insert(TakuzuCoord(row: r, col: c + 2))
                }
            }
        }

        // Per-column checks
        for c in 0..<size {
            let col = (0..<size).map { state[$0][c] }
            // Balance
            let trueCount  = col.compactMap { $0 }.filter { $0  }.count
            let falseCount = col.compactMap { $0 }.filter { !$0 }.count
            if trueCount > half || falseCount > half {
                for r in 0..<size where col[r] != nil {
                    result.insert(TakuzuCoord(row: r, col: c))
                }
            }
            // No-triples
            for r in 0..<(size - 2) {
                if let a = col[r], let b = col[r+1], let cc = col[r+2], a == b, b == cc {
                    result.insert(TakuzuCoord(row: r,     col: c))
                    result.insert(TakuzuCoord(row: r + 1, col: c))
                    result.insert(TakuzuCoord(row: r + 2, col: c))
                }
            }
        }

        // Uniqueness — only flag fully filled duplicate rows / columns
        let fullRows = (0..<size).filter { r in state[r].allSatisfy { $0 != nil } }
        for i in 0..<fullRows.count {
            for j in (i+1)..<fullRows.count {
                let r1 = fullRows[i], r2 = fullRows[j]
                if state[r1].elementsEqual(state[r2], by: { $0 == $1 }) {
                    for c in 0..<size {
                        result.insert(TakuzuCoord(row: r1, col: c))
                        result.insert(TakuzuCoord(row: r2, col: c))
                    }
                }
            }
        }
        let fullCols = (0..<size).filter { c in (0..<size).allSatisfy { state[$0][c] != nil } }
        for i in 0..<fullCols.count {
            for j in (i+1)..<fullCols.count {
                let c1 = fullCols[i], c2 = fullCols[j]
                let col1 = (0..<size).map { state[$0][c1] }
                let col2 = (0..<size).map { state[$0][c2] }
                if col1.elementsEqual(col2, by: { $0 == $1 }) {
                    for r in 0..<size {
                        result.insert(TakuzuCoord(row: r, col: c1))
                        result.insert(TakuzuCoord(row: r, col: c2))
                    }
                }
            }
        }

        return result
    }

    // MARK: - Init

    /// Creates a Takuzu model.
    ///
    /// - Parameters:
    ///   - size: Side length of the square grid. Must be a positive even number.
    ///   - cells: The initial puzzle. `nil` = blank/editable, non-`nil` = fixed given.
    ///   - solution: The complete correct answer grid.
    ///   - state: The player's current state. Defaults to `cells` (no progress) when `nil`.
    public init(size: Int, cells: [[Bool?]], solution: [[Bool?]], state: [[Bool?]]? = nil) {
        self.size = size
        self.cells = cells
        self.solution = solution
        self.state = state ?? cells
    }

    // MARK: - Mutations

    /// Resets the player's state back to the original `cells`, discarding all progress.
    public mutating func reset() {
        state = cells
    }

    /// Returns `true` if the cell at `(row, col)` is a fixed given (cannot be edited by the player).
    public func isFixed(row: Int, col: Int) -> Bool {
        cells[row][col] != nil
    }

    // MARK: - Example

    /// A ready-to-use 6×6 Takuzu puzzle for use in previews and testing.
    ///
    /// The fixed givens are spread to make the deduction chain interesting.
    /// Solution satisfies all three Takuzu rules.
    public static let example = TakuzuModel(
        size: 6,
        cells: [
        //    c0      c1     c2     c3     c4     c5
        /* r0 */ [true,  nil,   nil,   false, nil,   nil  ],
        /* r1 */ [nil,   nil,   true,  nil,   nil,   false],
        /* r2 */ [nil,   false, nil,   nil,   true,  nil  ],
        /* r3 */ [false, nil,   nil,   true,  nil,   nil  ],
        /* r4 */ [nil,   nil,   false, nil,   true,  nil  ],
        /* r5 */ [nil,   true,  nil,   nil,   false, nil  ],
        ],
        solution: [
        /* r0 */ [true,  true,  false, false, true,  false],
        /* r1 */ [true,  false, true,  true,  false, false],
        /* r2 */ [false, false, true,  false, true,  true ],
        /* r3 */ [false, true,  false, true,  false, true ],
        /* r4 */ [true,  false, false, true,  true,  false],
        /* r5 */ [false, true,  true,  false, false, true ],
        ]
    )
}

// MARK: - TakuzuCoord

/// A zero-based row/column coordinate identifying a cell in a ``TakuzuModel`` grid.
public struct TakuzuCoord: Hashable, Equatable, Sendable {
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
