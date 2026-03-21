import Foundation

/// One of the two players in a Voxel game.
public enum VoxelPlayer: Equatable {
    /// The first player (shown in the theme's `playerOne` colour).
    case one
    /// The second player (shown in the theme's `playerTwo` colour).
    case two

    /// The opposing player.
    public var next: VoxelPlayer { self == .one ? .two : .one }
}

/// Configuration for a Voxel (3D Tic-Tac-Toe) game.
///
/// Pass a `VoxelModel` to ``VoxelGameView`` to control the win condition and turn limit.
///
/// ```swift
/// // Standard 3-in-a-row, unlimited turns
/// VoxelGameView(model: VoxelModel())
///
/// // 4-in-a-row with a 30-turn limit
/// VoxelGameView(model: VoxelModel(winLength: 4, maxTurns: 30))
/// ```
public struct VoxelModel {
    /// Number of consecutive cubes in a straight line required to win. Default: `3`.
    public let winLength: Int
    /// Maximum total placements allowed before the game ends as a draw.
    /// Set to `0` (default) for an unlimited game.
    public let maxTurns: Int

    /// Creates a new Voxel game configuration.
    ///
    /// - Parameters:
    ///   - winLength: How many cubes in a row are needed to win. Defaults to `3`.
    ///   - maxTurns: Turn limit; pass `0` for no limit. Defaults to `0`.
    public init(winLength: Int = 3, maxTurns: Int = 0) {
        self.winLength = winLength
        self.maxTurns = maxTurns
    }
}
