# Kelvin Grid

Add a Wordle-style word-guessing puzzle to your app.

## Overview

`KelvinGridView` renders a grid of letter cells and a QWERTY keyboard. The player types guesses one row at a time; when a row is full it auto-submits and each cell is coloured to show whether the letter is correct, misplaced, or wrong. A unique **alphabetical-distance hint** on wrong cells reveals how far off the guess was, giving players an extra navigational nudge.

### Getting started

```swift
import PuzzlensSDK

KelvinGridView(model: KelvinGridModel(targetWord: "SWIFT", maxAttempts: 6))
    .padding()
```

### How the game works

1. The player taps letters on the built-in QWERTY keyboard to fill the active row.
2. Tapping **⌫** removes the last letter typed.
3. Once all columns are filled the row **auto-submits** and cell colouring is applied.
4. Cell colours communicate three outcomes:

| Colour | Meaning |
|---|---|
| **Green** | Correct letter in the correct position. |
| **Orange** | Correct letter in the wrong position. |
| **Gray + offset** | Letter not in the word. The small label (e.g. `+3` or `−2`) is the signed alphabetical distance from the correct letter — positive means the guessed letter comes *after* the correct one, negative means *before*. |

5. The game ends when the player guesses the word or exhausts all attempts.

---

## KelvinGridModel

```swift
public struct KelvinGridModel {
    public let targetWord: String
    public let maxAttempts: Int
    public let currentGuesses: [String]

    public init(targetWord: String, maxAttempts: Int = 6, currentGuesses: [String] = [])
}
```

| Property | Description |
|---|---|
| `targetWord` | The word to guess (stored uppercased internally). |
| `maxAttempts` | Number of guess rows. Default: `6`. |
| `currentGuesses` | Previously submitted guesses — pass these to restore a saved session. |

The number of columns is derived automatically from `targetWord.count`.

### Restoring a session

Pass previously submitted guesses to restore an in-progress game. The view evaluates and colours all restored rows automatically.

```swift
let model = KelvinGridModel(
    targetWord: "SWIFT",
    maxAttempts: 6,
    currentGuesses: ["STORM", "SHIFT"]
)
```

---

## KelvinCellState

```swift
public enum KelvinCellState: Equatable, Hashable {
    case empty
    case pending
    case correct
    case misplaced
    case wrong(Int)
}
```

| Case | Description |
|---|---|
| `.empty` | No letter typed. Shown as a gray outlined cell. |
| `.pending` | Letter typed but row not yet submitted. |
| `.correct` | Green — right letter, right position. |
| `.misplaced` | Orange — right letter, wrong position. |
| `.wrong(Int)` | Gray — letter not in word. `Int` is the signed alphabetical offset from the correct letter. |

---

## Customising Grid Cells — `.grid(spacing:cell:)`

```swift
KelvinGridView(model: model)
    .grid(spacing: 8, cell: MyCustomCell.self)
```

| Parameter | Type | Description |
|---|---|---|
| `spacing` | `CGFloat` | Gap between cells and rows in points. |
| `cell` | `T.Type` | A type conforming to `KelvinGridCellProtocol`. |

### KelvinGridCellProtocol

```swift
public protocol KelvinGridCellProtocol: View {
    init(letter: String, state: KelvinCellState, isActiveRow: Bool)
}
```

| Parameter | Type | Description |
|---|---|---|
| `letter` | `String` | The letter to display, or an empty string if the cell is blank. |
| `state` | `KelvinCellState` | The evaluation state driving the cell's colour. |
| `isActiveRow` | `Bool` | `true` when this cell belongs to the row currently being typed. Use this to render a highlighted border. |

### Example custom cell

```swift
struct MyCustomCell: View, KelvinGridCellProtocol {
    var letter: String
    var state: KelvinCellState
    var isActiveRow: Bool

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
                    Text(letter).font(.title2.bold()).foregroundStyle(.white)
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

---

## Customising Keyboard Keys — `.input(cell:)`

```swift
KelvinGridView(model: model)
    .input(cell: MyCustomKey.self)
```

### KelvinKeyProtocol

```swift
public protocol KelvinKeyProtocol: View {
    init(label: String, onTap: @escaping () -> Void)
}
```

| Parameter | Type | Description |
|---|---|---|
| `label` | `String` | The key label — a single letter or `"⌫"` for delete. |
| `onTap` | `() -> Void` | Call this when the key is tapped. |

### Example custom key

```swift
struct MyCustomKey: View, KelvinKeyProtocol {
    var label: String
    var onTap: () -> Void

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

---

## Callbacks

### `.onInput(_:)`

Called every time the player submits a complete row.

```swift
KelvinGridView(model: model)
    .onInput { guess, states in
        let correct = states.filter { $0 == .correct }.count
        print("\(guess): \(correct)/\(model.columns) correct")
    }
```

| Parameter | Type | Description |
|---|---|---|
| `guess` | `String` | The submitted word (uppercased). |
| `states` | `[KelvinCellState]` | Evaluated state for each letter in the row. |

### `.onCompletion(_:)`

Called when the game ends — either the word was guessed or all attempts were used.

```swift
KelvinGridView(model: model)
    .onCompletion { didWin in
        alertMessage = didWin ? "Well done!" : "The word was \(model.targetWord)."
        showAlert = true
    }
```

| Parameter | Type | Description |
|---|---|---|
| `didWin` | `Bool` | `true` if the player found the word; `false` if all attempts were exhausted. |

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
