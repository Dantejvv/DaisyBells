import SwiftUI

/// Settings modal with units, appearance, and data management
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var units: MockUnits = .lbs
    @State private var appearance: MockAppearance = .system
    @State private var isExporting = false
    @State private var isImporting = false
    @State private var resetConfig: ConfirmationDialogConfig?
    @State private var errorMessage: String?
    @State private var showSuccess = false
    @State private var successMessage = ""

    private let appVersion = "1.0.0"

    var body: some View {
        List {
            // Preferences section
            Section("Preferences") {
                Picker("Units", selection: $units) {
                    ForEach(MockUnits.allCases, id: \.self) { unit in
                        Text(unit.displayName).tag(unit)
                    }
                }

                Picker("Appearance", selection: $appearance) {
                    ForEach(MockAppearance.allCases, id: \.self) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
            }

            // Data management section
            Section("Data") {
                Button {
                    exportData()
                } label: {
                    HStack {
                        Label("Export Data", systemImage: "square.and.arrow.up")
                        Spacer()
                        if isExporting {
                            ProgressView()
                        }
                    }
                }
                .disabled(isExporting)

                Button {
                    importData()
                } label: {
                    HStack {
                        Label("Import Data", systemImage: "square.and.arrow.down")
                        Spacer()
                        if isImporting {
                            ProgressView()
                        }
                    }
                }
                .disabled(isImporting)

                Button(role: .destructive) {
                    resetConfig = ConfirmationDialogConfig(
                        title: "Reset All Data?",
                        message: "This will permanently delete all your exercises, templates, and workout history. This action cannot be undone.",
                        confirmTitle: "Reset All Data"
                    ) {
                        resetData()
                    }
                } label: {
                    Label("Reset All Data", systemImage: "trash")
                }
            }

            // About section
            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(appVersion)
                        .foregroundStyle(.secondary)
                }

                Link(destination: URL(string: "https://example.com/privacy")!) {
                    HStack {
                        Text("Privacy Policy")
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Link(destination: URL(string: "https://example.com/support")!) {
                    HStack {
                        Text("Support")
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Feedback section
            Section {
                Button {
                    // Rate app action
                } label: {
                    HStack {
                        Label("Rate DaisyBells", systemImage: "star")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Button {
                    // Share app action
                } label: {
                    Label("Share with Friends", systemImage: "square.and.arrow.up")
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .confirmationDialog($resetConfig)
        .errorAlert($errorMessage)
        .alert("Success", isPresented: $showSuccess) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(successMessage)
        }
    }

    private func exportData() {
        isExporting = true
        // Simulate export delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isExporting = false
            successMessage = "Data exported successfully"
            showSuccess = true
        }
    }

    private func importData() {
        isImporting = true
        // Simulate import delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isImporting = false
            successMessage = "Data imported successfully"
            showSuccess = true
        }
    }

    private func resetData() {
        successMessage = "All data has been reset"
        showSuccess = true
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
