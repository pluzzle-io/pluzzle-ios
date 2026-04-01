# Sudoku

Add a fully interactive 9×9 Sudoku puzzle to your app.

## Overview

`SudokuGameView` renders a 9×9 grid with a number pad below it. Fixed cells (pre-filled by the puzzle) are locked. The player selects an empty cell and taps a number pad button to fill it in. The view detects when every cell is filled and reports whether the solution is correct.

Hold a `SudokuGameModel` as `@State` in the parent view and pass it via a `Binding` — every move the player makes is written back to `model.state` automatically.

### Getting started

```swift
import PluzzleSDK

@State private var model = SudokuGameModel.example

var body: some View {
    SudokuGameView(model: $model)
        .padding()
}
```

### How the game works

1. The player taps an empty cell to select it. Fixed cells cannot be selected.
2. The player taps a number on the input pad to fill the selected cell.
3. Tapping the same number again clears the cell.
4. When every cell is filled `onCompletion` fires, passing `true` if the grid matches the solution.

---

## SudokuGameModel

```swift
public struct SudokuGameModel: SudokuGameModelProtocol {
    public var grid: [[Int?]]
    public var solution: [[Int]]
    public var state: [[Int?]]
    public var notes: [[Set<Int>]]?

    public init(grid: [[Int?]], solution: [[Int]], state: [[Int?]]? = nil)
    public mutating func reset()
}
```

| Property | Type | Description |
|---|---|---|
| `grid` | `[[Int?]]` | The puzzle's starting state — `Int` for pre-filled cells, `nil` for empty cells. |
| `solution` | `[[Int]]` | The complete, correct 9×9 solution grid. |
| `state` | `[[Int?]]` | The player's current grid entries, updated live as they play. Defaults to `grid` on init. |
| `notes` | `[[Set<Int>]]?` | Per-cell pencil marks. `nil` until the first note is written. |

Call `model.reset()` to restore `state` to its initial `grid` values and clear all notes.

```swift
let model = SudokuGameModel(
    grid: [
        [nil, 3, 4, 6, 7, 8, 9, 1, 2],
        [6, 7, 2, 1, 9, 5, 3, 4, 8],
        // ...
    ],
    solution: [
        [5, 3, 4, 6, 7, 8, 9, 1, 2],
        [6, 7, 2, 1, 9, 5, 3, 4, 8],
        // ...
    ]
)
```

To restore saved progress, pass the previously saved `state` to the initialiser:

```swift
@State private var model = SudokuGameModel(
    grid: savedGrid,
    solution: savedSolution,
    state: savedState
)
```

---

## Initialiser

```swift
public init(model: Binding<Model>, isNotesMode: Binding<Bool> = .constant(false))
```

| Parameter | Type | Description |
|---|---|---|
| `model` | `Binding<Model>` | A binding to any `SudokuGameModelProtocol` value held as `@State`. Player moves are written back automatically. |
| `isNotesMode` | `Binding<Bool>` | Controls whether tapping a number pencils in a candidate rather than filling the cell. Defaults to `.constant(false)`. |

---

## Resetting

Call `model.reset()` directly from the parent view — no external trigger binding is needed:

```swift
@State private var model = SudokuGameModel.example

var body: some View {
    VStack {
        Button("Restart") { model.reset() }
        SudokuGameView(model: $model)
    }
}
```

---

## Notes Mode

Pass a `Binding<Bool>` as `isNotesMode` to let the player pencil in candidate digits. Toggle it from an external control — for example a button placed in `.accessoryView {}`:

```swift
@State private var model = SudokuGameModel.example
@State private var isNotesMode = false

var body: some View {
    SudokuGameView(model: $model, isNotesMode: $isNotesMode)
        .accessoryView {
            Toggle("Notes", isOn: $isNotesMode)
        }
}
```

In notes mode, tapping a number adds or removes it from `model.notes` for the selected cell. Entering a digit in normal mode clears that cell's notes automatically.

---

## Customising Grid Cells — `.grid(spacing:cell:)`

```swift
SudokuGameView(model: $model)
    .grid(spacing: 1, cell: MyCustomCell.self)
```

