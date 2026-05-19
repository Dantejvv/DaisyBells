import SwiftUI
import UniformTypeIdentifiers

@MainActor
struct ProfileView: View {
    @State var viewModel: SettingsViewModel
    @State private var showResetConfirmation = false
    @State private var showResetTypeToConfirm = false
    @State private var showImportConfirmation = false

    var body: some View {
        List {
            preferencesSection
            dataSection
            dangerZoneSection
            aboutSection
        }
        .scrollContentBackground(.hidden)
        .background(Color.bgPrimary)
        .navigationTitle("Profile")
        .task {
            viewModel.loadSettings()
        }
        .errorAlert(errorMessage: $viewModel.errorMessage)
        .destructiveConfirmation(
            title: "Reset All Data",
            message: "This will permanently delete all exercises, workouts, templates, and settings. This action cannot be undone.",
            isPresented: $showResetConfirmation,
            onConfirm: {
                showResetTypeToConfirm = true
            }
        )
        .sheet(isPresented: $showResetTypeToConfirm) {
            TypeToConfirmSheet(
                title: "Reset All Data",
                message: "This will permanently delete all exercises, workouts, templates, and settings. This action cannot be undone.",
                confirmationPhrase: "DELETE",
                confirmButtonLabel: "Reset All Data",
                onConfirm: {
                    Task { await viewModel.resetData() }
                }
            )
        }
        .destructiveConfirmation(
            title: "Import Data",
            message: "Importing will replace all existing data with the contents of the selected file. This action cannot be undone.",
            isPresented: $showImportConfirmation,
            onConfirm: {
                viewModel.showFileImporter = true
            }
        )
        .fileExporter(
            isPresented: $viewModel.showFileExporter,
            document: viewModel.exportDocument,
            contentType: .json,
            defaultFilename: "DaisyBells-Backup"
        ) { result in
            viewModel.exportDocument = nil
            if case .failure(let error) = result {
                viewModel.errorMessage = error.localizedDescription
            }
        }
        .fileImporter(
            isPresented: $viewModel.showFileImporter,
            allowedContentTypes: [.json]
        ) { result in
            switch result {
            case .success(let url):
                Task { await viewModel.importData(url: url) }
            case .failure(let error):
                viewModel.errorMessage = error.localizedDescription
            }
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
                showImportConfirmation = true
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
    NavigationStack {
        ProfileView(viewModel: SettingsViewModel(settingsService: SettingsService()))
    }
}
