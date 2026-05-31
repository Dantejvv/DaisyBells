import SwiftUI

@MainActor
struct InCardNavBar: View {
    struct LeadingButton {
        let icon: String
        let action: () -> Void
    }

    struct TrailingButton {
        let label: String
        let isDisabled: Bool
        let action: () -> Void
    }

    let leading: LeadingButton
    let trailing: TrailingButton

    var body: some View {
        HStack {
            Button(action: leading.action) {
                Image(systemName: leading.icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.textSecondary)
                    .frame(width: 32, height: 32)
                    .background(Color.white.opacity(0.06))
                    .clipShape(Circle())
                    .minTouchTarget()
            }

            Spacer()

            Button(action: trailing.action) {
                Text(trailing.label)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.bgPrimary)
                    .padding(.horizontal, .spacingBase)
                    .padding(.vertical, 7)
                    .background(Color.accent)
                    .clipShape(Capsule())
                    .minTouchTarget()
            }
            .disabled(trailing.isDisabled)
        }
        .padding(.top, .spacingSm)
        .padding(.bottom, 2)
    }
}
