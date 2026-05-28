import Foundation

/// A zero-based row/column coordinate identifying a cell in a ``ShikakuModel`` grid.
public struct ShikakuCoord: Hashable, Equatable, Sendable, Codable {
    /// Zero-based row index (top = 0).
    public let row: Int
    /// Zero-based column index (left = 0).
    public let col: Int

    public init(row: Int, col: Int) {
        self.row = row
        self.col = col
    }
}

/// An axis-aligned rectangle in a Shikaku grid, identified by its top-left corner and dimensions.
public struct ShikakuRect: Hashable, Equatable, Sendable, Codable {
    /// Zero-based row of the top-left cell.
    public let row: Int
    /// Zero-based column of the top-left cell.
    public let col: Int
    /// Number of rows the rectangle spans (≥ 1).
    public let rowSpan: Int
    /// Number of columns the rectangle spans (≥ 1).
    public let colSpan: Int

    public init(row: Int, col: Int, rowSpan: Int, colSpan: Int) {
        self.row = row
        self.col = col
        self.rowSpan = rowSpan
        self.colSpan = colSpan
    }

    /// Area of the rectangle (= `rowSpan × colSpan`).
    public var area: Int { rowSpan * colSpan }

    /// Returns `true` when `coord` lies inside this rectangle.
    public func contains(_ coord: ShikakuCoord) -> Bool {
        coord.row >= row && coord.row < row + rowSpan &&
        coord.col >= col && coord.col < col + colSpan
    }

    /// Returns `true` when this rectangle does not overlap with `other`.
    public func isDisjoint(from other: ShikakuRect) -> Bool {
        row + rowSpan <= other.row ||
        other.row + other.rowSpan <= row ||
        col + colSpan <= other.col ||
        other.col + other.colSpan <= col
    }
}

/// Immutable data model for a Shikaku puzzle.
///
/// Shikaku is played on a rectangular grid. Some cells contain a positive integer clue.
/// The goal is to partition the entire grid into non-overlapping rectangles so that:
/// - Every rectangle contains exactly one numbered clue.
/// - The rectangle's area equals that clue number.
///
/// Create a model by providing `rows`, `columns`, and the clue cells (a sparse dictionary mapping
/// coordinates to their integer clues). Player progress is stored in `rects`.
///
/// ```swift
/// let model = ShikakuModel(
///     rows: 5,
///     columns: 5,
///     clues: [
///         ShikakuCoord(row: 0, col: 0): 4,
///         ShikakuCoord(row: 0, col: 3): 6,
///         // …
///     ]
/// )
/// ```
///
/// Use `ShikakuModel.example` for a ready-made 5×7 puzzle.
public struct ShikakuModel: Sendable, Codable {

    // MARK: - Configuration

    /// Number of rows in the grid.
    public let rows: Int
    /// Number of columns in the grid.
    public let columns: Int
    /// Clue cells. Keys are coordinates; values are the required rectangle area for that cell.
    public let clues: [ShikakuCoord: Int]

    // MARK: - Live state

    /// The set of rectangles the player has placed so far.
    public var rects: [ShikakuRect]
    /// `true` once the puzzle has been solved correctly.
    public var isSolved: Bool

    // MARK: - Computed helpers

    /// Returns the rectangle (if any) that contains `coord` in the current player state.
    public func rect(at coord: ShikakuCoord) -> ShikakuRect? {
        rects.first { $0.contains(coord) }
    }

    /// Returns `true` when all placed rectangles are valid and the grid is fully covered.
    ///
    /// Validity requires:
    /// 1. Every rectangle lies within the grid bounds.
    /// 2. No two rectangles overlap.
    /// 3. Each rectangle contains exactly one clue whose value equals the rectangle's area.
    /// 4. Every cell is covered by exactly one rectangle.
    public var isComplete: Bool {
        // All rects in bounds
        for r in rects {
            guard r.row >= 0, r.col >= 0,
                  r.row + r.rowSpan <= rows,
                  r.col + r.colSpan <= columns else { return false }
        }
        // No overlaps
        for i in rects.indices {
            for j in (i + 1)..<rects.count {
                guard rects[i].isDisjoint(from: rects[j]) else { return false }
            }
        }
        // Each rect has exactly one clue with matching area
        for r in rects {
            let cluesInside = clues.filter { r.contains($0.key) }
            guard cluesInside.count == 1, cluesInside.values.first == r.area else { return false }
        }
        // Full coverage
        let totalCells = rows * columns
        let coveredCells = rects.reduce(0) { $0 + $1.area }
        return coveredCells == totalCells
    }

    // MARK: - Init

