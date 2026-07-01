import Foundation

/// The display state of a single cell in a Minesweeper grid.
public enum MinesweeperCellState: Equatable, Hashable, Sendable, Codable {
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

    /// A hidden cell that is eligible to be tapped safely during an active hint. The view sets
    /// all hidden cells to this state while hint mode is active so the cell renderer can
    /// distinguish them visually. Reverts to ``hidden`` as soon as the player taps.
    case hintEligible

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case type
        case adjacentMines
    }

    private enum TypeKey: String, Codable {
        case hidden, revealed, flagged, exploded, mineRevealed, hintEligible
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(TypeKey.self, forKey: .type)
        switch type {
        case .hidden:         self = .hidden
        case .revealed:
            let adj = try container.decode(Int.self, forKey: .adjacentMines)
            self = .revealed(adjacentMines: adj)
        case .flagged:        self = .flagged
        case .exploded:       self = .exploded
        case .mineRevealed:   self = .mineRevealed
        case .hintEligible:   self = .hintEligible
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .hidden:
            try container.encode(TypeKey.hidden, forKey: .type)
        case .revealed(let adj):
            try container.encode(TypeKey.revealed, forKey: .type)
            try container.encode(adj, forKey: .adjacentMines)
        case .flagged:
            try container.encode(TypeKey.flagged, forKey: .type)
        case .exploded:
            try container.encode(TypeKey.exploded, forKey: .type)
        case .mineRevealed:
            try container.encode(TypeKey.mineRevealed, forKey: .type)
        case .hintEligible:
            try container.encode(TypeKey.hintEligible, forKey: .type)
        }
    }
}
