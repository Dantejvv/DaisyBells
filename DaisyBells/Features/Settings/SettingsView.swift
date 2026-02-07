import SwiftUI

/// Settings view with units, appearance, and data management
struct SettingsView: View {
    @State private var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var resetConfig: ConfirmationDialogConfig?
    @State private var showSuccess = false
    @State private var successMessage = ""

    init(viewModel: SettingsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        List {
            // Preferences section
            Section("Preferences") {
                Picker("Units", selection: Binding(
                    get: { viewModel.units },
                    set: { viewModel.updateUnits($0) }
                )) {
                    ForEach(Units.allCases, id: \.self) { unit in
                        Text(unit.displayName).tag(unit)
                    }
                }

                Picker("Appearance", selection: Binding(
                    get: { viewModel.appearance },
                    set: { viewModel.updateAppearance($0) }
                )) {
                    ForEach(Appearance.allCases, id: \.self) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
            }

            // Data management section
            Section("Data") {
                Button {
                    Task { await viewModel.exportData() }
                } label: {
                    HStack {
                        Label("Export Data", systemImage: "square.and.arrow.up")
                        Spacer()
                        if viewModel.isExporting {
                            ProgressView()
                        }
                    }
                }
                .disabled(viewModel.isExporting)

                Button {
                    // Phase 6 feature
                } label: {
                    HStack {
                        Label("Import Data", systemImage: "square.and.arrow.down")
                        Spacer()
                    }
                }

                Button(role: .destructive) {
                    resetConfig = ConfirmationDialogConfig(
                        title: "Reset All Data?",
                        message: "This will permanently delete all your exercises, templates, and workout history. This action cannot be undone.",
                        confirmTitle: "Reset All Data"
                    ) {
                        Task { await viewModel.resetData() }
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
                    Text(viewModel.appVersion)
                        .foregroundStyle(.secondary)
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
        .errorAlert(Binding(
            get: { viewModel.errorMessage },
            set: { viewModel.errorMessage = $0 }
        ))
        .onAppear {
            viewModel.loadSettings()
        }
    }
}
