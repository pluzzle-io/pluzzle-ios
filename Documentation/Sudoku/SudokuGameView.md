# SudokuGameView

`SudokuGameView` is a self-contained SwiftUI view that renders a fully interactive 9×9 Sudoku puzzle. It handles cell selection, user input via a number pad, and game completion detection out of the box. Its appearance and behaviour can be customised through a chainable modifier API.

---

## Basic Usage

At minimum, provide a `SudokuGameModel` containing the starting grid and the solution:

```swift
SudokuGameView(model: myModel)
```

`SudokuGameModel` holds two grids:

- `grid` — the puzzle's starting state. Pre-filled cells use `Int` values; empty cells are `nil`.
- `solution` — the complete, correct solution as a flat `[[Int]]`.

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

var body: some View {
    SudokuGameView(model: model)
}
```

---

## External Reset

You can optionally pass a `Binding<Bool?>` to trigger a puzzle reset from outside the view. Set it to `true` to reset; the view automatically resets it back to `false` so subsequent resets work correctly.

```swift
@State private var resetTrigger: Bool? = nil

var body: some View {
    VStack {
        SudokuGameView(model: model, resetTrigger: $resetTrigger)

        Button("Restart") {
            resetTrigger = true
        }
    }
}
```

---

## Customising the Grid — `.grid(spacing:cell:)`

By default, `SudokuGameView` renders cells using its built-in `SudokuGameCell`. You can replace this with any custom view using the `.grid` modifier:

```swift
SudokuGameView(model: model)
    .grid(spacing: 2, cell: MyCustomCell.self)
```

- `spacing` — the gap in points between cells.
- `cell` — a type that conforms to `SudokuCellProtocol`.

### Adopting `SudokuCellProtocol`

Your custom cell must conform to `SudokuCellProtocol`, which requires a specific initialiser:

```swift
public protocol SudokuCellProtocol: View {
    init(isSelected: Binding<Bool>, text: String, isFixed: Bool)
}
```

| Parameter | Type | Description |
|---|---|---|
| `isSelected` | `Binding<Bool>` | Whether this cell is currently selected by the player. |
| `text` | `String` | The number to display (`"1"`–`"9"`), or an empty string if the cell is blank. |
| `isFixed` | `Bool` | `true` if the cell was pre-filled in the puzzle and cannot be edited. |

**Example custom cell:**

```swift
struct MyCustomCell: View, SudokuCellProtocol {
    @Binding var isSelected: Bool
    var text: String
    var isFixed: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(isFixed ? Color.primary.opacity(0.1) : (isSelected ? Color.accentColor : Color.clear))
                .border(Color.secondary.opacity(0.3), width: 0.5)

            Text(text)
                .font(.title2.bold())
                .foregroundStyle(isFixed ? .primary : (isSelected ? .white : .primary))
        }
    }
}
```

Then pass it to the modifier:

```swift
SudokuGameView(model: model)
    .grid(spacing: 1, cell: MyCustomCell.self)
```

---

## Customising the Input Pad — `.input(cell:)`

The number pad below the grid is also fully replaceable. Use the `.input` modifier to supply a custom button type:

```swift
SudokuGameView(model: model)
    .input(cell: MyCustomPadButton.self)
```

### Adopting `InputPadCellProtocol`

Your custom button must conform to `InputPadCellProtocol`:

```swift
public protocol InputPadCellProtocol: View {
    init(label: String, onTap: @escaping () -> Void)
}
```

| Parameter | Type | Description |
|---|---|---|
| `label` | `String` | The number to display on the button (`"1"`–`"9"`). |
| `onTap` | `() -> Void` | The action to call when the button is tapped. Call this from your tap gesture. |

**Example custom button:**

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
                .background(Color.accentColor)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}
```

Then pass it to the modifier:

```swift
SudokuGameView(model: model)
    .input(cell: MyCustomPadButton.self)
```

---

## Callbacks

### `.onInput(_:)`

Called every time the player places a number in a cell. Use this to react to individual moves — logging, hints, undo history, etc.

```swift
SudokuGameView(model: model)
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

Called when the player has filled every cell. The `Bool` argument indicates whether the completed grid matches the solution.

```swift
SudokuGameView(model: model)
    .onCompletion { isCorrect in
        if isCorrect {
            print("Puzzle solved!")
        } else {
            print("Grid is full but incorrect.")
        }
    }
```

---

## Putting It All Together

```swift
SudokuGameView(model: model, resetTrigger: $resetTrigger)
    .grid(spacing: 1, cell: MyCustomCell.self)
    .input(cell: MyCustomPadButton.self)
    .onInput { row, col, value in
        print("Entered \(value ?? 0) at (\(row), \(col))")
    }
    .onCompletion { isCorrect in
        showAlert = true
        alertMessage = isCorrect ? "Well done!" : "Not quite right."
    }
```
