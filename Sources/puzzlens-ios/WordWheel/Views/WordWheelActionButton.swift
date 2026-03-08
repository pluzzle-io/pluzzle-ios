import SwiftUI

/// The default action button used by `WordWheelView` for Submit, Delete, and Clear.
struct WordWheelActionButton: View, WordWheelActionButtonProtocol {
    var label: String
    var onTap: () -> Void

    init(label: String, onTap: @escaping () -> Void) {
        self.label = label
        self.onTap = onTap
    }

    private var color: Color {
        switch label {
        case "Submit": return .green
        case "Delete": return .orange
        default:       return .red.opacity(0.8)
        }
    }

    var body: some View {
        Button(action: onTap) {
            Text(label)
                .font(.subheadline.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(color)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}