To also control the 3×3 box divider:

```swift
SudokuGameView(model: $model)
    .grid(spacing: 2, cell: MyCustomCell.self, dividerColor: .black, dividerThickness: 1.5)
```

| Parameter | Type | Description |
|---|---|---|
| `spacing` | `CGFloat` | Gap between cells in points. |
| `cell` | `T.Type` | A type conforming to `SudokuCellProtocol`. |
| `dividerColor` | `Color` | Color of the thick lines separating 3×3 boxes. |
| `dividerThickness` | `CGFloat` | Base stroke width of the box-divider lines. |

### SudokuCellProtocol

```swift
public protocol SudokuCellProtocol: View {
    init(isSelected: Bool, text: String, isFixed: Bool, notes: Set<Int>?)
    init(isSelected: Bool, text: String, isFixed: Bool, notes: Set<Int>?, index: Int)
}
```

| Parameter | Type | Description |
|---|---|---|
| `isSelected` | `Bool` | Whether this cell is currently selected. |
| `text` | `String` | The digit to display (`"1"`–`"9"`), or an empty string when blank. |
| `isFixed` | `Bool` | `true` if the cell was pre-filled and cannot be edited. |
| `notes` | `Set<Int>?` | Candidate digits the player has pencilled in. `nil` when no notes exist for this cell. |
| `index` | `Int` | Zero-based linear index of the cell (0 = top-left, 80 = bottom-right). Override the `index:` init to act on position. |

The `index:` init has a default implementation that forwards to the primary init — conforming types only need to implement `init(isSelected:text:isFixed:notes:)`.

### Example custom cell

```swift
struct MyCustomCell: View, SudokuCellProtocol {
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
                .fill(isFixed ? Color.primary.opacity(0.1) : (isSelected ? Color.accentColor : .clear))
                .border(Color.secondary.opacity(0.3), width: 0.5)

            Text(text)
                .font(.title2.bold())
                .foregroundStyle(isFixed ? .primary : (isSelected ? .white : .primary))
        }
    }
}
```

---

## Customising the Input Pad — `.input(cell:)`

```swift
SudokuGameView(model: $model)
    .input(cell: MyCustomPadButton.self)
```

### InputPadCellProtocol

```swift
public protocol InputPadCellProtocol: View {
    init(label: String, onTap: @escaping () -> Void)
}
```

| Parameter | Type | Description |
|---|---|---|
| `label` | `String` | The digit label (`"1"`–`"9"`). |
| `onTap` | `() -> Void` | Call this when the button is tapped. |

### Example custom pad button

```swift
struct MyCustomPadButton: View, InputPadCellProtocol {
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

Insert any custom view between the grid and the number pad using `.accessoryView {}`. In landscape this slot appears above the pad in the right column.

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

Called every time the player fills or clears a cell.

```swift
SudokuGameView(model: $model)
    .onInput { row, col, value in
        print("Entered \(value ?? 0) at row \(row), col \(col)")
    }
```

| Parameter | Type | Description |
|---|---|---|
| `row` | `Int` | Zero-based row index of the edited cell. |
| `col` | `Int` | Zero-based column index of the edited cell. |
| `value` | `Int?` | The digit entered (1–9), or `nil` if the cell was cleared. |

### `.onCompletion(_:)`

Called when the player has filled every cell.

```swift
SudokuGameView(model: $model)
    .onCompletion { isCorrect in
        alertMessage = isCorrect ? "Puzzle solved!" : "Grid full but incorrect."
        showAlert = true
    }
```

| Parameter | Type | Description |
|---|---|---|
| `isCorrect` | `Bool` | `true` if the filled grid matches the solution; `false` otherwise. |

---

## Putting It All Together

```swift
@State private var model = SudokuGameModel.example
@State private var isNotesMode = false

var body: some View {
    SudokuGameView(model: $model, isNotesMode: $isNotesMode)
        .grid(spacing: 1, cell: MyCustomCell.self, dividerColor: .black, dividerThickness: 1.5)
        .input(cell: MyCustomPadButton.self)
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
