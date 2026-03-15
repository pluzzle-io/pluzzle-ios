import Foundation

public enum MinesweeperCellState: Equatable, Hashable {
    case hidden
    case revealed(adjacentMines: Int)
    case flagged
    case exploded       // Mine tapped by the player
    case mineRevealed   // Other mines revealed on game over
}
