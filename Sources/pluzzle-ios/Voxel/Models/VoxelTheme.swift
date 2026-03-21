import SwiftUI

/// The colour theme applied to a ``VoxelGameView`` scene.
///
/// All colours are converted to `UIColor` when applied to SceneKit materials.
///
/// ```swift
/// VoxelGameView(model: model)
///     .theme(VoxelTheme(playerOne: .indigo, playerTwo: .orange))
/// ```
public struct VoxelTheme {
    /// Colour used for Player One's cubes. Default: `.blue`.
    public var playerOne: Color
    /// Colour used for Player Two's cubes. Default: `.red`.
    public var playerTwo: Color
    /// Colour used for the neutral seed cube placed at the origin to start the game.
    /// Default: `systemGray4`.
    public var seed: Color
    /// Colour used for the wireframe ghost nodes that indicate available placements.
    /// Default: `systemGray`.
    public var ghost: Color
    /// Colour used to highlight the winning line of cubes when the game ends.
    /// Default: `.red`.
    public var win: Color

    /// Creates a new theme with the given colours.
    ///
    /// All parameters have sensible defaults so you only need to specify the colours you want to override.
    ///
    /// - Parameters:
    ///   - playerOne: Colour for Player One's cubes. Defaults to `.blue`.
    ///   - playerTwo: Colour for Player Two's cubes. Defaults to `.red`.
    ///   - seed:      Colour for the neutral starting cube. Defaults to `systemGray4`.
    ///   - ghost:     Colour for placement-hint wireframe nodes. Defaults to `systemGray`.
    ///   - win:       Colour for the winning line highlight. Defaults to `.red`.
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

    /// The default theme (blue / red, gray seed, gray ghosts, red win).
    @MainActor public static let `default` = VoxelTheme()
}
