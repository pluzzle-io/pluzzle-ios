import SwiftUI

public struct KelvinGridView: View {
    private let model: KelvinGridModel
    private var gridSpacing: CGFloat = 8

    // MARK: - State

    @State private var currentInput: [String] = []
    @State private var submittedGuesses: [String] = []
    @State private var submittedStates: [[KelvinCellState]] = []
    @State private var isGameOver: Bool = false
    @State private var didWin: Bool = false

    // MARK: - Factories (default implementations)

    private var cellFactory: (_ letter: String, _ state: KelvinCellState, _ isActiveRow: Bool) -> AnyView =
    { letter, state, isActiveRow in
        AnyView(KelvinGridCell(letter: letter, state: state, isActiveRow: isActiveRow))
    }

    private var inputFactory: (_ label: String, _ onTap: @escaping () -> Void) -> AnyView =
    { label, onTap in
        AnyView(KelvinKey(label: label, onTap: onTap))
    }

    // MARK: - Callbacks

    private var onInputCallback: ((_ guess: String, _ states: [KelvinCellState]) -> Void)? = nil
    private var onCompletionCallback: ((_ didWin: Bool) -> Void)? = nil

    // MARK: - Init

    public init(model: KelvinGridModel) {
        self.model = model

        var guesses: [String] = []
        var stateRows: [[KelvinCellState]] = []
        var won = false

        for guess in model.currentGuesses {
            let upper = String(guess.prefix(model.columns))
            let states = KelvinGridModel.evaluate(guess: upper, target: model.targetWord)
            guesses.append(upper)
            stateRows.append(states)
            if states.allSatisfy({ $0 == .correct }) {
                won = true
                break
            }
        }

        let over = won || guesses.count >= model.maxAttempts
        self._submittedGuesses = State(initialValue: guesses)
        self._submittedStates = State(initialValue: stateRows)
        self._isGameOver = State(initialValue: over)
        self._didWin = State(initialValue: won)
    }

    // MARK: - Body

    public var body: some View {
        VStack(spacing: 16) {
            gridView
            Spacer()
            if !isGameOver {
                keyboardView
            }
        }
        .padding()
    }

    // MARK: - Grid

    private var gridView: some View {
        VStack(spacing: gridSpacing) {
            ForEach(0..<model.maxAttempts, id: \.self) { row in
                gridRow(for: row)
            }
        }
    }

    @ViewBuilder
    private func gridRow(for row: Int) -> some View {
        let isActiveRow = row == submittedGuesses.count && !isGameOver
        HStack(spacing: gridSpacing) {
            ForEach(0..<model.columns, id: \.self) { col in
                gridCell(row: row, col: col, isActiveRow: isActiveRow)
                    .aspectRatio(1, contentMode: .fit)
            }
        }
    }

    @ViewBuilder
    private func gridCell(row: Int, col: Int, isActiveRow: Bool) -> some View {
        let (letter, state) = cellData(row: row, col: col)
        cellFactory(letter, state, isActiveRow)
    }

    private func cellData(row: Int, col: Int) -> (String, KelvinCellState) {
        if row < submittedGuesses.count {
            let chars = Array(submittedGuesses[row])
            let letter = col < chars.count ? String(chars[col]) : ""
            let state = submittedStates[row][safe: col] ?? .cold
            return (letter, state)
        } else if row == submittedGuesses.count && !isGameOver {
            let letter = currentInput[safe: col] ?? ""
            return (letter, letter.isEmpty ? .empty : .pending)
        } else {
            return ("", .empty)
        }
    }

    // MARK: - Keyboard

    private var keyboardView: some View {
        VStack(spacing: 8) {
            keyboardRow(keys: ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"])
            keyboardRow(keys: ["A", "S", "D", "F", "G", "H", "J", "K", "L"])
            keyboardRow(keys: ["Z", "X", "C", "V", "B", "N", "M", "⌫"])
        }
    }

    @ViewBuilder
    private func keyboardRow(keys: [String]) -> some View {
        HStack(spacing: 6) {
            ForEach(keys, id: \.self) { key in
                inputFactory(key) { handleKey(key) }
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Input Logic

    private func handleKey(_ key: String) {
        guard !isGameOver else { return }
        switch key {
        case "⌫":
            guard !currentInput.isEmpty else { return }
            currentInput.removeLast()
        default:
            guard currentInput.count < model.columns else { return }
            currentInput.append(key)
            if currentInput.count == model.columns {
                submitGuess()
            }
        }
    }

    private func submitGuess() {
        guard currentInput.count == model.columns else { return }
        let guess = currentInput.joined()
        let states = KelvinGridModel.evaluate(guess: guess, target: model.targetWord)

        submittedGuesses.append(guess)
        submittedStates.append(states)
        onInputCallback?(guess, states)
        currentInput = []

        let won = states.allSatisfy { $0 == .correct }
        if won || submittedGuesses.count >= model.maxAttempts {
            isGameOver = true
            didWin = won
            onCompletionCallback?(won)
        }
    }

    // MARK: - Modifiers

    /// Replace the default grid cell with a custom view conforming to `KelvinGridCellProtocol`,
    /// and set the spacing between cells.
    public func grid<T: KelvinGridCellProtocol>(spacing: CGFloat, cell: T.Type) -> Self {
        var copy = self
        copy.gridSpacing = spacing
        copy.cellFactory = { letter, state, isActiveRow in
            AnyView(T(letter: letter, state: state, isActiveRow: isActiveRow))
        }
        return copy
    }

    /// Replace the default keyboard key with a custom view conforming to `KelvinKeyProtocol`.
    public func input<T: KelvinKeyProtocol>(cell: T.Type) -> Self {
        var copy = self
        copy.inputFactory = { label, onTap in AnyView(T(label: label, onTap: onTap)) }
        return copy
    }

    /// Called each time the player fills a complete row (auto-submitted).
    /// - Parameters:
    ///   - handler: Receives the submitted guess (uppercased) and the resulting cell states.
    public func onInput(_ handler: @escaping (_ guess: String, _ states: [KelvinCellState]) -> Void) -> Self {
        var copy = self
        copy.onInputCallback = handler
        return copy
    }

    /// Called when the game ends — either the player guessed the word or used all attempts.
    /// - Parameters:
    ///   - handler: Receives `true` if the player won, `false` if all attempts were exhausted.
    public func onCompletion(_ handler: @escaping (_ didWin: Bool) -> Void) -> Self {
        var copy = self
        copy.onCompletionCallback = handler
        return copy
    }
}
