import SwiftUI

/// The default cell view used by ``TakuzuGameView``.
///
/// Visual scheme:
/// - **Empty (nil)** — muted gray tile, no label.
/// - **HintEligible** — orange-tinted empty tile indicating the cell can be tapped to receive its solution value.
/// - **True ("1")** — accent-tinted tile, label "1".
/// - **False ("0")** — dark tile, label "0".
/// - **Fixed givens** — slightly brighter background, no interaction animation.
/// - **Violation** — red tint overlay indicating a broken rule.
struct TakuzuCell: TakuzuCellProtocol {
    let row: Int
    let column: Int
    let value: Bool?
    let isFixed: Bool
    let isViolation: Bool
    let isHintEligible: Bool

    init(row: Int, column: Int, value: Bool?, isFixed: Bool, isViolation: Bool, isHintEligible: Bool) {
        self.row = row
        self.column = column
        self.value = value
        self.isFixed = isFixed
        self.isViolation = isViolation
        self.isHintEligible = isHintEligible
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(backgroundColor)
            if isViolation {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.red.opacity(0.25))
            }
            if let v = value {
                Text(v ? "1" : "0")
                    .font(.system(size: 18, weight: isFixed ? .heavy : .semibold, design: .rounded))
                    .foregroundStyle(labelColor)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .animation(.easeInOut(duration: 0.12), value: value)
        .animation(.easeInOut(duration: 0.12), value: isViolation)
    }

    // MARK: - Private helpers

    private var backgroundColor: Color {
        switch value {
        case nil:
            if isHintEligible { return Color.orange.opacity(0.35) }
            return isFixed ? Color(.systemGray4) : Color(.systemGray5)
        case true:
            return isFixed ? Color.accentColor.opacity(0.85) : Color.accentColor.opacity(0.6)
        case false:
            return isFixed ? Color(.label).opacity(0.8) : Color(.label).opacity(0.55)
        }
    }

    private var labelColor: Color {
        switch value {
        case nil:   return Color(.label)
        case true:  return .white
        case false: return .white
        }
    }
}
