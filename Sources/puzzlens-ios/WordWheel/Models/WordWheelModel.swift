import Foundation

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
    /// Centre letter: E  |  Wheel: R A T H N G S
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
