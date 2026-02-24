import SwiftUI

struct ReadOnlyDualPill: View {
    let left: String
    let right: String

    var body: some View {
        HStack(spacing: 0) {
            Text(left)
                .frame(maxWidth: .infinity)
            Rectangle()
                .fill(Color.borderDefault)
                .frame(width: 1, height: 16)
            Text(right)
                .frame(maxWidth: .infinity)
        }
        .font(.system(size: 13))
        .foregroundStyle(Color.textPrimary)
        .frame(width: 94)
        .padding(.vertical, 5)
        .background(Color.bgInput)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color.borderSubtle, lineWidth: 1)
        )
    }
}

struct ReadOnlySinglePill: View {
    let value: String

    var body: some View {
        Text(value)
            .font(.system(size: 13))
            .foregroundStyle(Color.textPrimary)
            .frame(width: 46)
            .padding(.vertical, 5)
            .background(Color.bgInput)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.borderSubtle, lineWidth: 1)
            )
    }
}
