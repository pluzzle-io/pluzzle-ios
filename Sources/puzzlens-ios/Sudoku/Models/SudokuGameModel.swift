import Foundation

/// The data model for a Sudoku puzzle, containing the starting grid and its solution.
///
/// Pass a `SudokuGameModel` to ``SudokuGameView`` to define the initial puzzle state.
/// Pre-filled cells (non-`nil`) are locked and displayed as fixed. Empty cells (`nil`) are editable.
///
/// ```swift
/// let model = SudokuGameModel(
///     grid: [
///         [5, 3, nil,  nil, 7, nil,  nil, nil, nil],
///         // …
///     ],
///     solution: [
///         [5, 3, 4,  6, 7, 8,  9, 1, 2],
///         // …
///     ]
/// )
/// ```
public struct SudokuGameModel {
    /// The puzzle's starting state. Pre-filled cells hold an `Int` value (1–9); empty cells are `nil`.
    public var grid: [[Int?]]
    /// The complete, correct solution. Every cell must contain an `Int` value (1–9).
    public var solution: [[Int]]

    /// Creates a new Sudoku game model.
    ///
    /// - Parameters:
    ///   - grid: The initial grid. Use `nil` for cells the player must fill in.
    ///   - solution: The fully solved grid used to check the player's answers.
    public init(grid: [[Int?]], solution: [[Int]]) {
        self.grid = grid
        self.solution = solution
    }

    /// A ready-made 9×9 puzzle with a few empty cells, for use in previews and testing.
    @MainActor public static let example: SudokuGameModel = .init(
        grid: [
            [nil, 3, 4, 6, 7, 8, 9, 1, 2],
            [6, 7, 2, 1, 9, 5, 3, 4, 8],
            [1, 9, 8, 3, 4, 2, 5, 6, 7],

            [8, nil, nil, 7, 6, 1, 4, 2, 3],
            [4, 2, 6, 8, 5, 3, 7, 9, 1],
            [7, 1, 3, 9, 2, 4, 8, 5, 6],

            [9, 6, 1, 5, 3, 7, 2, 8, 4],
            [2, 8, 7, 4, 1, 9, nil, 3, 5],
            [3, 4, 5, 2, 8, 6, 1, 7, 9]
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
        ]
    )
}
