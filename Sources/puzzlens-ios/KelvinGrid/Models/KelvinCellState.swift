/// Represents the evaluation state of a single cell in a KelvinGrid row.
public enum KelvinCellState: Equatable, Hashable {
    /// No letter has been typed.
    case empty
    /// A letter has been typed but the row has not been submitted yet.
    case pending
    /// The letter is correct and in the correct position. Displayed in green.
    case correct
    /// The letter appears in the target word but at a different position. Displayed in orange.
    case misplaced
    /// The letter is not in the target word.
    /// `offset` is the signed alphabetical distance from the correct letter:
    /// positive means the guessed letter comes *after* the correct letter in the alphabet,
    /// negative means it comes *before*. Displayed in gray with a `+N` / `−N` hint.
    case wrong(Int)
}
