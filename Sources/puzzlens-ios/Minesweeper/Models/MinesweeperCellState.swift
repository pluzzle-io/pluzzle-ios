import Foundation

/// The display state of a single cell in a Minesweeper grid.
public enum MinesweeperCellState: Equatable, Hashable, Sendable {
    /// The cell has not been revealed or flagged yet.
    case hidden

    /// The cell has been safely revealed. `adjacentMines` is the count of mines in the 8 surrounding cells (0–8).
    case revealed(adjacentMines: Int)

    /// The player has flagged this cell as a suspected mine. Flagged cells cannot be revealed by tap.
    case flagged

    /// The player tapped this cell and it contained a mine, ending the game.
    case exploded

    /// A mine that was not tapped, revealed automatically when the game ends.
    case mineRevealed
}
