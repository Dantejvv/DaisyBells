import SwiftUI

struct NewWorkoutCard: View {
    let isDisabled: Bool
    let onStart: () -> Void

    var body: some View {
        HStack(spacing: .spacingSm) {
            VStack(alignment: .leading, spacing: 2) {
                Text("New Workout")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.textPrimary)
                Text("Start with a blank workout")
                    .font(.caption)
                    .foregroundStyle(Color.textTertiary)
            }

            Spacer()

            Button {
                onStart()
            } label: {
                Text("Start")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(isDisabled ? Color.textTertiary : Color.accent)
                    .padding(.horizontal, .spacingMd)
                    .padding(.vertical, .spacingXs)
                    .background(isDisabled ? Color.bgCardHover : Color.accentBg)
                    .clipShape(RoundedRectangle(cornerRadius: .radiusSm))
            }
            .buttonStyle(.plain)
            .disabled(isDisabled)
        }
        .padding(.spacingBase)
        .background(Color.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: .radiusLg))
        .overlay(
            RoundedRectangle(cornerRadius: .radiusLg)
                .stroke(Color.accent.opacity(0.3), lineWidth: 1)
        )
    }
}
