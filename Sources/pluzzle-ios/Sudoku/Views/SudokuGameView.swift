import SwiftUI

/// A SwiftUI view that presents a fully interactive Sudoku puzzle.
///
/// Provide a ``SudokuGameModel`` and a binding to a notes-mode flag, then optionally chain
/// builder modifiers before inserting the view into the hierarchy:
///
/// ```swift
/// @State private var model = SudokuGameModel.example
/// @State private var isNotesMode = false
///
/// var body: some View {
///     SudokuGameView(model: $model, isNotesMode: $isNotesMode, gridOnly: false)
///         .grid(spacing: 2, cell: MyCell.self, cornerRadius: 8)
///         .input(cell: MyPadButton.self)
///         .accessoryView {
///             Button("Notes") { isNotesMode.toggle() }
///         }
///         .onInput { row, col, value in print("Entered \(value ?? 0)") }
///         .onSelect { row, col in print("Selected (\(row), \(col))") }
///         .onCompletion { isCorrect in showResult = true }
/// }
/// ```
///
/// Because ``SudokuGameModel`` is a struct passed via binding, every cell the player fills in is
/// written back to `model.state` automatically — the parent view always has the current puzzle state.
///
/// ### Layout
/// The view adapts to the device orientation automatically:
/// - **Portrait** — the grid fills the available width (aspect-ratio 1:1) and claims space before
///   the accessory view and number pad below it.
/// - **Landscape** — the grid fills the available height on the left; the accessory view and
///   number pad stack vertically in the right column.
///
/// ### Interactions
/// - **Tap** an editable cell to select it, then tap a number on the pad below to fill it.
/// - Toggle `isNotesMode` from your own control (e.g. a button placed in `.accessoryView {}`)
///   to switch between entering digits and pencilling in candidates.
///   In notes mode tapping a number adds or removes it from `model.notes` for the selected cell.
///   Entering a digit in normal mode clears that cell's notes automatically.
/// - Call `model.reset()` from the parent to programmatically reset the board.
///
/// ### Accessory view
/// Use the ``accessoryView(_:)`` modifier to insert any custom view between the grid and the
/// number pad (or above the pad in landscape). This is the recommended place to add a notes
/// toggle button, an undo button, or any other game control.
///
/// ### Completion
/// ``onCompletion(_:)`` fires once every cell is filled.
/// The `Bool` argument is `true` only when all entries in `state` match the solution.
///
/// ### Grid-only mode
/// Pass `gridOnly: true` to the initialiser to render only the Sudoku grid, suppressing the
/// accessory view and input pad entirely. This is useful for read-only previews, replay screens,
/// or any context where the parent supplies its own input controls:
///
/// ```swift
/// SudokuGameView(model: $model, isNotesMode: $isNotesMode, gridOnly: true)
/// ```
///
/// `gridOnly` defaults to `false`, preserving the standard full-screen layout.
///
/// ### Grid corner radius
/// Both `.grid()` modifier overloads accept an optional `cornerRadius: CGFloat` parameter
/// (default `0`) that rounds the outer corners of the grid and its border:
///
/// ```swift
/// .grid(spacing: 2, cell: MyCell.self, cornerRadius: 12)
/// ```
///
/// ### Cell-selection callback
/// ``onSelect(_:)`` registers a closure that is called whenever the player taps a new
/// non-fixed cell. Use it to drive external UI — for example, to animate a custom toolbar or
/// to log analytics events — without having to poll the model:
///
/// ```swift
/// .onSelect { row, col in
///     highlightedCell = (row, col)
/// }
/// ```
///
/// The closure receives the zero-based `row` and `col` indices of the newly selected cell.
/// It is not called when the player taps a fixed (given) cell or re-taps the already-selected cell.
public struct SudokuGameView<Model: SudokuGameModelProtocol>: View {
    // MARK: - Configuration

    private var gridSpacing: CGFloat = 2.0
    private var dividerColor: Color = .black
    private var dividerThickness: CGFloat = 1.5
    private var gridCornerRadius: CGFloat = 0

    // MARK: - State

    @State private var selectedIndex: Int? = nil
    /// Guards `onCompletionCallback` so it fires at most once per completed board.
    /// Reset automatically when the board goes back to incomplete (e.g. after `model.reset()`).
    @State private var completionFired = false
    @State private var isHintModeActive: Bool = false

    @Binding var model: Model
    @Binding var isNotesMode: Bool

    /// When `true`, only the Sudoku grid is rendered — the accessory view and input pad are hidden.
    private var gridOnly: Bool = false

    // MARK: - Init

    /// Creates a new Sudoku game view.
    ///
    /// - Parameters:
    ///   - model: A binding to any ``SudokuGameModelProtocol`` value held as `@State`
    ///     in the parent view — player moves are written back to `model.state` automatically.
    ///   - isNotesMode: A binding to a `Bool` that controls whether the view is in notes
    ///     (pencil-mark) mode. Defaults to `.constant(false)` — pass a real binding when you
    ///     want to drive an external toggle button or toolbar item.
    ///   - gridOnly: When `true`, only the Sudoku grid is rendered — the accessory view and
    ///     input pad are hidden. Defaults to `false` so existing call sites require no changes.
    public init(model: Binding<Model>, isNotesMode: Binding<Bool> = .constant(false), gridOnly: Bool = false) {
        self._model = model
        self._isNotesMode = isNotesMode
        self.gridOnly = gridOnly
    }

