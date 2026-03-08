/// Represents the evaluation state of a single cell in a KelvinGrid row.
public enum KelvinCellState: Equatable, Hashable {
    /// No letter has been typed.
    case empty
    /// A letter has been typed but the row has not been submitted yet.
    case pending
    /// The letter is correct and in the correct position. Displayed in green.
    case correct
    /// The letter appears in the target word but at a different position. Displayed in red.
    case misplaced
    /// The letter is not in the target word but is within `distance` alphabetical steps
    /// of the correct letter for this position (1 ≤ distance ≤ 5).
    /// Displayed in a shade interpolated from yellow (close) to gray (far).
    case warm(Int)
    /// The letter is not in the target word and is more than 5 alphabetical steps
    /// from the correct letter for this position. Displayed in dark gray.
    case cold
}
