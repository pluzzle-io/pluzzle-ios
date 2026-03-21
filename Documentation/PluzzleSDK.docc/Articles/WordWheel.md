# Word Wheel

Add a letter-wheel word-finding puzzle to your app.

## Overview

`WordWheelView` presents a set of letters arranged in a circle. The player taps letters to spell words, each of which must include the central **main letter**. Valid words are collected in a found-words list below the wheel. The puzzle is complete when every acceptable answer has been found.

### Getting started

```swift
import PluzzleSDK

let model = WordWheelModel(
    mainLetter: "E",
    letters: ["R", "A", "T", "H", "N", "G", "S"],
    acceptableAnswers: ["earth", "heart", "hate", "rate", "grate", "great", "stare"]
)

WordWheelView(model: model)
    .padding()
```

### How the game works

1. The player taps wheel tiles to spell a word — each tile can only be used once per attempt.
2. The main letter tile is always available at the centre.
3. **Delete** removes the last letter. **Clear** resets the current attempt.
4. **Submit** validates the word:
   - It must appear in `acceptableAnswers`.
   - It must not have already been found.
5. Accepted words appear in the found-words list.
6. The puzzle ends when every `acceptableAnswer` has been found.

---

## WordWheelModel

```swift
public struct WordWheelModel {
    public let mainLetter: String
    public let letters: [String]
    public let currentAnswers: [String]
    public let acceptableAnswers: [String]

    public init(
        mainLetter: String,
        letters: [String],
        currentAnswers: [String] = [],
        acceptableAnswers: [String]
    )
}
```

| Property | Description |
|---|---|
| `mainLetter` | The centre tile. Every valid word must contain it. |
| `letters` | The outer ring tiles (excluding the main letter). |
| `currentAnswers` | Already-found words — pass these to restore a saved session. |
| `acceptableAnswers` | All valid words for this puzzle (stored lowercased). |

### Restoring a session

```swift
let model = WordWheelModel(
    mainLetter: "E",
    letters: ["R", "A", "T", "H", "N", "G", "S"],
    currentAnswers: ["earth", "heart"],   // already found
    acceptableAnswers: ["earth", "heart", "hate", "rate", "grate", "great", "stare"]
)
```

---

## Customising Letter Tiles — `.letterCell(cell:)`

```swift
WordWheelView(model: model)
    .letterCell(cell: MyCustomTile.self)
```

### WordWheelLetterCellProtocol

```swift
public protocol WordWheelLetterCellProtocol: View {
    init(letter: String, isMain: Bool, isUsed: Bool, onTap: @escaping () -> Void)
}
```

| Parameter | Type | Description |
|---|---|---|
| `letter` | `String` | The letter on this tile (always uppercased). |
| `isMain` | `Bool` | `true` for the centre/main tile. |
| `isUsed` | `Bool` | `true` when already tapped in the current word attempt. |
| `onTap` | `() -> Void` | Call this when the tile is tapped. |

### Example custom tile

```swift
struct MyCustomTile: View, WordWheelLetterCellProtocol {
    var letter: String
    var isMain: Bool
    var isUsed: Bool
    var onTap: () -> Void

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

---

## Customising Action Buttons — `.actionButton(cell:)`

```swift
WordWheelView(model: model)
    .actionButton(cell: MyCustomButton.self)
```

### WordWheelActionButtonProtocol

```swift
public protocol WordWheelActionButtonProtocol: View {
    init(label: String, onTap: @escaping () -> Void)
}
```

| Parameter | Type | Description |
|---|---|---|
| `label` | `String` | One of `"Submit"`, `"Delete"`, or `"Clear"`. |
| `onTap` | `() -> Void` | Call this when the button is tapped. |

### Example custom button

```swift
struct MyCustomButton: View, WordWheelActionButtonProtocol {
    var label: String
    var onTap: () -> Void

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

---

## Customising Found-Word Cells — `.solutionCell(cell:)`

```swift
WordWheelView(model: model)
    .solutionCell(cell: MyCustomSolutionCell.self)
```

### WordWheelSolutionCellProtocol

```swift
public protocol WordWheelSolutionCellProtocol: View {
    init(word: String)
}
```

| Parameter | Type | Description |
|---|---|---|
| `word` | `String` | The found word to display (lowercased). |

### Example custom solution cell

```swift
struct MyCustomSolutionCell: View, WordWheelSolutionCellProtocol {
    var word: String

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

---

## Callbacks

### `.onWordSubmitted(_:)`

Called every time the player submits a word, whether valid or not.

```swift
WordWheelView(model: model)
    .onWordSubmitted { word, isValid in
        feedbackMessage = isValid ? "✓ \(word.capitalized)" : "Not a valid word."
    }
```

| Parameter | Type | Description |
|---|---|---|
| `word` | `String` | The submitted word (lowercased). |
| `isValid` | `Bool` | `true` if the word is in `acceptableAnswers` and not already found. |

### `.onCompletion(_:)`

Called when the player has found every word in `acceptableAnswers`.

```swift
WordWheelView(model: model)
    .onCompletion {
        showCompletionAlert = true
    }
```

---

## Putting It All Together

```swift
WordWheelView(model: model)
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
