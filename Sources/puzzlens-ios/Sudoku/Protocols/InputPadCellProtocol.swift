import SwiftUI

public protocol InputPadCellProtocol: View {
    init(label: String, onTap: @escaping () -> Void)
}
