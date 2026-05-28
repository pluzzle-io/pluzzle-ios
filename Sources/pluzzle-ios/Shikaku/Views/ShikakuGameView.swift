import SwiftUI

/// A SwiftUI view that presents a fully interactive Shikaku puzzle.
///
/// The player draws rectangles over the grid by dragging from one corner to the opposite corner.
/// Each rectangle must cover exactly one clue cell, and its area must equal that clue.
///
/// Configure the view with builder modifiers before inserting it into the hierarchy:
///
/// ```swift
/// @State private var model = ShikakuModel.example
///
/// var body: some View {
///     ShikakuGameView(model: $model)
///         .grid(spacing: 2, cell: ShikakuCell.self)
///         .showViolations(true)
///         .onMove { rect in
///             print("Placed rect at (\(rect.row),\(rect.col)) size \(rect.rowSpan)×\(rect.colSpan)")
///         }
///         .onComplete {
///             print("Puzzle solved!")
///         }
/// }
/// ```
///
/// ### Interactions
/// - **Drag** across cells to draw a rectangle preview. Releasing the drag commits the rectangle.
/// - **Tap** a covered cell to remove its rectangle.
///
/// ### Violation highlighting
/// When `.showViolations(true)` is set (the default), rectangles that break a rule are
/// highlighted in red. Pass `false` to disable this feedback.
///
/// ### Aspect ratio
/// The grid renders at a 2:3 aspect ratio by default (width : height). Use `.aspectRatio`
/// on the parent view to override.
public struct ShikakuGameView: View {

    // MARK: - Configuration

    @Binding var model: ShikakuModel

    private var gridSpacing: CGFloat = 2
    private var shouldShowViolations: Bool = true

    private var cellFactory: (_ row: Int, _ col: Int, _ state: ShikakuCellState) -> AnyView = {
        row, col, state in
        AnyView(ShikakuCell(row: row, column: col, state: state))
    }

    private var hintTrigger: Binding<Int>? = nil
    private var onMoveCallback: ((_ rect: ShikakuRect) -> Void)? = nil
    private var onCompleteCallback: (() -> Void)? = nil

    // MARK: - Drag state

    @State private var dragStart: ShikakuCoord? = nil
    @State private var dragEnd: ShikakuCoord? = nil

    // MARK: - Init

    /// Creates a new Shikaku game view with the given model binding.
    ///
    /// Apply `.grid(spacing:cell:)`, `.showViolations(_:)`, `.onMove(_:)`, and `.onComplete(_:)`
    /// modifiers before inserting the view into the hierarchy.
    ///
    /// - Parameter model: A binding to the ``ShikakuModel`` that defines the grid and holds all
    ///   live player state. All state changes are written back through this binding.
    public init(model: Binding<ShikakuModel>) {
        self._model = model
    }

    // MARK: - Body

    public var body: some View {
        GeometryReader { geo in
            let cellSize = cellSizeFor(geo.size)
            let previewRect = makePreviewRect()
            let colorMap = buildColorMap()

            VStack(alignment: .leading, spacing: gridSpacing) {
                ForEach(0..<model.rows, id: \.self) { row in
                    HStack(spacing: gridSpacing) {
                        ForEach(0..<model.columns, id: \.self) { col in
                            let coord = ShikakuCoord(row: row, col: col)
                            let state = cellState(for: coord, previewRect: previewRect, colorMap: colorMap)

                            cellFactory(row, col, state)
                                .frame(width: cellSize, height: cellSize)
                        }
                    }
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .local)
                    .onChanged { value in
                        let start = coord(for: value.startLocation, cellSize: cellSize)
                        let current = coord(for: value.location, cellSize: cellSize)
                        if dragStart == nil { dragStart = start }
                        dragEnd = current
                    }
                    .onEnded { value in
                        commitDrag(end: coord(for: value.location, cellSize: cellSize))
                        dragStart = nil
                        dragEnd = nil
                    }
            )
        }
        .aspectRatio(2.0 / 3.0, contentMode: .fit)
        .onChange(of: hintTrigger?.wrappedValue ?? 0) { oldValue, newValue in
            guard newValue > oldValue, newValue > 0 else { return }
            let wasSolved = model.isSolved
            model.revealHint()
            if !wasSolved && model.isSolved {
                onCompleteCallback?()
            }
        }
    }

