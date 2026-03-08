import SwiftUI

public struct WordWheelView: View {
    private let model: WordWheelModel

    // MARK: - State

    /// Ordered list of wheel positions selected for the current word.
    /// -1 = main letter, 0...n = index into model.letters.
    @State private var wordPositions: [Int] = []

    /// Words successfully found so far. Pre-seeded from model.currentAnswers.
    @State private var foundWords: [String] = []

    // MARK: - Factories (default implementations)

    private var letterCellFactory: (_ letter: String, _ isMain: Bool, _ isUsed: Bool, _ onTap: @escaping () -> Void) -> AnyView =
    { letter, isMain, isUsed, onTap in
        AnyView(WordWheelLetterCell(letter: letter, isMain: isMain, isUsed: isUsed, onTap: onTap))
    }

    private var actionButtonFactory: (_ label: String, _ onTap: @escaping () -> Void) -> AnyView =
    { label, onTap in
        AnyView(WordWheelActionButton(label: label, onTap: onTap))
    }

    // MARK: - Callbacks

    private var onWordSubmittedCallback: ((_ word: String, _ isValid: Bool) -> Void)? = nil
    private var onCompletionCallback: (() -> Void)? = nil

    // MARK: - Init

    public init(model: WordWheelModel) {
        self.model = model
        self._foundWords = State(initialValue: model.currentAnswers.map { $0.lowercased() })
    }

    // MARK: - Derived

    /// The word currently being built, assembled from selected wheel positions.
    private var currentWord: String {
        wordPositions.map { pos in
            pos == -1 ? model.mainLetter : (model.letters[safe: pos] ?? "")
        }.joined()
    }

    private func isPositionUsed(_ pos: Int) -> Bool {
        wordPositions.contains(pos)
    }

    // MARK: - Body

    public var body: some View {
        VStack(spacing: 24) {
            // Current word display
            currentWordDisplay

            // The wheel
            wheelView

            // Action buttons: Delete / Submit / Clear
            actionRow

            // Found words
            foundWordsDisplay
        }
        .padding()
    }

    // MARK: - Subviews

    private var currentWordDisplay: some View {
        Text(currentWord.isEmpty ? " " : currentWord)
            .font(.title.bold())
            .kerning(4)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var wheelView: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let cellSize = size * 0.18
            let radius = size * 0.36
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)

            ZStack {
                surroundingLetters(cellSize: cellSize, radius: radius, center: center)
                mainLetterTile(cellSize: cellSize, center: center)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    @ViewBuilder
    private func surroundingLetters(cellSize: CGFloat, radius: CGFloat, center: CGPoint) -> some View {
        ForEach(Array(model.letters.enumerated()), id: \.offset) { index, letter in
            surroundingTile(letter: letter, index: index, cellSize: cellSize, radius: radius, center: center)
        }
    }

    private func surroundingTile(letter: String, index: Int, cellSize: CGFloat, radius: CGFloat, center: CGPoint) -> some View {
        let angle = (2 * .pi / Double(model.letters.count)) * Double(index) - (.pi / 2)
        let x = center.x + cos(angle) * radius
        let y = center.y + sin(angle) * radius
        return letterCellFactory(letter, false, isPositionUsed(index)) { selectPosition(index) }
            .frame(width: cellSize, height: cellSize)
            .position(x: x, y: y)
    }

    private func mainLetterTile(cellSize: CGFloat, center: CGPoint) -> some View {
        letterCellFactory(model.mainLetter, true, isPositionUsed(-1)) { selectPosition(-1) }
            .frame(width: cellSize * 1.2, height: cellSize * 1.2)
            .position(x: center.x, y: center.y)
    }

    private var actionRow: some View {
        HStack(spacing: 12) {
            actionButtonFactory("Delete") { deleteLast() }
            actionButtonFactory("Submit") { submitWord() }
            actionButtonFactory("Clear")  { clearWord() }
        }
    }

    private var foundWordsDisplay: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Found: \(foundWords.count) / \(model.acceptableAnswers.count)")
                .font(.caption)
                .foregroundStyle(.secondary)

            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 8) {
                    ForEach(foundWords.sorted(), id: \.self) { word in
                        Text(word.capitalized)
                            .font(.subheadline)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.green.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
            .frame(maxHeight: 140)
        }
    }

    // MARK: - Word Building

    private func selectPosition(_ pos: Int) {
        guard !isPositionUsed(pos) else { return }
        wordPositions.append(pos)
    }

    private func deleteLast() {
        guard !wordPositions.isEmpty else { return }
        wordPositions.removeLast()
    }

    private func clearWord() {
        wordPositions.removeAll()
    }

    // MARK: - Submission

    private func submitWord() {
        let word = currentWord.lowercased()
        guard !word.isEmpty else { return }

        let isValid = model.acceptableAnswers.contains(word) && !foundWords.contains(word)
        onWordSubmittedCallback?(word, isValid)

        if isValid {
            foundWords.append(word)
            if foundWords.count == model.acceptableAnswers.count {
                onCompletionCallback?()
            }
        }

        clearWord()
    }

    // MARK: - Modifiers

    /// Replace the default letter tile with a custom view conforming to `WordWheelLetterCellProtocol`.
    public func letterCell<T: WordWheelLetterCellProtocol>(cell: T.Type) -> Self {
        var copy = self
        copy.letterCellFactory = { letter, isMain, isUsed, onTap in
            AnyView(T(letter: letter, isMain: isMain, isUsed: isUsed, onTap: onTap))
        }
        return copy
    }

    /// Replace the default action buttons (Submit / Delete / Clear) with a custom view
    /// conforming to `WordWheelActionButtonProtocol`.
    public func actionButton<T: WordWheelActionButtonProtocol>(cell: T.Type) -> Self {
        var copy = self
        copy.actionButtonFactory = { label, onTap in
            AnyView(T(label: label, onTap: onTap))
        }
        return copy
    }

    /// Called each time the player submits a word.
    /// - Parameters:
    ///   - handler: Receives the submitted word and whether it was a valid, new answer.
    public func onWordSubmitted(_ handler: @escaping (_ word: String, _ isValid: Bool) -> Void) -> Self {
        var copy = self
        copy.onWordSubmittedCallback = handler
        return copy
    }

    /// Called when the player has found every acceptable answer.
    public func onCompletion(_ handler: @escaping () -> Void) -> Self {
        var copy = self
        copy.onCompletionCallback = handler
        return copy
    }
}
