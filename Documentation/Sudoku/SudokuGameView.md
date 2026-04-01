# SudokuGameView

`SudokuGameView` is a SwiftUI view that renders a fully interactive Sudoku puzzle. It handles cell selection, number input, and completion detection out of the box. Appearance and behaviour are customised through a chainable modifier API.

---

## Basic Usage

Hold a `SudokuGameModel` as `@State` and pass it to `SudokuGameView` via a binding:

```swift
@State private var model = SudokuGameModel.example
@State private var isNotesMode = false

var body: some View {
    SudokuGameView(model: $model, isNotesMode: $isNotesMode)
}
```

Because the model is passed as a `Binding`, every cell the player fills in is written back to `model.state` automatically — the parent view always has the current puzzle state.

### Initialiser

```swift
public init(model: Binding<Model>, isNotesMode: Binding<Bool> = .constant(false))
```

| Parameter | Type | Description |
|---|---|---|
| `model` | `Binding<Model>` | A binding to any `SudokuGameModelProtocol` value held as `@State`. |
| `isNotesMode` | `Binding<Bool>` | When `true`, tapping a number pencils in a candidate rather than filling the cell. Defaults to `.constant(false)`. |

---

## The Model

`SudokuGameModel` is the built-in model type. It holds all game state:

| Property | Type | Description |
|---|---|---|
| `grid` | `[[Int?]]` | Initial puzzle. Pre-filled cells hold `1–9`; empty cells are `nil`. |
| `solution` | `[[Int]]` | The complete, correct solution. |
| `state` | `[[Int?]]` | Player's current entries — updated live as they play. |
| `notes` | `[[Set<Int>]]?` | Optional per-cell pencil marks. `nil` until first note is written. |
| `isComplete` | `Bool` | `true` when every cell has been filled (regardless of correctness). |
| `isCorrect` | `Bool` | `true` when all entries match the solution. |

```swift
let model = SudokuGameModel(
    grid: [
        [5, 3, nil, nil, 7, nil, nil, nil, nil],
        [nil, 7, nil, 1, nil, nil, nil, 4, nil],
        // …
    ],
    solution: [
        [5, 3, 4, 6, 7, 8, 9, 1, 2],
        [6, 7, 2, 1, 9, 5, 3, 4, 8],
        // …
    ]
)
```

### Restoring Progress

Pass a `state` array to the initialiser to restore a previously saved game:

```swift
@State private var model = SudokuGameModel(
    grid: savedGrid,
    solution: savedSolution,
    state: savedState   // player's progress
)
```

To save progress, read `model.state` (and optionally `model.notes`) at any time from the parent view — they are always current.

---

## Resetting

Call `model.reset()` to restore the board to its initial state and clear all notes:

```swift
Button("Reset") {
    model.reset()
}

SudokuGameView(model: $model)
```

---

## Custom Models — `SudokuGameModelProtocol`

`SudokuGameView` is generic over `SudokuGameModelProtocol`, so you can supply your own model type:

```swift
public protocol SudokuGameModelProtocol {
    var grid: [[Int?]] { get }
    var solution: [[Int]] { get }
    var state: [[Int?]] { get set }
    var notes: [[Set<Int>]]? { get set }
    mutating func reset()
    // isComplete and isCorrect are provided free via a protocol extension
}
```

Example:

```swift
struct MyModel: SudokuGameModelProtocol {
    var grid: [[Int?]]
    var solution: [[Int]]
    var state: [[Int?]]
    var notes: [[Set<Int>]]?

    mutating func reset() {
        state = grid
        notes = nil
    }
}

@State private var model = MyModel(…)
SudokuGameView(model: $model)
```

---

## Customising the Grid — `.grid(spacing:cell:)`

By default, `SudokuGameView` renders cells using the built-in `SudokuGameCell`. Replace it with any custom view using the `.grid` modifier:

```swift
SudokuGameView(model: $model)
    .grid(spacing: 2, cell: MyCustomCell.self)
```

To also control the 3×3 box divider:

```swift
SudokuGameView(model: $model)
    .grid(spacing: 2, cell: MyCustomCell.self, dividerColor: .black, dividerThickness: 1.5)
```

### Adopting `SudokuCellProtocol`

```swift
public protocol SudokuCellProtocol: View {
    init(isSelected: Bool, text: String, isFixed: Bool, notes: Set<Int>?)
    init(isSelected: Bool, text: String, isFixed: Bool, notes: Set<Int>?, index: Int)
}
```

