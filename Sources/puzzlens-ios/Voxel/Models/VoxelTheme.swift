import SwiftUI

/// Colour theme for a Voxel game.
public struct VoxelTheme {
    /// Colour used for Player One's cubes.
    public var playerOne: Color
    /// Colour used for Player Two's cubes.
    public var playerTwo: Color
    /// Colour used for the neutral seed cube.
    public var seed: Color
    /// Colour used for available-placement ghost nodes.
    public var ghost: Color
    /// Colour used to highlight the winning cubes on game end.
    public var win: Color

    public init(
        playerOne: Color = .blue,
        playerTwo: Color = .red,
        seed: Color = Color(.systemGray4),
        ghost: Color = Color(.systemGray),
        win: Color = .red
    ) {
        self.playerOne = playerOne
        self.playerTwo = playerTwo
        self.seed = seed
        self.ghost = ghost
        self.win = win
    }

    @MainActor public static let `default` = VoxelTheme()
}
