import Foundation

/// The data model for a KelvinGrid puzzle.
///
/// - `targetWord`    — The word the player is trying to guess (always uppercased internally).
/// - `maxAttempts`   — Maximum number of guess rows (default: 6).
/// - `currentGuesses`— Previously submitted guesses, used to restore a saved session.
public struct KelvinGridModel {
    public let targetWord: String
    public let maxAttempts: Int
    public var currentGuesses: [String]

    /// Number of columns in the grid — equal to the length of `targetWord`.
    public var columns: Int { targetWord.count }

    public init(targetWord: String, maxAttempts: Int = 6, currentGuesses: [String] = []) {
        self.targetWord = targetWord.uppercased()
        self.maxAttempts = maxAttempts
        self.currentGuesses = currentGuesses.map { $0.uppercased() }
    }

    // MARK: - Evaluation

    /// Evaluates a guess against the target word and returns a `KelvinCellState` for each position.
    ///
    /// Evaluation rules (applied in priority order):
    /// 1. **Green** (`.correct`)   — letter matches the target letter at this position.
    /// 2. **Orange** (`.misplaced`) — letter exists in the target word but at a different position.
    /// 3. **Gray** (`.wrong(offset)`) — letter is not in the word; `offset` is the signed
    ///    alphabetical distance (`guessLetter − correctLetter`): positive means the guessed letter
    ///    comes after the correct letter in the alphabet, negative means before.
    public static func evaluate(guess: String, target: String) -> [KelvinCellState] {
        let guessChars = Array(guess.uppercased())
        let targetChars = Array(target.uppercased())
        let count = min(guessChars.count, targetChars.count)

        var result = Array(repeating: KelvinCellState.wrong(0), count: count)
        var targetUsed = Array(repeating: false, count: count)
        var guessUsed = Array(repeating: false, count: count)

        // Pass 1: exact matches
        for i in 0..<count where guessChars[i] == targetChars[i] {
            result[i] = .correct
            targetUsed[i] = true
            guessUsed[i] = true
        }

        // Pass 2: misplaced letters
        for i in 0..<count where !guessUsed[i] {
            for j in 0..<count where !targetUsed[j] {
                if guessChars[i] == targetChars[j] {
                    result[i] = .misplaced
                    targetUsed[j] = true
                    guessUsed[i] = true
                    break
                }
            }
        }

        // Pass 3: wrong — compute signed alphabetical offset (guess − target)
        for i in 0..<count where !guessUsed[i] {
            guard let guessVal = guessChars[i].asciiValue,
                  let targetVal = targetChars[i].asciiValue else { continue }
            let offset = Int(guessVal) - Int(targetVal)
            result[i] = .wrong(offset)
        }

        return result
    }

    // MARK: - Example

    /// A ready-made puzzle for use in previews and testing.
    @MainActor public static let example = KelvinGridModel(
        targetWord: "USMAN",
        maxAttempts: 5
    )
}
