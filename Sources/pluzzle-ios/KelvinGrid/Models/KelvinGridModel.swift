import Foundation

/// The data model for a KelvinGrid puzzle.
///
/// Pass a `KelvinGridModel` to ``KelvinGridView`` to define the target word, attempt limit,
/// and any previously submitted guesses for session restore.
///
/// ```swift
/// // Fresh game
/// let model = KelvinGridModel(targetWord: "SWIFT", maxAttempts: 6)
///
/// // Restore a saved session
/// let model = KelvinGridModel(
///     targetWord: "SWIFT",
///     maxAttempts: 6,
///     currentGuesses: ["CRANE", "SHIRT"]
/// )
/// ```
public struct KelvinGridModel {
    /// The word the player is trying to guess. Always stored uppercased.
    public let targetWord: String
    /// Maximum number of guess rows (default: `6`).
    public let maxAttempts: Int
    /// Previously submitted guesses, used to restore a saved session.
    public var currentGuesses: [String]

    /// Number of columns in the grid — equal to the character count of `targetWord`.
    public var columns: Int { targetWord.count }

    /// Creates a new KelvinGrid model.
    ///
    /// - Parameters:
    ///   - targetWord: The word the player must guess. Stored uppercased.
    ///   - maxAttempts: Maximum number of rows available to the player. Defaults to `6`.
    ///   - currentGuesses: Any previously submitted guesses to restore. Defaults to empty.
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

    /// A ready-made 5-letter puzzle with 5 attempts, for use in previews and testing.
    @MainActor public static let example = KelvinGridModel(
        targetWord: "USMAN",
        maxAttempts: 5
    )
}
