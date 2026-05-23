import Foundation

/// A zero-based row/column coordinate identifying a cell in a ``MinesweeperModel`` grid.
public struct MinesweeperCoord: Hashable, Equatable, Sendable, Codable {
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
///
/// // Fully deterministic board from an integer seed
/// let model = MinesweeperModel(rows: 9, columns: 9, mineCount: 10, seed: 42)
/// // model.startingCoord gives a safe, zero-adjacency cell to open from
/// ```
public struct MinesweeperModel: Sendable, Codable {
    /// Number of rows in the grid.
    public let rows: Int
    /// Number of columns in the grid.
    public let columns: Int
    /// Total number of mines to place. Ignored when `mines` is non-empty.
    public let mineCount: Int
    /// Pre-placed mine positions. Leave empty to auto-generate on the first tap (safe-start guaranteed).
    public let mines: Set<MinesweeperCoord>
    /// How mines are placed when auto-generating. Defaults to ``MinesweeperGenerationMode/random``.
    public let generationMode: MinesweeperGenerationMode
    /// A recommended starting cell derived from the seed initialiser.
    ///
    /// When a model is created with ``init(rows:columns:mineCount:seed:)`` this is a mine-free cell,
    /// preferring one with zero adjacent mines so an opening flood-fill is triggered immediately.
    /// For all other initialisers this is `nil`.
    public let startingCoord: MinesweeperCoord?

    // MARK: - Runtime state

    /// Per-cell display state. Dimensions: `rows × columns`. All cells start as `.hidden`.
    public var cellStates: [[MinesweeperCellState]]
    /// The active mine positions for this game session.
    /// May differ from `mines` when mines were auto-generated on the first tap.
    public var activeMines: Set<MinesweeperCoord>
    /// Count of safely revealed cells.
    public var score: Int
    /// `true` once the game has ended (win or loss).
    public var isGameOver: Bool
    /// `true` = player won, `false` = player lost, `nil` = game still in progress.
    public var didWin: Bool?

    // MARK: - Computed

    /// Total number of safe (non-mine) cells based on the active mine set.
    public var totalSafe: Int { rows * columns - activeMines.count }

    /// Creates a new model.
    ///
    /// - Parameters:
    ///   - rows: Number of rows.
    ///   - columns: Number of columns.
    ///   - mineCount: How many mines to place when auto-generating. Ignored if `mines` is non-empty.
    ///   - mines: Optional pre-placed mine positions. Pass an empty set (the default) to auto-generate.
    ///   - generationMode: How mines are placed when auto-generating. Defaults to ``MinesweeperGenerationMode/random``.
    public init(
        rows: Int,
        columns: Int,
        mineCount: Int,
        mines: Set<MinesweeperCoord> = [],
        generationMode: MinesweeperGenerationMode = .random,
        cellStates: [[MinesweeperCellState]]? = nil,
        activeMines: Set<MinesweeperCoord>? = nil,
        score: Int = 0,
        isGameOver: Bool = false,
        didWin: Bool? = nil
    ) {
        self.rows = rows
        self.columns = columns
        self.mineCount = mineCount
        self.mines = mines
        self.generationMode = generationMode
        self.startingCoord = nil
        self.cellStates = cellStates ?? Array(
            repeating: Array(repeating: .hidden, count: columns),
            count: rows
        )
        self.activeMines = activeMines ?? mines
        self.score = score
        self.isGameOver = isGameOver
        self.didWin = didWin
    }

