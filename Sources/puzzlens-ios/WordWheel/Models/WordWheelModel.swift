import Foundation

/// The data model for a Word Wheel puzzle.
///
/// Describes the centre letter, the surrounding wheel letters, the full set of acceptable
/// answers, and any words already found in a restored session.
public struct WordWheelModel {
    /// The letter at the centre of the wheel. Every valid word must contain this letter.
    public var mainLetter: String

    /// The letters arranged around the wheel (excluding the main letter).
    public var letters: [String]

    /// Words the player has already found in this session.
    public var currentAnswers: [String]

    /// All words that are acceptable solutions for this puzzle.
    /// Each entry should be lowercase. Every word must contain `mainLetter`.
    public var acceptableAnswers: [String]

    /// Creates a new Word Wheel model.
    ///
    /// - Parameters:
    ///   - mainLetter: The centre letter. Stored uppercased. Every valid answer must contain this letter.
    ///   - letters: The surrounding wheel letters (excluding the centre). Stored uppercased.
    ///   - currentAnswers: Words already found in a saved session. Defaults to empty.
    ///   - acceptableAnswers: All valid solutions. Stored lowercased. Every entry should contain `mainLetter`.
    public init(
        mainLetter: String,
        letters: [String],
        currentAnswers: [String] = [],
        acceptableAnswers: [String]
    ) {
        self.mainLetter = mainLetter.uppercased()
        self.letters = letters.map { $0.uppercased() }
        self.currentAnswers = currentAnswers
        self.acceptableAnswers = acceptableAnswers.map { $0.lowercased() }
    }

    // MARK: - Example

    /// A ready-made puzzle for use in previews and testing.
    ///
    /// Centre letter: **E** | Wheel: R A T H N G S
    @MainActor public static let example = WordWheelModel(
        mainLetter: "E",
        letters: ["R", "A", "T", "H", "N", "G", "S"],
        acceptableAnswers: [
            "earth", "heart", "hare", "hate", "rate",
            "gate", "grate", "great", "stare", "share",
            "shear", "haste", "anger", "range", "snare"
        ]
    )
}
