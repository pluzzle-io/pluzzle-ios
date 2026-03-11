import Foundation

/// One of the two players in a Voxel game.
public enum VoxelPlayer: Equatable {
    case one
    case two

    /// The other player.
    var next: VoxelPlayer { self == .one ? .two : .one }
}

/// Configuration for a Voxel puzzle.
public struct VoxelModel {
    /// Number of consecutive cubes required to win (default: 3).
    public let winLength: Int
    /// Total number of player turns allowed before the game ends as a draw.
    /// Set to `0` (default) for an unlimited game.
    public let maxTurns: Int

    public init(winLength: Int = 3, maxTurns: Int = 0) {
        self.winLength = winLength
        self.maxTurns = maxTurns
    }
}
