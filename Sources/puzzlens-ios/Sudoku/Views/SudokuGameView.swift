import SwiftUI

/// A SwiftUI view that presents a fully interactive Sudoku puzzle.
///
/// Provide a ``SudokuGameModel`` and optionally chain builder modifiers before inserting
/// the view into the hierarchy:
///
/// ```swift
/// SudokuGameView(model: model)
///     .grid(spacing: 2, cell: MyCell.self)
///     .input(cell: MyPadButton.self)
///     .onInput { row, col, value in print("Entered \(value ?? 0)") }
///     .onCompletion { isCorrect in showResult = true }
/// ```
///
/// ### Interactions
/// - **Tap** an editable cell to select it, then tap a number on the pad below to fill it.
/// - Pass a `Binding<Bool?>` `resetTrigger` to programmatically reset the board from outside.
///
/// ### Completion
/// ``onCompletion(_:)`` fires once every cell is filled.
/// The `Bool` argument is `true` only when all entries match the solution.
public struct SudokuGameView: View {
    // MARK: - Configuration

    private var gridSpacing: CGFloat = 2.0

    /// Optional external reset trigger. Set to `true` from outside the view to reset the board;
    /// the view automatically resets the value back to `false` after processing.
    @Binding private var resetTrigger: Bool?

    // MARK: - State

    @State private var selectedIndex: Int? = nil

    private let model: SudokuGameModel

    /// The player's current entries. `nil` means the cell is empty.
    @State private var entries: [[Int?]] = []

    // MARK: - Init

    /// Creates a new Sudoku game view.
    ///
    /// - Parameters:
    ///   - model: The puzzle definition (starting grid and solution).
    ///   - resetTrigger: An optional binding you can flip to `true` to programmatically
    ///     reset the board. The view resets the value to `false` after processing.
    ///     Defaults to `.constant(nil)` (no external reset).
    public init(model: SudokuGameModel, resetTrigger: Binding<Bool?> = .constant(nil)) {
        self.model = model
        self._resetTrigger = resetTrigger
    }

    private var n: Int { model.grid.count }
    private var m: Int { model.grid.first?.count ?? n }
    private var count: Int { n * m }

    // Type-erased factories (default implementations)
    private var cellFactory: (_ index: Int, _ isSelected: Binding<Bool>, _ text: String, _ isFixed: Bool) -> AnyView =
    { _, isSelected, text, isFixed in
        AnyView(SudokuGameCell(isSelected: isSelected, text: text, isFixed: isFixed))
    }

    private var inputPadFactory: (_ label: String, _ onTap: @escaping () -> Void) -> AnyView =
    { label, onTap in
        AnyView(SudokuInputPadCell(label: label, onTap: onTap))
    }

    // Callbacks
    private var onInputCallback: ((_ row: Int, _ col: Int, _ value: Int?) -> Void)? = nil
    private var onCompletionCallback: ((Bool) -> Void)? = nil