    private var n: Int { model.grid.count }
    private var m: Int { model.grid.first?.count ?? n }
    private var count: Int { n * m }

    // Type-erased factories (default implementations)
    private var cellFactory: (_ isSelected: Bool, _ text: String, _ isFixed: Bool, _ notes: Set<Int>?, _ index: Int, _ isHintEligible: Bool) -> AnyView =
    { isSelected, text, isFixed, notes, index, isHintEligible in
        AnyView(SudokuGameCell(isSelected: isSelected, text: text, isFixed: isFixed, notes: notes, index: index, isHintEligible: isHintEligible))
    }

    private var inputPadFactory: (_ label: String, _ onTap: @escaping () -> Void) -> AnyView =
    { label, onTap in
        AnyView(SudokuInputPadCell(label: label, onTap: onTap))
    }

    private var accessoryViewFactory: (() -> AnyView)? = nil

    // Hint trigger
    private var hintTrigger: Binding<Int>? = nil

    // Callbacks
    private var onSelectCallback: ((_ row: Int, _ col: Int) -> Void)? = nil
    private var onInputCallback: ((_ row: Int, _ col: Int, _ value: Int?) -> Void)? = nil
    private var onCompletionCallback: ((Bool) -> Void)? = nil

    /// Grid items for the n×m cell layout, with uniform horizontal spacing.
    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: gridSpacing), count: m)
    }

    /// Grid items for the 3×3 box-border overlay (only visually meaningful on a 9×9 grid).
    private var overlayColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 0), count: 3)
    }

    public var body: some View {
        GeometryReader { screen in
            if screen.size.width > screen.size.height {
                landscapeBody(screen: screen)
            } else {
                portraitBody(screen: screen)
            }
        }
        .onChange(of: model.isComplete) { _, isComplete in
            if !isComplete { completionFired = false }
        }
        .onChange(of: hintTrigger?.wrappedValue ?? 0) { oldValue, newValue in
            guard newValue > oldValue, newValue > 0 else { return }
            guard !model.isComplete else { return }
            isHintModeActive = true
        }
    }

    // MARK: - Layout variants

    @ViewBuilder
    private func portraitBody(screen: GeometryProxy) -> some View {
        let hPad: CGFloat = 12
        let vPad: CGFloat = 8
        VStack(spacing: 12) {
            // layoutPriority(1) ensures the grid claims space first;
            // aspectRatio(1, .fit) then constrains it to a square.
            // Controls receive whatever height remains.
            Color.clear
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .aspectRatio(1, contentMode: .fit)
                .overlay { gridOverlay }
                .clipShape(RoundedRectangle(cornerRadius: gridCornerRadius))
                .overlay { RoundedRectangle(cornerRadius: gridCornerRadius).strokeBorder(dividerColor, lineWidth: dividerThickness * 2) }
                .layoutPriority(1)
            if !gridOnly {
                if let accessoryViewFactory { accessoryViewFactory() }
                numberPad
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, hPad)
        .padding(.vertical, vPad)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func landscapeBody(screen: GeometryProxy) -> some View {
        let hPad: CGFloat = 12
        let vPad: CGFloat = 8
        // Grid fills available height (screen minus top + bottom padding), staying 1:1.
        // Explicit frame is required so the HStack gives the remaining width to the right column.
        let gridSize = screen.size.height - vPad * 2
        HStack(alignment: .center, spacing: 16) {
            Color.clear
                .frame(width: gridSize, height: gridSize)
                .overlay { gridOverlay }
                .clipShape(RoundedRectangle(cornerRadius: gridCornerRadius))
                .overlay { RoundedRectangle(cornerRadius: gridCornerRadius).strokeBorder(dividerColor, lineWidth: dividerThickness * 2) }
            if !gridOnly {
                VStack(spacing: 12) {
                    if let accessoryViewFactory { accessoryViewFactory() }
                    numberPad
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, maxHeight: gridSize)
            }
        }
        .padding(.horizontal, hPad)
        .padding(.vertical, vPad)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Shared sub-views

    @ViewBuilder
    private var gridOverlay: some View {
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
                    let cellNotes: Set<Int>? = model.notes?[safe: row]?[safe: col]
                    let isSelected = selectedIndex == index
                    let isHintEligible = isHintModeActive && text.isEmpty && !isFixed

                    cellFactory(isSelected, text, isFixed, cellNotes, index, isHintEligible)
                        .frame(width: cellSize, height: cellSize)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            guard !isFixed else { return }
                            if isHintModeActive {
                                isHintModeActive = false
                                guard model.state[safe: row]?[safe: col] == nil else { return }
                                model.state[row][col] = model.solution[row][col]
                                model.notes?[row][col] = []
                                onInputCallback?(row, col, model.solution[row][col])
                                if model.isComplete && !completionFired {
                                    completionFired = true
                                    onCompletionCallback?(model.isCorrect)
                                }
                                return
                            }
                            guard !isSelected else { return }
                            selectedIndex = index
                            onSelectCallback?(row, col)
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
                .allowsHitTesting(false)
            }
        }
    }

    @ViewBuilder
    private var numberPad: some View {
        SudokuNumberPad(
            makeCell: inputPadFactory,
            onInput: { number in
                guard let idx = selectedIndex else { return }
                let row = idx / m
                let col = idx % m
                guard model.grid[row][col] == nil else { return }
                if isNotesMode {
                    model.notes = model.notes ?? Array(repeating: Array(repeating: Set<Int>(), count: m), count: n)
                    if model.notes?[row][col].contains(number) == true {
                        model.notes?[row][col].remove(number)
                    } else {
                        model.notes?[row][col].insert(number)
                    }
                } else {
                    model.state[row][col] = number
                    model.notes?[row][col] = []
                    onInputCallback?(row, col, number)
                    if model.isComplete && !completionFired {
                        completionFired = true
                        onCompletionCallback?(model.isCorrect)
                    }
                }
            }
        )
    }

    // MARK: - Modifiers (generic API, type-erased storage)

    /// Sets the cell spacing and registers a custom cell type for the grid.
    /// - Parameters:
    ///   - spacing: Points of space between adjacent cells.
    ///   - cell: A type conforming to ``SudokuCellProtocol`` used to render each grid cell.
    ///   - cornerRadius: Corner radius applied to the outer edge of the grid and its border. Defaults to `0`.
    public func grid<T: SudokuCellProtocol>(spacing: CGFloat, cell: T.Type, cornerRadius: CGFloat = 0) -> Self {
        var copy = self
        copy.gridSpacing = spacing
        copy.gridCornerRadius = cornerRadius
        copy.cellFactory = { isSelected, text, isFixed, notes, index, isHintEligible in
            AnyView(T(isSelected: isSelected, text: text, isFixed: isFixed, notes: notes, index: index, isHintEligible: isHintEligible))
        }
        return copy
    }

    /// Sets the cell spacing, registers a custom cell type, and configures the 3×3 box divider appearance.
    /// - Parameters:
    ///   - spacing: Points of space between adjacent cells.
    ///   - cell: A type conforming to ``SudokuCellProtocol`` used to render each grid cell.
    ///   - dividerColor: The color used to draw the thick lines separating the 3×3 boxes.
    ///   - dividerThickness: The base stroke width of the box-divider lines.
    ///   - cornerRadius: Corner radius applied to the outer edge of the grid and its border. Defaults to `0`.
    public func grid<T: SudokuCellProtocol>(spacing: CGFloat, cell: T.Type, dividerColor: Color, dividerThickness: CGFloat, cornerRadius: CGFloat = 0) -> Self {
        var copy = self.grid(spacing: spacing, cell: cell, cornerRadius: cornerRadius)
        copy.dividerColor     = dividerColor
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

    /// Inserts a custom view between the grid and the input pad.
    /// In landscape mode it appears above the input pad in the right column.
    /// - Parameter content: A `@ViewBuilder` closure returning the view to insert.
    public func accessoryView<V: View>(@ViewBuilder _ content: @escaping () -> V) -> Self {
        var copy = self
        copy.accessoryViewFactory = { AnyView(content()) }
        return copy
    }

    /// Registers a handler called each time the player selects a cell.
    /// - Parameter handler: Receives the zero-based row and column index of the selected cell.
    public func onSelect(_ handler: @escaping (_ row: Int, _ col: Int) -> Void) -> Self {
        var copy = self
        copy.onSelectCallback = handler
        return copy
    }

    /// Registers a handler called each time the player places a number in a cell.
    /// - Parameter handler: Receives the zero-based row index, column index, and the entered value (1–9).
    public func onInput(_ handler: @escaping (_ row: Int, _ col: Int, _ value: Int?) -> Void) -> Self {
        var copy = self
        copy.onInputCallback = handler
        return copy
    }

    /// Connects an external hint counter to the view.
    ///
    /// Each time the binding's value **increases**, hint mode activates: all empty editable cells
    /// glow orange, and the player taps the cell they want filled. The tapped cell is filled with
    /// its correct solution value and hint mode ends. Has no effect when every editable cell is
    /// already filled.
    ///
    /// ```swift
    /// @State private var hintCount = 0
    ///
    /// SudokuGameView(model: $model, isNotesMode: $isNotesMode)
    ///     .hint(trigger: $hintCount)
    ///
    /// Button("Hint") { hintCount += 1 }
    /// ```
    ///
    /// - Parameter trigger: A binding to an integer counter owned by the parent. The view reads
    ///   this value reactively; only increases activate hint mode.
    public func hint(trigger: Binding<Int>) -> Self {
        var copy = self
        copy.hintTrigger = trigger
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
