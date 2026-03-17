extension Array {
    /// Returns the element at `index`, or `nil` if the index is out of bounds.
    ///
    /// Use this subscript wherever an out-of-range index is a recoverable condition
    /// rather than a programmer error.
    ///
    /// ```swift
    /// let items = [1, 2, 3]
    /// items[safe: 1]  // 2
    /// items[safe: 9]  // nil
    /// ```
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
