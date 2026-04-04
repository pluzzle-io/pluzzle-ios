# WordWheelView

`WordWheelView` is a self-contained SwiftUI view that renders a fully interactive Word Wheel puzzle. The player taps letters arranged in a circle to build words, each of which must include the central main letter. It handles letter selection, word submission, answer validation, and completion detection out of the box. Its appearance can be customised through a chainable modifier API.

---

## Basic Usage

At minimum, provide a `WordWheelModel` containing the puzzle data:

```swift
WordWheelView(model: myModel)
```

`WordWheelModel` holds four properties:

- `mainLetter` — the letter at the centre of the wheel. Every valid word must contain it.
- `letters` — the letters arranged around the wheel (excluding the main letter).
- `currentAnswers` — words already found. Pass a non-empty array to pre-populate a restored session; defaults to `[]`.
- `acceptableAnswers` — all valid words for this puzzle. Entries are stored lowercased.

```swift
let model = WordWheelModel(
    mainLetter: "E",
    letters: ["R", "A", "T", "H", "N", "G", "S"],
    acceptableAnswers: [
        "earth", "heart", "hate", "rate", "gate",
        "grate", "great", "stare", "share", "shear"
    ]
)

var body: some View {
    WordWheelView(model: model)
}
```

### How the game works

1. The player taps letters on the wheel to spell a word — each physical tile can only be used once per attempt.
2. The main letter tile is always available at the centre.
3. Tapping **Delete** removes the last letter. Tapping **Clear** resets the current attempt.
4. Tapping **Submit** checks the word:
   - It must be present in `acceptableAnswers`.
   - It must not already have been found.
5. Valid words are added to the found-words list below the wheel.
6. The puzzle is complete when every `acceptableAnswer` has been found.

---

## Customising the Input Display — `.inputView(cell:)`

The word-in-progress banner at the top of the view is fully replaceable. Use the `.inputView` modifier to supply a custom type:

```swift
WordWheelView(model: model)
    .inputView(MyInputView.self)
```

### Adopting `WordWheelInputViewProtocol`

Your custom view must conform to `WordWheelInputViewProtocol`:

```swift
public protocol WordWheelInputViewProtocol: View {
    init(word: String, isValid: Bool, letterCount: Int)
}
```

| Parameter | Type | Description |
|---|---|---|
| `word` | `String` | The word currently being built (uppercased). Empty string when no letters are selected. |
| `isValid` | `Bool` | `true` when the current word is in `acceptableAnswers` and has not yet been found. Recomputed live on every letter tap. |
| `letterCount` | `Int` | Total number of letters on the wheel — surrounding letters plus the main letter. |

**Example custom input view:**

```swift
struct MyInputView: View, WordWheelInputViewProtocol {
    var word: String
    var isValid: Bool
    var letterCount: Int

    init(word: String, isValid: Bool, letterCount: Int) {
        self.word = word
        self.isValid = isValid
        self.letterCount = letterCount
    }

    var body: some View {
        HStack {
            Text(word.isEmpty ? "Start typing…" : word)
                .font(.title2.bold())
                .foregroundStyle(isValid ? Color.green : Color.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("\(word.count) / \(letterCount)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
```

Then pass it to the modifier:

```swift
WordWheelView(model: model)
    .inputView(MyInputView.self)
```

---

## Customising Letter Tiles — `.letterCell(cell:)`

By default, `WordWheelView` renders each wheel tile using its built-in `WordWheelLetterCell`. Replace it with any custom view using the `.letterCell` modifier:

```swift
WordWheelView(model: model)
    .letterCell(cell: MyCustomTile.self)
```

### Adopting `WordWheelLetterCellProtocol`

Your custom tile must conform to `WordWheelLetterCellProtocol`:

```swift
public protocol WordWheelLetterCellProtocol: View {
    init(letter: String, isMain: Bool, isUsed: Bool, onTap: @escaping () -> Void)
}
```

| Parameter | Type | Description |
|---|---|---|
| `letter` | `String` | The letter displayed on this tile (always uppercased). |
| `isMain` | `Bool` | `true` when this is the centre/main letter tile. |
| `isUsed` | `Bool` | `true` when this tile has already been tapped in the current word attempt and cannot be tapped again. |
| `onTap` | `() -> Void` | Call this when the tile is tapped. |

**Example custom tile:**

