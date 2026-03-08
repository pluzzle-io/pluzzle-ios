import SwiftUI

public struct SudokuGameView: View {
    // Config
    private var gridSpacing: CGFloat = 2.0

    // Optional external reset trigger (default nil)
    @Binding private var resetTrigger: Bool?

    // Selection
    @State private var selectedIndex: Int? = nil

    private let model: SudokuGameModel

    // Editable entries (nil means empty). Start with the initial grid.
    @State private var entries: [[Int?]] = []

    // MARK: - Init
    // If caller doesn't provide a binding, it defaults to `.constant(nil)`
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

    // n×m with matching H/V spacing
    var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: gridSpacing), count: m)
    }

    // 3×3 overlay blocks (for 9×9)
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
        .onChange(of: resetTrigger) { newValue, _ in
            guard newValue == true else { return }
            resetGrid()
            // auto-clear the trigger so a subsequent `true` fires again
            resetTrigger = false
        }
    }

    // MARK: - Public helper (in-view direct call if needed)
    public func programmaticReset() {
        resetGrid()
    }

    // MARK: - Modifiers (generic API, type-erased storage)

    public func grid<T: SudokuCellProtocol>(spacing: CGFloat, cell: T.Type) -> Self {
        var copy = self
        copy.gridSpacing = spacing
        copy.cellFactory = { _, isSelected, text, isFixed in
            AnyView(T(isSelected: isSelected, text: text, isFixed: isFixed))
        }
        return copy
    }

    public func input<T: InputPadCellProtocol>(cell: T.Type) -> Self {
        var copy = self
        copy.inputPadFactory = { label, onTap in
            AnyView(T(label: label, onTap: onTap))
        }
        return copy
    }

    public func onInput(_ handler: @escaping (_ row: Int, _ col: Int, _ value: Int?) -> Void) -> Self {
        var copy = self
        copy.onInputCallback = handler
        return copy
    }

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
