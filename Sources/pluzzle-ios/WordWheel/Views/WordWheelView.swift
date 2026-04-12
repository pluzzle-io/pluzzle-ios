import SwiftUI

/// A SwiftUI view that presents a fully interactive Word Wheel puzzle.
///
/// Provide a ``WordWheelModel`` and optionally chain builder modifiers before inserting
/// the view into the hierarchy:
///
/// ```swift
/// WordWheelView(model: model)
///     .inputView(MyInputView.self)
///     .input(cell: MyTile.self)
///     .actionButton(cell: MyButton.self)
///     .onWordSubmitted { word in print(word) }
/// ```
///
/// ### Interactions
/// - **Tap** letter tiles to spell a word; each physical tile can only be used once per attempt.
/// - The centre main letter tile is always available.
/// - Tap **Submit** to validate the current word, **Delete** to remove the last letter,
///   or **Clear** to reset the attempt.
public struct WordWheelView: View {
    private let model: WordWheelModel

    // MARK: - Layout configuration

    private var gridRadius: CGFloat? = nil

    // MARK: - State

    /// Ordered list of wheel positions selected for the current word attempt.
    /// `-1` represents the main/centre letter; values `0...n` are indices into `model.letters`.
    @State private var wordPositions: [Int] = []

    // MARK: - Factories (default implementations)

    private var inputFactory: (_ letter: String, _ isMain: Bool, _ isUsed: Bool, _ onTap: @escaping () -> Void) -> AnyView =
    { letter, isMain, isUsed, onTap in
        AnyView(WordWheelLetterCell(letter: letter, isMain: isMain, isUsed: isUsed, onTap: onTap))
    }

    private var actionButtonFactory: (_ label: String, _ onTap: @escaping () -> Void) -> AnyView =
    { label, onTap in
        AnyView(WordWheelActionButton(label: label, onTap: onTap))
    }

    private var inputViewFactory: (_ word: String, _ isValid: Bool, _ letterCount: Int) -> AnyView =
    { word, isValid, _ in
        AnyView(
            Text(word.isEmpty ? " " : word)
                .font(.title.bold())
                .kerning(4)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        )
    }

    // MARK: - Callbacks

    private var onWordSubmittedCallback: ((_ word: String) -> Void)? = nil

    // MARK: - Init

    /// Creates a new Word Wheel view with the given model.
    ///
    /// Apply `.input(cell:)`, `.actionButton(cell:)`, and `.onWordSubmitted(_:)` modifiers
    /// before inserting the view into the hierarchy.
    ///
    /// - Parameter model: The ``WordWheelModel`` defining the puzzle letters.
    public init(model: WordWheelModel) {
        self.model = model
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
            inputViewFactory(currentWord, false, model.letters.count + 1)

            // The wheel
            wheelView

            // Action buttons: Delete / Submit / Clear
            actionRow
        }
        .padding()
    }

    // MARK: - Subviews

    private var wheelView: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let cellSize = size * 0.18
            let radius = gridRadius ?? (size * 0.36)
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
        return inputFactory(letter, false, isPositionUsed(index)) { selectPosition(index) }
            .frame(width: cellSize, height: cellSize)
            .position(x: x, y: y)
    }

    private func mainLetterTile(cellSize: CGFloat, center: CGPoint) -> some View {
        inputFactory(model.mainLetter, true, isPositionUsed(-1)) { selectPosition(-1) }
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
        onWordSubmittedCallback?(word)
        clearWord()
    }

    // MARK: - Modifiers

    /// Replace the default input display with a custom view conforming to `WordWheelInputViewProtocol`.
    public func inputView<T: WordWheelInputViewProtocol>(cell: T.Type) -> Self {
        var copy = self
        copy.inputViewFactory = { word, isValid, letterCount in
            AnyView(T(word: word, isValid: isValid, letterCount: letterCount))
        }
        return copy
    }

    /// Replace the default letter tile with a custom view conforming to `WordWheelLetterCellProtocol`.
    public func input<T: WordWheelLetterCellProtocol>(cell: T.Type) -> Self {
        var copy = self
        copy.inputFactory = { letter, isMain, isUsed, onTap in
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

    /// Called each time the player taps Submit.
    /// - Parameter handler: Receives the submitted word (lowercased). Validation and
    ///   found-word tracking are the caller's responsibility.
    public func onWordSubmitted(_ handler: @escaping (_ word: String) -> Void) -> Self {
        var copy = self
        copy.onWordSubmittedCallback = handler
        return copy
    }

    /// Sets the distance from the centre letter to each surrounding letter tile.
    ///
    /// When not set the radius scales automatically with the available space (36 % of the
    /// smaller layout dimension). Supply an explicit value to fix the spacing regardless of
    /// how much space the wheel is given.
    ///
    /// ```swift
    /// WordWheelView(model: model)
    ///     .grid(radius: 120)
    /// ```
    ///
    /// - Parameter radius: Distance in points from the centre of the wheel to the centre of
    ///   each surrounding tile.
    public func grid(radius: CGFloat) -> Self {
        var copy = self
        copy.gridRadius = radius
        return copy
    }
}
