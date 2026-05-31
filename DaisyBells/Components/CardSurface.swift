import SwiftUI

struct CardSurface: ViewModifier {
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(Color.bgCard)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.borderSubtle, lineWidth: 1)
            )
    }
}

extension View {
    func cardSurface(cornerRadius: CGFloat = .radiusLg) -> some View {
        modifier(CardSurface(cornerRadius: cornerRadius))
    }
}
