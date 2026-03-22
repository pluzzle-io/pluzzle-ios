import Foundation

/// The data model for a Sudoku puzzle, containing the starting grid, solution, and live player state.
///
/// Hold a `SudokuGameModel` as `@State` in a parent view and pass it to ``SudokuGameView``
/// via a binding — any cell the player fills in is written back automatically.
///
/// ```swift
/// @State private var model = SudokuGameModel(
///     grid: [
///         [5, 3, nil, nil, 7, nil, nil, nil, nil],
///         // …
///     ],
///     solution: [
///         [5, 3, 4, 6, 7, 8, 9, 1, 2],
///         // …
///     ]
/// )
///
/// var body: some View {
///     SudokuGameView(model: $model)
/// }
/// ```
public struct SudokuGameModel: SudokuGameModelProtocol {
    /// The puzzle's starting state. Pre-filled cells hold an `Int` value (1–9); empty cells are `nil`.
    public var grid: [[Int?]]
    /// The complete, correct solution. Every cell must contain an `Int` value (1–9).
    public var solution: [[Int]]
    /// The player's current grid state. Updated live as the player fills in cells.
    /// Pre-filled (fixed) cells retain their initial values; editable cells start as `nil`.
    public var state: [[Int?]]

    /// Per-cell pencil marks. `nil` until the first note is written.
    /// Each `Set<Int>` holds the candidate digits (1–9) the player has marked for that cell.
    public var notes: [[Set<Int>]]?

    /// Creates a new Sudoku game model.
    ///
    /// - Parameters:
    ///   - grid: The initial grid. Use `nil` for cells the player must fill in.
    ///   - solution: The fully solved grid used to check the player's answers.
    ///   - state: The player's current grid state. Defaults to `grid` (no progress) if omitted.
    public init(grid: [[Int?]], solution: [[Int]], state: [[Int?]]? = nil) {
        self.grid = grid
        self.solution = solution
        self.state = state ?? grid
        self.notes = nil
    }

    /// Resets the player's state back to the initial grid and clears all notes.
    public mutating func reset() {
        state = grid
        notes = nil
    }

    /// A ready-made 9×9 puzzle with some cells already filled, for use in previews and testing.
    public static let example: SudokuGameModel = .init(
        grid: [
            [  5, nil, nil, nil,   7, nil, nil, nil, nil],
            [nil,   7, nil,   1, nil, nil, nil,   4, nil],
            [  1, nil, nil, nil, nil,   2, nil, nil,   7],

            [nil,   5, nil,   7, nil, nil, nil, nil,   3],
            [nil, nil,   6, nil,   5, nil,   7, nil, nil],
            [  7, nil, nil, nil, nil,   4, nil, nil, nil],

            [nil, nil,   1, nil,   3, nil, nil, nil,   4],
            [nil,   8, nil, nil, nil,   9, nil, nil, nil],
            [nil, nil, nil,   2, nil, nil,   1, nil,   9],
        ],
        solution: [
            [5, 3, 4, 6, 7, 8, 9, 1, 2],
            [6, 7, 2, 1, 9, 5, 3, 4, 8],
            [1, 9, 8, 3, 4, 2, 5, 6, 7],

            [8, 5, 9, 7, 6, 1, 4, 2, 3],
            [4, 2, 6, 8, 5, 3, 7, 9, 1],
            [7, 1, 3, 9, 2, 4, 8, 5, 6],

            [9, 6, 1, 5, 3, 7, 2, 8, 4],
            [2, 8, 7, 4, 1, 9, 6, 3, 5],
            [3, 4, 5, 2, 8, 6, 1, 7, 9]
        ],
        state: [
            [  5,   3,   4,   6,   7,   8,   9,   1,   2],
            [  6,   7,   2,   1,   9,   5, nil,   4, nil],
            [  1,   9,   8,   3,   4,   2, nil, nil,   7],

            [  8,   5, nil,   7,   6, nil, nil, nil,   3],
            [nil, nil,   6, nil,   5, nil,   7, nil, nil],
            [  7, nil, nil, nil, nil,   4, nil, nil, nil],

            [nil, nil,   1, nil,   3, nil, nil, nil,   4],
            [nil,   8, nil, nil, nil,   9, nil, nil, nil],
            [nil, nil, nil,   2, nil, nil,   1, nil,   9],
        ]
    )
}