```swift
struct MyCustomTile: View, WordWheelLetterCellProtocol {
    var letter: String
    var isMain: Bool
    var isUsed: Bool
    var onTap: () -> Void

    init(letter: String, isMain: Bool, isUsed: Bool, onTap: @escaping () -> Void) {
        self.letter = letter
        self.isMain = isMain
        self.isUsed = isUsed
        self.onTap = onTap
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(isUsed ? Color.gray.opacity(0.3) : (isMain ? Color.purple : Color.accentColor))
            Text(letter)
                .font(isMain ? .title2.bold() : .headline)
                .foregroundStyle(.white)
        }
        .onTapGesture {
            guard !isUsed else { return }
            onTap()
        }
    }
}
```

Then pass it to the modifier:

```swift
WordWheelView(model: model)
    .letterCell(cell: MyCustomTile.self)
```

---

## Customising Action Buttons — `.actionButton(cell:)`

The Submit, Delete, and Clear buttons are fully replaceable. Use the `.actionButton` modifier to supply a custom button type:

```swift
WordWheelView(model: model)
    .actionButton(cell: MyCustomButton.self)
```

### Adopting `WordWheelActionButtonProtocol`

Your custom button must conform to `WordWheelActionButtonProtocol`:

```swift
public protocol WordWheelActionButtonProtocol: View {
    init(label: String, onTap: @escaping () -> Void)
}
```

| Parameter | Type | Description |
|---|---|---|
| `label` | `String` | The button's display text — one of `"Submit"`, `"Delete"`, or `"Clear"`. |
| `onTap` | `() -> Void` | Call this when the button is tapped. |

**Example custom button:**

```swift
struct MyCustomButton: View, WordWheelActionButtonProtocol {
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
                .padding(.vertical, 12)
                .background(Color.accentColor)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}
```

Then pass it to the modifier:

```swift
WordWheelView(model: model)
    .actionButton(cell: MyCustomButton.self)
```

---

## Customising Found Word Cells — `.solutionCell(cell:)`

Each entry in the found-words list is rendered using the built-in `WordWheelSolutionCell`. Replace it with any custom view using the `.solutionCell` modifier:

```swift
WordWheelView(model: model)
    .solutionCell(cell: MyCustomSolutionCell.self)
```

### Adopting `WordWheelSolutionCellProtocol`

Your custom cell must conform to `WordWheelSolutionCellProtocol`:

```swift
public protocol WordWheelSolutionCellProtocol: View {
    init(word: String)
}
```

| Parameter | Type | Description |
|---|---|---|
| `word` | `String` | The found word to display (lowercased). |

**Example custom solution cell:**

```swift
struct MyCustomSolutionCell: View, WordWheelSolutionCellProtocol {
    var word: String

    init(word: String) {
        self.word = word
    }

    var body: some View {
        Text(word.uppercased())
            .font(.caption.bold())
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.accentColor.opacity(0.15))
            .clipShape(Capsule())
    }
}
```

Then pass it to the modifier:

```swift
WordWheelView(model: model)
    .solutionCell(cell: MyCustomSolutionCell.self)
```

---

## Callbacks

### `.onWordSubmitted(_:)`

Called every time the player submits a word, whether valid or not. Use this to show feedback, play sounds, or log attempts.

```swift
WordWheelView(model: model)
    .onWordSubmitted { word, isValid in
        if isValid {
            print("\(word) accepted!")
        } else {
            print("\(word) is not valid.")
        }
    }
```

| Parameter | Type | Description |
|---|---|---|
| `word` | `String` | The submitted word (lowercased). |
| `isValid` | `Bool` | `true` if the word is in `acceptableAnswers` and hasn't already been found. |

### `.onCompletion(_:)`

Called when the player has found every word in `acceptableAnswers`.

```swift
WordWheelView(model: model)
    .onCompletion {
        print("Puzzle complete!")
    }
```

---

## Putting It All Together

```swift
WordWheelView(model: model)
    .inputView(MyInputView.self)
    .letterCell(cell: MyCustomTile.self)
    .actionButton(cell: MyCustomButton.self)
    .solutionCell(cell: MyCustomSolutionCell.self)
    .onWordSubmitted { word, isValid in
        feedbackMessage = isValid ? "✓ \(word.capitalized)" : "Not a valid word."
    }
    .onCompletion {
        showCompletionAlert = true
    }
```
