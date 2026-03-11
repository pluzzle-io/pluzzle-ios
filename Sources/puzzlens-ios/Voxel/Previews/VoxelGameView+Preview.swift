import SwiftUI

#Preview {
    VoxelGameView(model: VoxelModel(winLength: 3, maxTurns: 20))
        .node(shape: .box(chamfer: 0), size: 0.85)
        .theme(VoxelTheme(
            playerOne: .indigo,
            playerTwo: .orange,
            seed: Color(.green),
            ghost: Color(.black).opacity(0.5),
            win: Color(.red)
        ))
        .onInput { coord, player in
            let name = player == .one ? "Indigo" : "Orange"
            print("\(name) placed at (\(coord.x), \(coord.y), \(coord.z))")
        }
        .onCompletion { winner in
            if let winner {
                print(winner == .one ? "Indigo wins!" : "Orange wins!")
            } else {
                print("Draw — no winner after 20 turns.")
            }
        }
        .background(Color(.systemBackground))
}
