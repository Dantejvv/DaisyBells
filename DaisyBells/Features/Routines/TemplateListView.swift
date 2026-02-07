import SwiftUI

/// List of workout templates
struct TemplateListView: View {
    @State private var viewModel: TemplateListViewModel
    @State private var deleteConfig: ConfirmationDialogConfig?

    init(viewModel: TemplateListViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingSpinnerView(message: "Loading templates...")
            } else if viewModel.templates.isEmpty {
                EmptyStateView(
                    systemImage: "list.bullet.clipboard",
                    title: "No Templates",
                    message: "Create a template for your favorite workout routines.",
                    buttonTitle: "Create Template"
                ) {
                    viewModel.createTemplate()
                }
            } else {
                List {
                    ForEach(viewModel.templates) { template in
                        Button {
                            viewModel.selectTemplate(template)
                        } label: {
                            TemplateRow(template: template)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button("Delete", role: .destructive) {
                                deleteConfig = ConfirmationDialogConfig(
                                    title: "Delete \"\(template.name)\"?",
                                    message: "This template will be permanently deleted. Your workout history will not be affected.",
                                    confirmTitle: "Delete"
                                ) {
                                    Task { await viewModel.deleteTemplate(template) }
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Templates")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.createTemplate()
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .confirmationDialog($deleteConfig)
        .errorAlert(Binding(
            get: { viewModel.errorMessage },
            set: { viewModel.errorMessage = $0 }
        ))
        .task { await viewModel.loadTemplates() }
    }
}

private struct TemplateRow: View {
    let template: SchemaV1.WorkoutTemplate

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(template.name)
                .font(.body)
                .foregroundStyle(.primary)

            HStack(spacing: 4) {
                Text("\(template.templateExercises.count) exercises")

                if let notes = template.notes, !notes.isEmpty {
                    Text("•")
                    Text(notes)
                        .lineLimit(1)
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}