    /// Grid items for the n×m cell layout, with uniform horizontal spacing.
    var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: gridSpacing), count: m)
    }

    /// Grid items for the 3×3 box-border overlay (only visually meaningful on a 9×9 grid).
    var overlayColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 0), count: 3)
    }

    public var body: some View {
        VStack(spacing: 12) {
            GeometryReader { gp in
                // Compute cell size accounting for spacing so grid fits width
                let totalHSpacing = gridSpacing * CGFloat(m - 1)
                let availableWidth = gp.size.width - totalHSpacing
                let cellSize = availableWidth / CGFloat(m)

                LazyVGrid(columns: columns, spacing: gridSpacing) {
                    ForEach(0..<count, id: \.self) { index in
                        let row = index / m
                        let col = index % m
                        let fixedValue = model.grid[row][col]
                        let isFixed = fixedValue != nil

                        // show fixed value OR user entry
                        let displayValue = fixedValue ?? entries[safe: row]?[safe: col] ?? nil
                        let text = displayValue.map(String.init) ?? ""

                        // isSelected binding derived from selectedIndex; blocked for fixed cells
                        let isSelected = Binding<Bool>(
                            get: { selectedIndex == index },
                            set: { newValue in
                                if !isFixed {
                                    selectedIndex = newValue ? index : nil
                                }
                            }
                        )

                        cellFactory(index, isSelected, text, isFixed)
                            .frame(width: cellSize, height: cellSize)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                guard !isFixed else { return }
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    selectedIndex = (selectedIndex == index) ? nil : index
                                }
                            }
                    }
                }
                // Thick 3×3 block borders overlay (only meaningful for 9×9)
                .overlay {
                    LazyVGrid(columns: overlayColumns, spacing: 0) {
                        ForEach(0..<9, id: \.self) { _ in
                            Rectangle()
                                .fill(.clear)
                                .frame(width: gp.size.width / 3, height: gp.size.width / 3)
                                .border(.black, width: 1.5)
                        }
                    }
                    .border(.black, width: 2)
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .border(.black, width: 3)

            // Number Pad (factory-driven, no Clear)
            SudokuNumberPad(
                makeCell: inputPadFactory,
                onInput: { number in
                    guard let idx = selectedIndex else { return }
                    let row = idx / m
                    let col = idx % m
                    // Only allow editing non-fixed cells
                    if model.grid[row][col] == nil {
                        entries[row][col] = number
                        onInputCallback?(row, col, number)
                        if isGridFilled() {
                            onCompletionCallback?(isCompleteCorrectly())
                        }
                    }
                }
            )
        }
        .onAppear {
            if entries.isEmpty {
                entries = model.grid
            }
        }
        // External reset trigger (optional)
        .onChange(of: resetTrigger) { _, newValue in
            guard newValue == true else { return }
            resetGrid()
            // auto-clear the trigger so a subsequent `true` fires again
            resetTrigger = false
        }
    }

    // MARK: - Public Helpers

    /// Resets all player entries and clears the selection, returning the board to
    /// its initial state. Prefer using the `resetTrigger` binding from outside the view.
    public func programmaticReset() {
        resetGrid()
    }

    // MARK: - Modifiers (generic API, type-erased storage)

    /// Sets the cell spacing and registers a custom cell type for the grid.
    /// - Parameters:
    ///   - spacing: Points of space between adjacent cells.
    ///   - cell: A type conforming to ``SudokuCellProtocol`` used to render each grid cell.
    public func grid<T: SudokuCellProtocol>(spacing: CGFloat, cell: T.Type) -> Self {
        var copy = self
        copy.gridSpacing = spacing
        copy.cellFactory = { _, isSelected, text, isFixed in
            AnyView(T(isSelected: isSelected, text: text, isFixed: isFixed))
        }
        return copy
    }

    /// Registers a custom number button type for the input pad.
    /// - Parameter cell: A type conforming to ``InputPadCellProtocol``.
    public func input<T: InputPadCellProtocol>(cell: T.Type) -> Self {
        var copy = self
        copy.inputPadFactory = { label, onTap in
            AnyView(T(label: label, onTap: onTap))
        }
        return copy
    }

    /// Registers a handler called each time the player places a number in a cell.
    /// - Parameter handler: Receives the zero-based row index, column index, and the entered value (1–9).
    public func onInput(_ handler: @escaping (_ row: Int, _ col: Int, _ value: Int?) -> Void) -> Self {
        var copy = self
        copy.onInputCallback = handler
        return copy
    }

    /// Registers a handler called once all cells are filled.
    /// - Parameter handler: Receives `true` if every entry matches the solution, `false` otherwise.
    public func onCompletion(_ handler: @escaping (Bool) -> Void) -> Self {
        var copy = self
        copy.onCompletionCallback = handler
        return copy
    }

    // MARK: - Helpers

    private func isGridFilled() -> Bool {
        for r in 0..<n {
            for c in 0..<m {
                if entries[r][c] == nil { return false }
            }
        }
        return true
    }

    private func isCompleteCorrectly() -> Bool {
        for r in 0..<n {
            for c in 0..<m {
                if entries[r][c] != model.solution[r][c] { return false }
            }
        }
        return true
    }

    private func resetGrid() {
        entries = model.grid
        selectedIndex = nil
    }
}
