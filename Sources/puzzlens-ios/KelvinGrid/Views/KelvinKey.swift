import SwiftUI

/// The default on-screen keyboard key used by `KelvinGridView`.
struct KelvinKey: View, KelvinKeyProtocol {
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
                .frame(height: 44)
                .background(Color(.systemGray5))
                .foregroundStyle(.primary)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }
}