    /// Creates a new Shikaku model.
    ///
    /// - Parameters:
    ///   - rows: Number of rows in the grid.
    ///   - columns: Number of columns in the grid.
    ///   - clues: Sparse dictionary of clue coordinates and their required rectangle areas.
    ///   - rects: The player's current rectangle placements. Defaults to empty.
    ///   - isSolved: Initial solved flag. Defaults to `false`.
    public init(
        rows: Int,
        columns: Int,
        clues: [ShikakuCoord: Int],
        rects: [ShikakuRect] = [],
        isSolved: Bool = false
    ) {
        self.rows = rows
        self.columns = columns
        self.clues = clues
        self.rects = rects
        self.isSolved = isSolved
    }

    // MARK: - Mutations

    /// Resets all player progress, clearing every placed rectangle.
    public mutating func reset() {
        rects = []
        isSolved = false
    }

    /// Places `rect` in the grid, removing any existing rectangles that overlap with it first.
    ///
    /// After placing, checks whether the puzzle is now complete and updates `isSolved`.
    public mutating func place(_ rect: ShikakuRect) {
        rects.removeAll { !$0.isDisjoint(from: rect) }
        rects.append(rect)
        if isComplete { isSolved = true }
    }

    /// Removes the rectangle that covers `coord`, if any.
    public mutating func removeRect(at coord: ShikakuCoord) {
        rects.removeAll { $0.contains(coord) }
        isSolved = false
    }

    // MARK: - Example

    /// A ready-to-use 9×6 Shikaku puzzle for use in previews and testing.
    ///
    /// 9 rows × 6 columns = 54 cells. cols/rows = 6/9 = 2/3, so the grid fills a 2:3 portrait
    /// container exactly with square cells. Clue values sum to 54. Verified solution:
    ///
    /// ```
    ///  col: 0 1 2 3 4 5
    ///  r 0: A A B B C C    A (6)  rows 0-2 cols 0-1
    ///  r 1: A A B B C C    B (4)  rows 0-1 cols 2-3
    ///  r 2: A A D D C C    C (6)  rows 0-2 cols 4-5
    ///  r 3: E E D D F F    D (6)  rows 2-4 cols 2-3
    ///  r 4: E E D D F F    E (6)  rows 3-5 cols 0-1
    ///  r 5: E E G G F F    F (6)  rows 3-5 cols 4-5
    ///  r 6: H H G G I I    G (6)  rows 5-7 cols 2-3
    ///  r 7: H H G G I I    H (6)  rows 6-8 cols 0-1
    ///  r 8: H H J J J J    I (4)  rows 6-7 cols 4-5
    ///                       J (4)  row  8   cols 2-5
    /// ```
    public static let example = ShikakuModel(
        rows: 9,
        columns: 6,
        clues: [
            ShikakuCoord(row: 0, col: 1): 6,  // A
            ShikakuCoord(row: 1, col: 2): 4,  // B
            ShikakuCoord(row: 2, col: 4): 6,  // C
            ShikakuCoord(row: 4, col: 3): 6,  // D
            ShikakuCoord(row: 3, col: 0): 6,  // E
            ShikakuCoord(row: 5, col: 5): 6,  // F
            ShikakuCoord(row: 7, col: 2): 6,  // G
            ShikakuCoord(row: 6, col: 1): 6,  // H
            ShikakuCoord(row: 7, col: 4): 4,  // I
            ShikakuCoord(row: 8, col: 4): 4,  // J
        ]
    )
}

// MARK: - Codable

extension ShikakuCoord {
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        row = try container.decode(Int.self)
        col = try container.decode(Int.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(row)
        try container.encode(col)
    }
}

extension ShikakuModel {
    // Custom Codable for [ShikakuCoord: Int] — encode as array of {coord, value} pairs.
    private enum CodingKeys: String, CodingKey {
        case rows, columns, clues, rects, isSolved
    }

    private struct CluePair: Codable {
        let coord: ShikakuCoord
        let value: Int
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        rows = try container.decode(Int.self, forKey: .rows)
        columns = try container.decode(Int.self, forKey: .columns)
        let pairs = try container.decode([CluePair].self, forKey: .clues)
        clues = Dictionary(uniqueKeysWithValues: pairs.map { ($0.coord, $0.value) })
        rects = try container.decode([ShikakuRect].self, forKey: .rects)
        isSolved = try container.decode(Bool.self, forKey: .isSolved)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(rows, forKey: .rows)
        try container.encode(columns, forKey: .columns)
        let pairs = clues.map { CluePair(coord: $0.key, value: $0.value) }
        try container.encode(pairs, forKey: .clues)
        try container.encode(rects, forKey: .rects)
        try container.encode(isSolved, forKey: .isSolved)
    }
}