    /// Creates a fully deterministic model from an integer seed.
    ///
    /// Both the mine layout (solution) and a recommended opening cell (starting point) are derived
    /// from `seed` using a Xorshift64 pseudo-random number generator, so the same seed always
    /// produces the same board — useful for shareable puzzles, daily challenges, or reproducible
    /// testing scenarios.
    ///
    /// The ``startingCoord`` property returns the recommended first cell to reveal. It is always
    /// mine-free and, when possible, has zero adjacent mines so the reveal flood-fills outward
    /// immediately.
    ///
    /// ```swift
    /// let model = MinesweeperModel(rows: 9, columns: 9, mineCount: 10, seed: 42)
    ///
    /// // Use the suggested starting cell in the view
    /// if let start = model.startingCoord {
    ///     // e.g. pre-reveal or highlight that cell
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - rows: Number of rows.
    ///   - columns: Number of columns.
    ///   - mineCount: How many mines to place.
    ///   - seed: An integer seed. The same value always produces the same mine layout and starting cell.
    public init(
        rows: Int,
        columns: Int,
        mineCount: Int,
        seed: Int,
        cellStates: [[MinesweeperCellState]]? = nil,
        activeMines: Set<MinesweeperCoord>? = nil,
        score: Int = 0,
        isGameOver: Bool = false,
        didWin: Bool? = nil
    ) {
        self.rows = rows
        self.columns = columns
        self.mineCount = mineCount
        self.generationMode = .random  // mines are pre-placed; auto-generation won't fire

        // Build candidate list in a stable row-major order
        var candidates: [MinesweeperCoord] = []
        for r in 0..<rows {
            for c in 0..<columns {
                candidates.append(MinesweeperCoord(row: r, col: c))
            }
        }

        // Shuffle with the seeded RNG to determine mine placement
        var rng = SeededRNG(seed: UInt64(bitPattern: Int64(seed)))
        candidates.shuffle(using: &rng)
        let placedMines = Set(candidates.prefix(min(mineCount, candidates.count)))
        self.mines = placedMines

        // Determine the starting cell: prefer a non-mine cell with zero adjacent mines,
        // falling back to any non-mine cell if none has zero adjacency.
        let tempModel = _MinesweeperGeometry(rows: rows, columns: columns)

        var zeroCells: [MinesweeperCoord] = []
        var safeCells: [MinesweeperCoord] = []

        for r in 0..<rows {
            for c in 0..<columns {
                let coord = MinesweeperCoord(row: r, col: c)
                guard !placedMines.contains(coord) else { continue }
                safeCells.append(coord)
                let adjCount = tempModel.neighbors(of: coord).filter { placedMines.contains($0) }.count
                if adjCount == 0 { zeroCells.append(coord) }
            }
        }

        // Shuffle each candidate pool with the same RNG so the starting cell is also seed-stable
        zeroCells.shuffle(using: &rng)
        safeCells.shuffle(using: &rng)

        if let first = zeroCells.first {
            self.startingCoord = first
        } else if let first = safeCells.first {
            self.startingCoord = first
        } else {
            // Degenerate: every cell is mined
            self.startingCoord = nil
        }
        self.cellStates = cellStates ?? Array(
            repeating: Array(repeating: .hidden, count: columns),
            count: rows
        )
        self.activeMines = activeMines ?? placedMines
        self.score = score
        self.isGameOver = isGameOver
        self.didWin = didWin
    }

    /// Resets the game state to its initial values, ready for a new game.
    ///
    /// - Clears all cell states back to `.hidden`.
    /// - Restores `activeMines` to the pre-placed `mines` set (auto-generated sets are discarded).
    /// - Zeroes `score`, `isGameOver`, and `didWin`.
    public mutating func reset() {
        cellStates = Array(
            repeating: Array(repeating: .hidden, count: columns),
            count: rows
        )
        activeMines = mines
        score = 0
        isGameOver = false
        didWin = nil
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

    /// Places `mineCount` mines across the grid, excluding every coord in `safeZone`.
    ///
    /// Placement strategy is determined by ``generationMode``:
    /// - ``MinesweeperGenerationMode/random``: uses the system RNG — no two calls produce the same layout.
    /// - ``MinesweeperGenerationMode/seeded(_:)``: derives a seed from the date's day, month, and year
    ///   so the same calendar date always produces the same layout.
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
        switch generationMode {
        case .random:
            candidates.shuffle()
        case .seeded(let date):
            var rng = SeededRNG(seed: Self.seed(from: date))
            candidates.shuffle(using: &rng)
        }
        return Set(candidates.prefix(min(mineCount, candidates.count)))
    }

    /// Derives a deterministic UInt64 seed from the day, month, and year of `date`.
    private static func seed(from date: Date) -> UInt64 {
        let cal = Calendar(identifier: .gregorian)
        let c = cal.dateComponents([.day, .month, .year], from: date)
        let y = UInt64(c.year  ?? 2024)
        let m = UInt64(c.month ?? 1)
        let d = UInt64(c.day   ?? 1)
        return y * 10_000 + m * 100 + d
    }

    /// A 9×9 beginner-level example with 10 mines. Mines are auto-generated on first tap.
    public static let example = MinesweeperModel(rows: 9, columns: 9, mineCount: 10)
}

// MARK: - SeededRNG

/// A Xorshift64 pseudo-random number generator used for deterministic mine placement.
private struct SeededRNG: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        // Xorshift requires a non-zero state; use a safe fallback if seed is zero.
        state = seed == 0 ? 6_364_136_223_846_793_005 : seed
    }

    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}

// MARK: - _MinesweeperGeometry

/// A lightweight grid-geometry helper used inside `MinesweeperModel.init(seed:)` to compute
/// neighbor lists before `self` is fully initialised.
private struct _MinesweeperGeometry {
    let rows: Int
    let columns: Int

    func neighbors(of coord: MinesweeperCoord) -> [MinesweeperCoord] {
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
}
