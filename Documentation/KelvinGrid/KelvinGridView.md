# KelvinGridView

`KelvinGridView` is a self-contained SwiftUI view that renders a fully interactive word-guessing puzzle. The player uses an on-screen QWERTY keyboard to fill rows of the grid one letter at a time. When a row is submitted, each cell is coloured to show whether the letter is correct, misplaced, or wrong (with a signed alphabetical-distance hint). It handles input, evaluation, and game-over detection out of the box. Its appearance can be customised through a chainable modifier API.

---

## Basic Usage

At minimum, provide a `KelvinGridModel` containing the puzzle data:

```swift
KelvinGridView(model: myModel)
```

`KelvinGridModel` holds three properties:

- `targetWord`     — The word the player is trying to guess (stored uppercased internally).
- `maxAttempts`    — The number of guess rows (default: `6`).
- `currentGuesses` — Words already submitted. Pass a non-empty array to restore a saved session; defaults to `[]`.

```swift
let model = KelvinGridModel(
    targetWord: "SWIFT",
    maxAttempts: 6
)

var body: some View {
    KelvinGridView(model: model)
}
```

### How the game works

1. The player taps letters on the QWERTY keyboard to fill the current row.
2. Tapping **⌫** removes the last letter.
3. Once all columns are filled the row is submitted automatically and cell colouring is applied.
4. Each submitted cell is coloured based on the following rules:

| Colour | Condition |
|---|---|
| **Green** | The letter is in the target word **and** in the correct position. |
| **Orange** | The letter is in the target word but at a **different** position. |
| **Gray + offset** | The letter is not in the word. A small label (e.g. `+3` or `−2`) shows the signed alphabetical distance from the correct letter: positive means the guessed letter comes *after* the correct one in the alphabet, negative means *before*. |
| **Gray outlined** | The cell is empty or has a pending (unsubmitted) letter. |

5. The game ends when the player guesses the word (all cells green) or exhausts all attempts.

---

## Customising Grid Cells — `.grid(spacing:cell:)`

By default, `KelvinGridView` renders each grid cell using its built-in `KelvinGridCell`. Replace it with any custom view using the `.grid` modifier:

```swift
KelvinGridView(model: model)
    .grid(spacing: 8, cell: MyCustomCell.self)
```

- `spacing` — the gap in points between cells and between rows.
- `cell` — a type that conforms to `KelvinGridCellProtocol`.

### Adopting `KelvinGridCellProtocol`

Your custom cell must conform to `KelvinGridCellProtocol`:

```swift
public protocol KelvinGridCellProtocol: View {
    init(letter: String, state: KelvinCellState, isActiveRow: Bool)
}
```

| Parameter | Type | Description |
|---|---|---|
| `letter` | `String` | The letter to display, or an empty string if the cell is blank. |
| `state` | `KelvinCellState` | The evaluation state that drives the cell's colour (see below). |
| `isActiveRow` | `Bool` | `true` when this cell belongs to the row currently being typed. Use this to render a highlighted border. |

### `KelvinCellState`

```swift
public enum KelvinCellState: Equatable, Hashable {
    case empty       // No letter typed. Displayed as a gray outlined cell.
    case pending     // Letter typed but row not yet submitted. Displayed as a gray outlined cell.
    case correct     // Green — right letter, right position.
    case misplaced   // Orange — right letter, wrong position.
    case wrong(Int)  // Gray — letter not in word. Int is the signed alphabetical offset
                     // (guessLetter − correctLetter): positive = guessed letter comes after
                     // the correct letter in the alphabet; negative = comes before.
                     // Displayed with a small "+N" / "−N" label on the cell.
}
```

**Example custom cell:**