    // MARK: - Modifiers

    /// Sets the cell spacing and registers a custom cell type for the grid.
    ///
    /// - Parameters:
    ///   - spacing: Points of space between adjacent cells.
    ///   - cell: A type conforming to ``ShikakuCellProtocol`` used to render each grid cell.
    public func grid<T: ShikakuCellProtocol>(spacing: CGFloat, cell: T.Type) -> Self {
        var copy = self
        copy.gridSpacing = spacing
        copy.cellFactory = { row, col, state in AnyView(T(row: row, column: col, state: state)) }
        return copy
    }

    /// Controls whether cells in invalid rectangles are visually highlighted.
    ///
    /// When `true` (the default), any rectangle that violates a Shikaku rule receives
    /// `isViolation: true` on each of its cells. Pass `false` to disable this feedback.
    ///
    /// - Parameter show: Pass `false` to disable violation highlighting.
    public func showViolations(_ show: Bool) -> Self {
        var copy = self
        copy.shouldShowViolations = show
        return copy
    }

    /// Registers a handler that fires each time the player successfully commits a rectangle.
    ///
    /// - Parameter handler: Receives the newly placed ``ShikakuRect``.
    public func onMove(_ handler: @escaping (_ rect: ShikakuRect) -> Void) -> Self {
        var copy = self
        copy.onMoveCallback = handler
        return copy
    }

    /// Connects an external hint counter to the view.
    ///
    /// Each time the binding's value **increases**, one randomly chosen unsolved rectangle from
    /// ``ShikakuModel/solution`` is revealed and placed on the grid. Has no effect when no
    /// solution was provided or when every solution rectangle is already correctly placed.
    ///
    /// ```swift
    /// @State private var hintCount = 0
    ///
    /// ShikakuGameView(model: $model)
    ///     .hint(trigger: $hintCount)
    ///
    /// Button("Hint") { hintCount += 1 }
    /// ```
    ///
    /// - Parameter trigger: A binding to an integer counter owned by the parent. The view reads
    ///   this value reactively; only increases trigger a reveal.
    public func hint(trigger: Binding<Int>) -> Self {
        var copy = self
        copy.hintTrigger = trigger
        return copy
    }

    /// Registers a handler that fires once when the puzzle is solved.
    ///
    /// The handler is called when `model.isSolved` becomes `true` after placing a rectangle.
    public func onComplete(_ handler: @escaping () -> Void) -> Self {
        var copy = self
        copy.onCompleteCallback = handler
        return copy
    }

    // MARK: - Helpers

    /// Returns the side length of one square cell that fits within `size`.
    ///
    /// Uses whichever dimension is the binding constraint (the one that would produce the
    /// smaller cell), so the grid never overflows and cells are always square.
    private func cellSizeFor(_ size: CGSize) -> CGFloat {
        let fromWidth  = (size.width  - gridSpacing * CGFloat(model.columns - 1)) / CGFloat(model.columns)
        let fromHeight = (size.height - gridSpacing * CGFloat(model.rows    - 1)) / CGFloat(model.rows)
        return max(min(fromWidth, fromHeight), 1)
    }

    /// Maps a local point to the nearest grid coordinate, clamped to valid bounds.
    private func coord(for point: CGPoint, cellSize: CGFloat) -> ShikakuCoord {
        let col = Int(point.x / (cellSize + gridSpacing))
        let row = Int(point.y / (cellSize + gridSpacing))
        return ShikakuCoord(
            row: max(0, min(row, model.rows    - 1)),
            col: max(0, min(col, model.columns - 1))
        )
    }

