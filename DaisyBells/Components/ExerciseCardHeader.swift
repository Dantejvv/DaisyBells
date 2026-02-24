import SwiftUI

struct ExerciseCardHeader<Trailing: View>: View {
    let name: String
    @ViewBuilder let trailing: Trailing

    var body: some View {
        HStack {
            Text(name)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.textPrimary)

            Spacer()

            trailing
        }
        .padding(.horizontal, 14)
        .padding(.top, 10)
        .padding(.bottom, 2)
    }
}
