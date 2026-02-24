import SwiftUI

@MainActor
struct ProfileView: View {
    @State var viewModel: SettingsViewModel
    @State private var showResetConfirmation = false

    var body: some View {
        NavigationStack {
            List {
                preferencesSection
                dataSection
                dangerZoneSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .background(Color.bgPrimary)
            .navigationTitle("Profile")
            .preferredColorScheme(.dark)
            .task {
                viewModel.loadSettings()
            }
            .errorAlert(errorMessage: $viewModel.errorMessage)
            .destructiveConfirmation(
                title: "Reset All Data",
                message: "This will permanently delete all exercises, workouts, templates, and settings. This action cannot be undone.",
                isPresented: $showResetConfirmation,
                onConfirm: {
                    Task { await viewModel.resetData() }
                }
            )
        }
    }

    // MARK: - Sections

    private var preferencesSection: some View {
        Section {
            Picker(selection: Binding(
                get: { viewModel.units },
                set: { viewModel.updateUnits($0) }
            )) {
                ForEach(Units.allCases, id: \.self) { unit in
                    Text(unit.displayName).tag(unit)
                }
            } label: {
                Text("Units")
                    .foregroundStyle(Color.textPrimary)
            }

            Picker(selection: Binding(
                get: { viewModel.distanceUnits },
                set: { viewModel.updateDistanceUnits($0) }
            )) {
                ForEach(DistanceUnits.allCases, id: \.self) { unit in
                    Text(unit.displayName).tag(unit)
                }
            } label: {
                Text("Distance")
                    .foregroundStyle(Color.textPrimary)
            }

            Picker(selection: Binding(
                get: { viewModel.appearance },
                set: { viewModel.updateAppearance($0) }
            )) {
                ForEach(Appearance.allCases, id: \.self) { appearance in
                    Text(appearance.displayName).tag(appearance)
                }
            } label: {
                Text("Appearance")
                    .foregroundStyle(Color.textPrimary)
            }
        } header: {
            Text("Preferences")
                .foregroundStyle(Color.textSecondary)
        }
        .listRowBackground(Color.bgCard)
    }

    private var dataSection: some View {
        Section {
            Button {
                Task { await viewModel.exportData() }
            } label: {
                Label("Export Data", systemImage: "square.and.arrow.up")
                    .foregroundStyle(Color.textPrimary)
            }
            .disabled(viewModel.isExporting)

            Button {
                // Phase 6: Present file importer
            } label: {
                Label("Import Data", systemImage: "square.and.arrow.down")
                    .foregroundStyle(Color.textPrimary)
            }
            .disabled(viewModel.isImporting)
        } header: {
            Text("Data")
                .foregroundStyle(Color.textSecondary)
        }
        .listRowBackground(Color.bgCard)
    }

    private var dangerZoneSection: some View {
        Section {
            Button(role: .destructive) {
                showResetConfirmation = true
            } label: {
                Label("Reset All Data", systemImage: "trash")
                    .foregroundStyle(Color.destructive)
            }
        } header: {
            Text("Danger Zone")
                .foregroundStyle(Color.textSecondary)
        }
        .listRowBackground(Color.bgCard)
    }

    private var aboutSection: some View {
        Section {
            LabeledContent("Version", value: viewModel.appVersion)
                .foregroundStyle(Color.textPrimary)
        } header: {
            Text("About")
                .foregroundStyle(Color.textSecondary)
        }
        .listRowBackground(Color.bgCard)
    }
}

// MARK: - Preview

#Preview {
    ProfileView(viewModel: SettingsViewModel(settingsService: SettingsService()))
}
