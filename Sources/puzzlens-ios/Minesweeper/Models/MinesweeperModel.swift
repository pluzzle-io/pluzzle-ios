import Foundation

public struct MinesweeperCoord: Hashable, Equatable, Sendable {
    public let row: Int
    public let col: Int

    public init(row: Int, col: Int) {
        self.row = row
        self.col = col
    }
}

public struct MinesweeperModel: Sendable {
    public let rows: Int
    public let columns: Int
    public let mineCount: Int
    /// Pre-placed mines. Leave empty to auto-generate on the first tap (safe-start guaranteed).
    public let mines: Set<MinesweeperCoord>

    public init(
        rows: Int,
        columns: Int,
        mineCount: Int,
        mines: Set<MinesweeperCoord> = []
    ) {
        self.rows = rows
        self.columns = columns
        self.mineCount = mineCount
        self.mines = mines
    }

    /// Returns all 8-directional neighbors that exist within the grid.
    public func neighbors(of coord: MinesweeperCoord) -> [MinesweeperCoord] {
        var result: [MinesweeperCoord] = []
        for dr in -1...1 {
            for dc in -1...1 {
                guard dr != 0 || dc != 0 else { continue }
                let r = coord.row + dr
                let c = coord.col + dc
                guard r >= 0, r < rows, c >= 0, c < columns else { continue }
                result.append(MinesweeperCoord(row: r, col: c))
            }
        }
        return result
    }

    /// Count how many of the given mines border `coord`.
    public func adjacentMineCount(for coord: MinesweeperCoord, in mines: Set<MinesweeperCoord>) -> Int {
        neighbors(of: coord).filter { mines.contains($0) }.count
    }

    /// Randomly place `mineCount` mines, skipping every coord in `safeZone`.
    public func generateMines(avoiding safeZone: Set<MinesweeperCoord>) -> Set<MinesweeperCoord> {
        var candidates: [MinesweeperCoord] = []
        for r in 0..<rows {
            for c in 0..<columns {
                let coord = MinesweeperCoord(row: r, col: c)
                if !safeZone.contains(coord) { candidates.append(coord) }
            }
        }
        candidates.shuffle()
        return Set(candidates.prefix(min(mineCount, candidates.count)))
    }

    @MainActor public static let example = MinesweeperModel(rows: 9, columns: 9, mineCount: 10)
}
