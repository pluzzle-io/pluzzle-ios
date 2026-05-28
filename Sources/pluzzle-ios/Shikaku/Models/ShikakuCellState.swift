import Foundation

/// The display state of a single cell in a Shikaku grid.
///
/// Passed to ``ShikakuCellProtocol`` implementations so custom cells can render all relevant
/// visual information without needing direct access to ``ShikakuModel``.
public struct ShikakuCellState: Equatable, Hashable, Sendable {
    /// The clue number shown in this cell, or `nil` if the cell is blank.
    public let clue: Int?
    /// The rectangle this cell belongs to, or `nil` if the cell is not yet covered.
    public let rect: ShikakuRect?
    /// `true` when this cell is the top-left corner of its rectangle (used to draw border labels).
    public let isRectOrigin: Bool
    /// `true` when the rectangle covering this cell violates a puzzle rule (wrong area or contains
    /// multiple clues). Useful for showing inline error feedback.
    public let isViolation: Bool
    /// `true` when this cell is part of the rectangle currently being drawn by the player's drag.
    public let isPreview: Bool

    public init(
        clue: Int? = nil,
        rect: ShikakuRect? = nil,
        isRectOrigin: Bool = false,
        isViolation: Bool = false,
        isPreview: Bool = false
    ) {
        self.clue = clue
        self.rect = rect
        self.isRectOrigin = isRectOrigin
        self.isViolation = isViolation
        self.isPreview = isPreview
    }
}
