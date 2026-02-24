import SwiftUI

struct SetNumberBadge: View {
    let number: Int
    let style: Style

    enum Style {
        case completed
        case active
        case pending
        case neutral

        var foregroundColor: Color {
            switch self {
            case .completed: Color.success
            case .active: Color.accent
            case .pending: Color.textTertiary
            case .neutral: Color.textTertiary
            }
        }

        var backgroundColor: Color {
            switch self {
            case .completed: Color.successBg
            case .active: Color.accentBg
            case .pending: Color.white.opacity(0.04)
            case .neutral: Color.white.opacity(0.04)
            }
        }
    }

    var body: some View {
        Text("\(number)")
            .font(.system(size: 14, weight: .bold))
            .frame(width: 22, height: 22)
            .foregroundStyle(style.foregroundColor)
            .background(style.backgroundColor)
            .clipShape(Circle())
    }
}
