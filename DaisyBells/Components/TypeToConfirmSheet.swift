import SwiftUI

@MainActor
struct TypeToConfirmSheet: View {
    let title: String
    let message: String
    let confirmationPhrase: String
    let confirmButtonLabel: String
    let onConfirm: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var typed: String = ""
    @State private var fieldFocused: Bool = false

    private var matches: Bool { typed == confirmationPhrase }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text(message)
                        .font(.system(size: 14))
                        .foregroundStyle(Color.textSecondary)
                }
                .listRowBackground(Color.bgCard)

                Section {
                    BridgedTextField(
                        text: $typed,
                        placeholder: "Type \(confirmationPhrase)",
                        isFocused: $fieldFocused,
                        autocapitalization: .allCharacters,
                        autocorrection: .no,
                        textColor: .textPrimary,
                        onSubmit: { fieldFocused = false }
                    )
                } header: {
                    Text("Type \(confirmationPhrase) to confirm")
                        .foregroundStyle(Color.textSecondary)
                }
                .listRowBackground(Color.bgCard)

                Section {
                    Button(role: .destructive) {
                        onConfirm()
                        dismiss()
                    } label: {
                        Label(confirmButtonLabel, systemImage: "trash")
                            .foregroundStyle(matches ? Color.destructive : Color.textTertiary)
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(!matches)
                }
                .listRowBackground(Color.bgCard)
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color.bgPrimary)
            .tapToDismissKeyboard()
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .task {
                // Sheet-presentation focus needs a small delay on iOS — without it,
                // the keyboard intermittently fails to appear.
                try? await Task.sleep(for: .milliseconds(500))
                fieldFocused = true
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}