    /// Builds a rectangle from the current drag start/end pair, or `nil` if no drag is active.
    private func makePreviewRect() -> ShikakuRect? {
        guard let s = dragStart, let e = dragEnd else { return nil }
        let minRow = min(s.row, e.row), maxRow = max(s.row, e.row)
        let minCol = min(s.col, e.col), maxCol = max(s.col, e.col)
        return ShikakuRect(
            row: minRow, col: minCol,
            rowSpan: maxRow - minRow + 1,
            colSpan: maxCol - minCol + 1
        )
    }

    /// Builds a rect→colorIndex map keyed to clue coordinates, not rect order.
    ///
    /// Clue coords are fixed for the lifetime of a puzzle, so sorting them once gives each
    /// rectangle a stable colour that never shifts when other rectangles are placed or removed.
    private func buildColorMap() -> [ShikakuRect: Int] {
        let sortedClueCoords = model.clues.keys.sorted {
            $0.row != $1.row ? $0.row < $1.row : $0.col < $1.col
        }
        let clueIndex = Dictionary(
            uniqueKeysWithValues: sortedClueCoords.enumerated().map { ($1, $0) }
        )
        var map: [ShikakuRect: Int] = [:]
        for rect in model.rects {
            if let clueCoord = model.clues.keys.first(where: { rect.contains($0) }) {
                map[rect] = clueIndex[clueCoord]
            }
        }
        return map
    }

    /// Builds a ``ShikakuCellState`` for a single cell, factoring in violations and the preview.
    private func cellState(for coord: ShikakuCoord, previewRect: ShikakuRect?, colorMap: [ShikakuRect: Int]) -> ShikakuCellState {
        let clue = model.clues[coord]
        let placedRect = model.rect(at: coord)
        let inPreview = previewRect?.contains(coord) ?? false
        let isOverlap = placedRect != nil && inPreview

        var isViolation = false
        if shouldShowViolations, let r = placedRect {
            isViolation = isRectViolating(r)
        }

        return ShikakuCellState(
            clue: clue,
            rect: placedRect,
            isRectOrigin: placedRect.map { $0.row == coord.row && $0.col == coord.col } ?? false,
            isViolation: isViolation,
            isPreview: inPreview && placedRect == nil,
            isOverlap: isOverlap,
            colorIndex: placedRect.flatMap { colorMap[$0] }
        )
    }

    /// Returns `true` when `rect` violates a Shikaku rule:
    /// - contains zero or more than one clue, or
    /// - the single clue's value does not equal the rectangle's area, or
    /// - the rectangle extends beyond the grid bounds.
    private func isRectViolating(_ rect: ShikakuRect) -> Bool {
        guard rect.row >= 0, rect.col >= 0,
              rect.row + rect.rowSpan <= model.rows,
              rect.col + rect.colSpan <= model.columns else { return true }
        let cluesInside = model.clues.filter { rect.contains($0.key) }
        guard cluesInside.count == 1, cluesInside.values.first == rect.area else { return true }
        return false
    }

    /// Commits the current drag as a rectangle placement (or tap-to-remove).
    private func commitDrag(end: ShikakuCoord) {
        dragEnd = end
        guard let rect = makePreviewRect() else { return }

        // Single-cell gesture on an already-covered cell → remove that rect.
        if rect.rowSpan == 1 && rect.colSpan == 1 {
            let coord = ShikakuCoord(row: rect.row, col: rect.col)
            if model.rect(at: coord) != nil {
                model.removeRect(at: coord)
                return
            }
        }

        // Place the rectangle.
        let wasSolved = model.isSolved
        model.place(rect)
        onMoveCallback?(rect)
        if !wasSolved && model.isSolved {
            onCompleteCallback?()
        }
    }
}
