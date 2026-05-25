// TakuzuHintTests.swift
// Run: swiftc -sdk $(xcrun --sdk macosx --show-sdk-path) \
//        Sources/pluzzle-ios/Takuzu/Models/TakuzuModel.swift \
//        Tests/TakuzuHintTests.swift -o /tmp/takuzu_hint_tests && /tmp/takuzu_hint_tests
import Foundation

var passed = 0
var failed = 0

func expect(_ description: String, _ condition: Bool, file: String = #file, line: Int = #line) {
    if condition {
        print("  ✅ \(description)")
        passed += 1
    } else {
        print("  ❌ FAIL: \(description) (\(file):\(line))")
        failed += 1
    }
}

func runTests() {

    // MARK: - Test: revealHint fills one empty cell with its solution value

    print("revealHint() fills one empty cell with its solution value")
    do {
        var model = TakuzuModel.example
        let emptiesBefore = model.state.flatMap { $0 }.filter { $0 == nil }.count
        model.revealHint()
        let emptiesAfter = model.state.flatMap { $0 }.filter { $0 == nil }.count
        expect("reduces empty cell count by exactly 1", emptiesAfter == emptiesBefore - 1)
    }

    // MARK: - Test: revealed cell matches solution

    print("\nrevealHint() revealed cell matches solution value")
    do {
        var model = TakuzuModel.example
        let before = model.state
        model.revealHint()
        var changedCoords: [(row: Int, col: Int)] = []
        for r in 0..<model.size {
            for c in 0..<model.size {
                if before[r][c] == nil && model.state[r][c] != nil {
                    changedCoords.append((r, c))
                }
            }
        }
        expect("exactly one cell was revealed", changedCoords.count == 1)
        if let coord = changedCoords.first {
            expect("revealed value matches solution", model.state[coord.row][coord.col] == model.solution[coord.row][coord.col])
        }
    }

    // MARK: - Test: only reveals unfixed (nil) cells

    print("\nrevealHint() only touches currently-empty cells")
    do {
        var model = TakuzuModel.example
        let before = model.state
        model.revealHint()
        var violatedFilled = false
        for r in 0..<model.size {
            for c in 0..<model.size {
                if before[r][c] != nil && model.state[r][c] != before[r][c] {
                    violatedFilled = true
                }
            }
        }
        expect("no previously-filled cell was changed", !violatedFilled)
    }

    // MARK: - Test: no-op when board is fully filled

    print("\nrevealHint() is a no-op when no empty cells remain")
    do {
        var model = TakuzuModel(
            size: TakuzuModel.example.size,
            cells: TakuzuModel.example.cells,
            solution: TakuzuModel.example.solution,
            state: TakuzuModel.example.solution   // fully filled
        )
        let stateBefore = model.state
        model.revealHint()
        let unchanged = (0..<model.size).allSatisfy { r in
            (0..<model.size).allSatisfy { c in stateBefore[r][c] == model.state[r][c] }
        }
        expect("state is unchanged when board is full", unchanged)
    }

    // MARK: - Summary

    print("\n\(passed) passed, \(failed) failed")
    if failed > 0 { exit(1) }
}

@main struct Runner { static func main() { runTests() } }
