import Foundation

/// A type that provides the data for a Sudoku puzzle.
///
/// Conform to this protocol to supply a custom model to ``SudokuGameView``:
///
/// ```swift
/// struct MySudokuModel: SudokuGameModelProtocol {
///     var grid: [[Int?]]
///     var solution: [[Int]]
///     var state: [[Int?]]
///     var notes: [[Set<Int>]]?
///
///     mutating func reset() {
///         state = grid
///         notes = nil
///     }
/// }
///
/// @State private var model = MySudokuModel(…)
///
/// SudokuGameView(model: $model)
/// ```
///
/// `isComplete` and `isCorrect` are provided automatically via a protocol extension —
/// override them only if you need custom logic.
public protocol SudokuGameModelProtocol: Sendable {
    /// The puzzle's starting state. Pre-filled cells hold an `Int` value (1–9); empty cells are `nil`.
    var grid: [[Int?]] { get }
    /// The complete, correct solution. Every cell must contain an `Int` value (1–9).
    var solution: [[Int]] { get }
    /// The player's current grid state. Updated live as the player fills in cells.
    var state: [[Int?]] { get set }
    /// Per-cell pencil marks. `nil` until the first note is written.
    var notes: [[Set<Int>]]? { get set }
    /// Resets the player's state back to the initial grid and clears all notes.
    mutating func reset()
}

public extension SudokuGameModelProtocol {
    /// Reveals one randomly chosen empty editable cell by filling it with its solution value.
    ///
    /// An "empty editable" cell is one where `grid[r][c] == nil` (not a given) and
    /// `state[r][c] == nil` (not yet filled by the player). If no such cell exists this
    /// method is a no-op.
    mutating func revealHint() {
        var candidates: [(row: Int, col: Int)] = []
        for r in grid.indices {
            for c in grid[r].indices {
                guard grid[r][c] == nil, state[r][c] == nil else { continue }
                candidates.append((r, c))
            }
        }
        guard let chosen = candidates.randomElement() else { return }
        state[chosen.row][chosen.col] = solution[chosen.row][chosen.col]
    }

    /// `true` when every cell has been filled (regardless of correctness).
    var isComplete: Bool {
        guard state.count == grid.count else { return false }
        return grid.indices.allSatisfy { r in
            guard r < state.count, state[r].count == grid[r].count else { return false }
            return grid[r].indices.allSatisfy { c in state[r][c] != nil }
        }
    }

    /// `true` when every cell's entry matches the solution.
    var isCorrect: Bool {
        guard state.count == grid.count, solution.count == grid.count else { return false }
        return grid.indices.allSatisfy { r in
            guard r < state.count, r < solution.count,
                  state[r].count == grid[r].count,
                  solution[r].count == grid[r].count else { return false }
            return grid[r].indices.allSatisfy { c in state[r][c] == solution[r][c] }
        }
    }
}
