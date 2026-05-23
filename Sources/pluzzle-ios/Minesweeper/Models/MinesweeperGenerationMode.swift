import Foundation

/// Controls how mines are placed when a ``MinesweeperModel`` auto-generates on the first tap.
public enum MinesweeperGenerationMode: Sendable, Codable {
    /// Places mines using a random source each time. No two games are alike.
    case random

    /// Places mines using a seed derived from the given date's day, month, and year.
    ///
    /// The same calendar date always produces the same board layout, regardless of when the
    /// game is started — useful for daily puzzles or shareable challenges.
    ///
    /// ```swift
    /// // Today's puzzle
    /// MinesweeperModel(rows: 9, columns: 9, mineCount: 10, generationMode: .seeded(Date()))
    ///
    /// // A specific date
    /// let date = Calendar(identifier: .gregorian).date(from: DateComponents(year: 2026, month: 3, day: 22))!
    /// MinesweeperModel(rows: 9, columns: 9, mineCount: 10, generationMode: .seeded(date))
    /// ```
    case seeded(Date)
}
