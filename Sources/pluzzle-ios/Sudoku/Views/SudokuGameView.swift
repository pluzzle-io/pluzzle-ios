import SwiftUI

/// A SwiftUI view that presents a fully interactive Sudoku puzzle.
///
/// Provide a ``SudokuGameModel`` and optionally chain builder modifiers before inserting
/// the view into the hierarchy:
///
/// ```swift
/// @State private var model = SudokuGameModel.example
///
/// var body: some View {
///     SudokuGameView(model: model)
///         .grid(spacing: 2, cell: MyCell.self)
///         .input(cell: MyPadButton.self)
///         .onInput { row, col, value in print("Entered \(value ?? 0)") }
///         .onCompletion { isCorrect in showResult = true }
/// }
/// ```
///
/// Because ``SudokuGameModel`` is a struct passed via binding, every cell the player fills in is
/// written back to `model.state` automatically — the parent view always has the current puzzle state.
///
/// ### Interactions
/// - **Tap** an editable cell to select it, then tap a number on the pad below to fill it.
/// - Tap the **Notes** toggle button to switch between entering digits and pencilling in candidates.
///   In notes mode tapping a number adds or removes it from `model.notes` for the selected cell.
///   Entering a digit in normal mode clears that cell's notes automatically.
/// - Call `model.reset()` from the parent to programmatically reset the board.
///
/// ### Completion
/// ``onCompletion(_:)`` fires once every cell is filled.
/// The `Bool` argument is `true` only when all entries in `state` match the solution.
public struct SudokuGameView<Model: SudokuGameModelProtocol>: View {
    // MARK: - Configuration

    private var gridSpacing: CGFloat = 2.0
    private var dividerColor: Color = .black
    private var dividerThickness: CGFloat = 1.5

    // MARK: - State

    @State private var selectedIndex: Int? = nil
    @State private var isNotesMode: Bool = false

    @Binding var model: Model

    // MARK: - Init

    /// Creates a new Sudoku game view.
    ///
    /// - Parameter model: A binding to any ``SudokuGameModelProtocol`` value held as `@State`
    ///   in the parent view — player moves are written back to `model.state` automatically.
    public init(model: Binding<Model>) {
        self._model = model
    }

    private var n: Int { model.grid.count }
    private var m: Int { model.grid.first?.count ?? n }
    private var count: Int { n * m }

    // Type-erased factories (default implementations)
    private var cellFactory: (_ index: Int, _ isSelected: Binding<Bool>, _ text: String, _ isFixed: Bool, _ notes: Set<Int>?) -> AnyView =
    { _, isSelected, text, isFixed, notes in
        AnyView(SudokuGameCell(isSelected: isSelected, text: text, isFixed: isFixed, notes: notes))
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
        GeometryReader { screen in
        ScrollView {
        VStack(spacing: 12) {
            // Use a zero-size Color as the aspect-ratio anchor so the GeometryReader
            // receives a square frame rather than expanding to fill all available height.
            Color.clear
                .aspectRatio(1, contentMode: .fit)
                .overlay {
                    GeometryReader { gp in
                        let totalHSpacing = gridSpacing * CGFloat(m - 1)
                        let availableWidth = gp.size.width - totalHSpacing
                        let cellSize = availableWidth / CGFloat(m)

                        LazyVGrid(columns: columns, spacing: gridSpacing) {
                            ForEach(0..<count, id: \.self) { index in
                                let row = index / m
                                let col = index % m
                                let fixedValue = model.grid[row][col]
                                let isFixed = fixedValue != nil

                                let displayValue = fixedValue ?? model.state[safe: row]?[safe: col] ?? nil
                                let text = displayValue.map(String.init) ?? ""
                                let cellNotes = model.notes?[safe: row]?[safe: col] ?? []

                                let isSelected = Binding<Bool>(
                                    get: { selectedIndex == index },
                                    set: { newValue in
                                        if !isFixed {
                                            selectedIndex = newValue ? index : nil
                                        }
                                    }
                                )

                                cellFactory(index, isSelected, text, isFixed, cellNotes)
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
                        .overlay {
                            LazyVGrid(columns: overlayColumns, spacing: 0) {
                                ForEach(0..<9, id: \.self) { _ in
                                    Rectangle()
                                        .fill(.clear)
                                        .frame(width: gp.size.width / 3, height: gp.size.width / 3)
                                        .border(dividerColor, width: dividerThickness)
                                }
                            }
                            .border(dividerColor, width: dividerThickness * 1.5)
                        }
                    }
                }
                .border(dividerColor, width: dividerThickness * 2)

            // Notes mode toggle
            Button {
                isNotesMode.toggle()
            } label: {
                Label("Notes", systemImage: "pencil")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(isNotesMode ? .white : .primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(isNotesMode ? Color.indigo : Color.gray.opacity(0.15))
                    .clipShape(Capsule())
            }

            // Number Pad (factory-driven, no Clear)
            SudokuNumberPad(
                makeCell: inputPadFactory,
                onInput: { number in
                    guard let idx = selectedIndex else { return }
                    let row = idx / m
                    let col = idx % m
                    guard model.grid[row][col] == nil else { return }
                    if isNotesMode {
                        if model.notes == nil {
                            model.notes = Array(repeating: Array(repeating: Set<Int>(), count: m), count: n)
                        }
                        if model.notes![row][col].contains(number) {
                            model.notes![row][col].remove(number)
                        } else {
                            model.notes![row][col].insert(number)
                        }
                    } else {
                        model.state[row][col] = number
                        model.notes?[row][col] = []
                        onInputCallback?(row, col, number)
                        if model.isComplete {
                            onCompletionCallback?(model.isCorrect)
                        }
                    }
                }
            )
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(minHeight: screen.size.height)
        } // end ScrollView
        .frame(width: screen.size.width, height: screen.size.height)
        } // end GeometryReader
    }

    // MARK: - Modifiers (generic API, type-erased storage)

    /// Sets the cell spacing and registers a custom cell type for the grid.
    /// - Parameters:
    ///   - spacing: Points of space between adjacent cells.
    ///   - cell: A type conforming to ``SudokuCellProtocol`` used to render each grid cell.
    public func grid<T: SudokuCellProtocol>(spacing: CGFloat, cell: T.Type) -> Self {
        var copy = self
        copy.gridSpacing = spacing
        copy.cellFactory = { _, isSelected, text, isFixed, notes in
            AnyView(T(isSelected: isSelected, text: text, isFixed: isFixed, notes: notes))
        }
        return copy
    }

    /// Sets the cell spacing, registers a custom cell type, and configures the 3×3 box divider appearance.
    /// - Parameters:
    ///   - spacing: Points of space between adjacent cells.
    ///   - cell: A type conforming to ``SudokuCellProtocol`` used to render each grid cell.
    ///   - dividerColor: The color used to draw the thick lines separating the 3×3 boxes.
    ///   - dividerThickness: The base stroke width of the box-divider lines.
    public func grid<T: SudokuCellProtocol>(spacing: CGFloat, cell: T.Type, dividerColor: Color, dividerThickness: CGFloat) -> Self {
        var copy = self
        copy.gridSpacing = spacing
        copy.cellFactory = { _, isSelected, text, isFixed, notes in
            AnyView(T(isSelected: isSelected, text: text, isFixed: isFixed, notes: notes))
        }
        copy.dividerColor = dividerColor
        copy.dividerThickness = dividerThickness
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

}
