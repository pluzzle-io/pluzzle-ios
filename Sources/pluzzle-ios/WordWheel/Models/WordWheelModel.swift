import Foundation

/// The data model for a Word Wheel puzzle.
///
/// Describes the centre letter and the surrounding wheel letters.
/// Answer validation and found-word tracking are the responsibility of the parent view.
public struct WordWheelModel {
    /// The letter at the centre of the wheel. Every valid word must contain this letter.
    public var mainLetter: String

    /// The letters arranged around the wheel (excluding the main letter).
    public var letters: [String]

    /// Creates a new Word Wheel model.
    ///
    /// - Parameters:
    ///   - mainLetter: The centre letter. Stored uppercased.
    ///   - letters: The surrounding wheel letters (excluding the centre). Stored uppercased.
    public init(
        mainLetter: String,
        letters: [String]
    ) {
        self.mainLetter = mainLetter.uppercased()
        self.letters = letters.map { $0.uppercased() }
    }

    // MARK: - Example

    /// A ready-made puzzle for use in previews and testing.
    ///
    /// Centre letter: **E** | Wheel: R A T H N G S
    @MainActor public static let example = WordWheelModel(
        mainLetter: "E",
        letters: ["R", "A", "T", "H", "N", "G", "S"]
    )
}
