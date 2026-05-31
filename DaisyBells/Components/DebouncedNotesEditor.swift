import SwiftUI

@MainActor
struct DebouncedNotesEditor: View {
    let initialValue: String
    let placeholder: String
    let maxLines: Int
    let onCommit: (String) async -> Void

    @State private var draft: String = ""
    @State private var persistTask: Task<Void, Never>?
    @State private var didSeed = false
    @State private var isFocused: Bool = false

    var body: some View {
        BridgedTextEditor(
            text: $draft,
            placeholder: placeholder,
            isFocused: $isFocused,
            maxLines: maxLines,
            font: .systemFont(ofSize: 13),
            textColor: .textSecondary
        )
        .task {
            if !didSeed {
                draft = initialValue
                didSeed = true
            }
        }
        .onChange(of: draft) { _, newValue in
            guard didSeed else { return }
            persistTask?.cancel()
            persistTask = Task {
                try? await Task.sleep(for: .milliseconds(500))
                if Task.isCancelled { return }
                await onCommit(newValue)
            }
        }
    }
}