| Parameter | Type | Description |
|---|---|---|
| `isSelected` | `Bool` | Whether this cell is currently selected. |
| `text` | `String` | The digit to display (`"1"`–`"9"`), or empty if blank. |
| `isFixed` | `Bool` | `true` if the cell was pre-filled and cannot be edited. |
| `notes` | `Set<Int>?` | Candidate digits the player has pencilled in. `nil` when no notes exist for this cell. |
| `index` | `Int` | Zero-based linear index of the cell (0 = top-left, 80 = bottom-right). Override the `index:` init to act on cell position. |

The `index:` init has a default implementation that forwards to the primary init — conforming types only need to implement `init(isSelected:text:isFixed:notes:)`.

Example:

```swift
struct MyCell: View, SudokuCellProtocol {
    var isSelected: Bool
    var text: String
    var isFixed: Bool
    var notes: Set<Int>?

    init(isSelected: Bool, text: String, isFixed: Bool, notes: Set<Int>? = nil) {
        self.isSelected = isSelected
        self.text = text
        self.isFixed = isFixed
        self.notes = notes
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(isFixed ? .secondary.opacity(0.2) : (isSelected ? .accentColor : .clear))
            Text(text)
                .font(.title2.bold())
                .foregroundStyle(isSelected && !isFixed ? .white : .primary)
        }
    }
}
```

---

## Customising the Input Pad — `.input(cell:)`

Replace the default number pad buttons with your own type:

```swift
SudokuGameView(model: $model)
    .input(cell: MyPadButton.self)
```

### Adopting `InputPadCellProtocol`

```swift
public protocol InputPadCellProtocol: View {
    init(label: String, onTap: @escaping () -> Void)
}
```

| Parameter | Type | Description |
|---|---|---|
| `label` | `String` | The digit to display (`"1"`–`"9"`). |
| `onTap` | `() -> Void` | Call this when the button is tapped. |

Example:

```swift
struct MyPadButton: View, InputPadCellProtocol {
    var label: String
    var onTap: () -> Void

    init(label: String, onTap: @escaping () -> Void) {
        self.label = label
        self.onTap = onTap
    }

    var body: some View {
        Button(action: onTap) {
            Text(label)
                .font(.title3.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(.tint)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}
```

---

## Accessory View — `.accessoryView(_:)`

Insert any custom view between the grid and the number pad. In landscape mode it appears above the pad in the right column. This is the recommended location for a notes toggle, an undo button, or any other game control.

```swift
SudokuGameView(model: $model, isNotesMode: $isNotesMode)
    .accessoryView {
        HStack {
            Button("Reset") { model.reset() }
            Spacer()
            Toggle("Notes", isOn: $isNotesMode)
        }
        .padding(.horizontal)
    }
```

---

## Callbacks

### `.onInput(_:)`

Called every time the player places a number in a cell.

```swift
SudokuGameView(model: $model)
    .onInput { row, col, value in
        print("Player entered \(value ?? 0) at row \(row), col \(col)")
    }
```

| Parameter | Type | Description |
|---|---|---|
| `row` | `Int` | Zero-based row index of the edited cell. |
| `col` | `Int` | Zero-based column index of the edited cell. |
| `value` | `Int?` | The number entered (1–9). |

### `.onCompletion(_:)`

Called once when every cell has been filled. The `Bool` argument indicates whether the completed grid matches the solution.

```swift
SudokuGameView(model: $model)
    .onCompletion { isCorrect in
        print(isCorrect ? "Solved!" : "Board full but incorrect.")
    }
```

---

## Putting It All Together

```swift
@State private var model = SudokuGameModel.example
@State private var isNotesMode = false

var body: some View {
    SudokuGameView(model: $model, isNotesMode: $isNotesMode)
        .grid(spacing: 2, cell: MyCell.self, dividerColor: .black, dividerThickness: 1.5)
        .input(cell: MyPadButton.self)
        .accessoryView {
            HStack {
                Button("Reset") { model.reset() }
                Spacer()
                Toggle("Notes", isOn: $isNotesMode)
            }
            .padding(.horizontal)
        }
        .onInput { row, col, value in
            print("Entered \(value ?? 0) at (\(row), \(col))")
        }
        .onCompletion { isCorrect in
            showAlert = true
            alertMessage = isCorrect ? "Well done!" : "Not quite right."
        }
}
```
