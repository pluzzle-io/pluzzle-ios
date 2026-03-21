# PluzzleSDK

Add fully interactive puzzle games to your iOS app with a few lines of SwiftUI.

## Overview

PluzzleSDK provides six self-contained game views that you can drop into any SwiftUI hierarchy. Each view manages its own state and game logic, and exposes a chainable modifier API so you can customise cell rendering, theming, and callbacks without touching the internals.

All views require **iOS 17** or later.

### Integration

Add the package to your project and import the module:

```swift
import PluzzleSDK
```

Every game follows the same pattern:

1. Create a **model** describing the puzzle configuration.
2. Instantiate the **game view** with that model.
3. Apply **modifier chains** to swap out custom cells, configure spacing, and attach callbacks.

```swift
MinesweeperGameView(model: .example)
    .grid(spacing: 4, cell: MyCell.self)
    .onInput { coord, score in … }
    .onCompletion { didWin in … }
```

### Customisation model

Each game exposes its appearance through **protocol-based slot types**. You provide a concrete `View` type that conforms to the relevant protocol and the SDK instantiates it for every cell. This keeps the SDK's internal layout and gesture handling unchanged while giving you full control over the visual design.

### Callbacks

Every game fires two categories of callbacks:

| Callback | When it fires |
|---|---|
| `.onInput` | Each time the player makes a move. |
| `.onCompletion` | Once when the game ends (win, loss, or draw). |

WordWheel additionally provides `.onWordSubmitted` which fires on every submission attempt, valid or not.

---

## Topics

### Puzzle Games

- <doc:Minesweeper>
- <doc:KelvinGrid>
- <doc:WordWheel>
- <doc:Streaks>
- <doc:Sudoku>
- <doc:Voxel>
