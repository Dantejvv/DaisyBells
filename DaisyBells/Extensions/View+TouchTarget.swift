import SwiftUI

extension View {
    func minTouchTarget(_ size: CGFloat = 44) -> some View {
        contentShape(Rectangle())
            .frame(minWidth: size, minHeight: size)
    }
}
