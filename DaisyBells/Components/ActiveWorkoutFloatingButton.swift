import SwiftUI

@MainActor
struct ActiveWorkoutFloatingButton: View {
    @Environment(ActiveWorkoutManager.self) private var manager

    var body: some View {
        Button {
            manager.showSheet()
        } label: {
            HStack(spacing: .spacingSm) {
                pulseDot

                VStack(alignment: .leading, spacing: .spacing2xs) {
                    Text(manager.workoutName ?? "Workout")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.textPrimary)
                        .lineLimit(1)

                    Text("In Progress")
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                }

                Spacer()

                Text(formattedElapsedTime)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.accent)
                    .monospacedDigit()
            }
            .padding(.horizontal, .spacingBase)
            .padding(.vertical, .spacingMd)
            .background(Color.bgElevated)
            .clipShape(RoundedRectangle(cornerRadius: .radiusLg))
            .overlay(
                RoundedRectangle(cornerRadius: .radiusLg)
                    .stroke(Color.accent.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, .spacingBase)
        .padding(.top, -8)
        .padding(.bottom, .spacingMd)
    }

    // MARK: - Subviews

    private var pulseDot: some View {
        Circle()
            .fill(Color.success)
            .frame(width: 8, height: 8)
            .modifier(PulseModifier())
    }

    // MARK: - Helpers

    private var formattedElapsedTime: String {
        let totalSeconds = Int(manager.elapsedTime)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Pulse Animation Modifier

private struct PulseModifier: ViewModifier {
    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .overlay(
                Circle()
                    .fill(Color.success.opacity(0.4))
                    .scaleEffect(isPulsing ? 2.2 : 1.0)
                    .opacity(isPulsing ? 0 : 0.6)
            )
            .onAppear {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: false)) {
                    isPulsing = true
                }
            }
    }
}