```swift
struct MyCustomCell: View, KelvinGridCellProtocol {
    var letter: String
    var state: KelvinCellState
    var isActiveRow: Bool

    init(letter: String, state: KelvinCellState, isActiveRow: Bool) {
        self.letter = letter
        self.state = state
        self.isActiveRow = isActiveRow
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(background)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(borderColor, lineWidth: 1.5)
                )
            if case .wrong(let offset) = state {
                VStack(spacing: 1) {
                    Text(letter)
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                    Text(offset >= 0 ? "+\(offset)" : "\(offset)")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.85))
                }
            } else {
                Text(letter)
                    .font(.title2.bold())
                    .foregroundStyle(letter.isEmpty ? .clear : .white)
            }
        }
    }

    private var background: Color {
        switch state {
        case .empty, .pending: return Color(.systemGray5)
        case .correct:         return .green
        case .misplaced:       return .orange
        case .wrong:           return Color(.systemGray2)
        }
    }

    private var borderColor: Color {
        switch state {
        case .empty, .pending: return isActiveRow ? Color.accentColor : Color(.systemGray3)
        default:               return .clear
        }
    }
}
```

Then pass it to the modifier:

```swift
KelvinGridView(model: model)
    .grid(spacing: 8, cell: MyCustomCell.self)
```

---

## Customising Keyboard Keys — `.input(cell:)`

The QWERTY keyboard is fully replaceable. Use the `.input` modifier to supply a custom key type:

```swift
KelvinGridView(model: model)
    .input(cell: MyCustomKey.self)
```

### Adopting `KelvinKeyProtocol`

Your custom key must conform to `KelvinKeyProtocol`:

```swift
public protocol KelvinKeyProtocol: View {
    init(label: String, onTap: @escaping () -> Void)
}
```

| Parameter | Type | Description |
|---|---|---|
| `label` | `String` | The text on the key — a single letter or `"⌫"` (delete). Rows auto-submit when full. |
| `onTap` | `() -> Void` | Call this when the key is tapped. |

**Example custom key:**

```swift
struct MyCustomKey: View, KelvinKeyProtocol {
    var label: String
    var onTap: () -> Void

    init(label: String, onTap: @escaping () -> Void) {
        self.label = label
        self.onTap = onTap
    }

    var body: some View {
        Button(action: onTap) {
            Text(label)
                .font(.subheadline.bold())
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Color.accentColor.opacity(0.15))
                .foregroundStyle(.primary)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}
```

Then pass it to the modifier:

```swift
KelvinGridView(model: model)
    .input(cell: MyCustomKey.self)
```

---

## Callbacks

### `.onInput(_:)`

Called every time the player fills a complete row (auto-submitted). Use this to react to individual guesses — logging, haptic feedback, animations, etc.

```swift
KelvinGridView(model: model)
    .onInput { guess, states in
        print("Player guessed: \(guess)")
        print("States: \(states)")
    }
```

| Parameter | Type | Description |
|---|---|---|
| `guess` | `String` | The submitted word (uppercased). |
| `states` | `[KelvinCellState]` | The evaluated state for each cell in the row. |

### `.onCompletion(_:)`

Called when the game ends — either the player guessed the word or exhausted all attempts.

```swift
KelvinGridView(model: model)
    .onCompletion { didWin in
        if didWin {
            print("Correct!")
        } else {
            print("Better luck next time. The word was \(model.targetWord).")
        }
    }
```

| Parameter | Type | Description |
|---|---|---|
| `didWin` | `Bool` | `true` if the player found the word; `false` if all attempts were used. |

---

## Restoring a Session

Pass previously submitted guesses to `KelvinGridModel` to restore an in-progress game. The view will evaluate and colour all restored rows automatically.

```swift
let model = KelvinGridModel(
    targetWord: "SWIFT",
    maxAttempts: 6,
    currentGuesses: ["STORM", "SHIFT"]
)
```

---

## Putting It All Together

```swift
KelvinGridView(model: model)
    .grid(spacing: 8, cell: MyCustomCell.self)
    .input(cell: MyCustomKey.self)
    .onInput { guess, states in
        let correct = states.filter { $0 == .correct }.count
        print("\(guess): \(correct)/\(model.columns) correct positions")
    }
    .onCompletion { didWin in
        showAlert = true
        alertMessage = didWin ? "Well done!" : "The word was \(model.targetWord)."
    }
```
