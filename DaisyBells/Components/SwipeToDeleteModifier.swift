import SwiftUI

struct SwipeToDeleteModifier: ViewModifier {
    let enabled: Bool
    let onDelete: () -> Void

    @State private var offset: CGFloat = 0
    @State private var revealed = false
    @State private var deleting = false

    private let buttonWidth: CGFloat = 70
    private let revealThreshold: CGFloat = 50

    func body(content: Content) -> some View {
        if !enabled {
            content
        } else {
            ZStack(alignment: .trailing) {
                // Delete button behind the row
                deleteButton
                    .opacity(offset < 0 || revealed ? 1 : 0)

                // Row content slides left
                content
                    .offset(x: deleting ? -500 : revealed ? -buttonWidth : offset)
                    .highPriorityGesture(dragGesture)
            }
            .clipped()
        }
    }

    private var deleteButton: some View {
        Button {
            withAnimation(.easeIn(duration: 0.2)) {
                deleting = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                onDelete()
            }
        } label: {
            Image(systemName: "trash")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: buttonWidth)
                .frame(maxHeight: .infinity)
                .background(Color.red)
        }
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 20)
            .onChanged { value in
                let horizontal = abs(value.translation.width)
                let vertical = abs(value.translation.height)

                // Only respond to mostly-horizontal drags
                guard horizontal > vertical else { return }

                if revealed {
                    // Allow dragging further left or back to close
                    let newOffset = -buttonWidth + value.translation.width
                    offset = min(0, max(-buttonWidth * 1.5, newOffset))
                } else {
                    // Only respond to leftward drags
                    let newOffset = min(0, value.translation.width)
                    offset = max(-buttonWidth * 1.5, newOffset)
                }
            }
            .onEnded { value in
                if revealed {
                    // If dragged right past halfway, close
                    if value.translation.width > buttonWidth / 2 {
                        close()
                    } else {
                        snapOpen()
                    }
                } else {
                    if -value.translation.width > revealThreshold {
                        snapOpen()
                    } else {
                        close()
                    }
                }
            }
    }

    private func snapOpen() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            revealed = true
            offset = -buttonWidth
        }
    }

    private func close() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            revealed = false
            offset = 0
        }
    }
}

extension View {
    func swipeToDelete(enabled: Bool, onDelete: @escaping () -> Void) -> some View {
        modifier(SwipeToDeleteModifier(enabled: enabled, onDelete: onDelete))
    }
}
