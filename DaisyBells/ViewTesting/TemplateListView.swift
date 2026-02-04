import SwiftUI

/// List of workout templates
struct TemplateListView: View {
    @State private var templates = MockTemplateData.templates
    @State private var deleteConfig: ConfirmationDialogConfig?

    var body: some View {
        Group {
            if templates.isEmpty {
                EmptyStateView(
                    systemImage: "list.bullet.clipboard",
                    title: "No Templates",
                    message: "Create a template for your favorite workout routines.",
                    buttonTitle: "Create Template"
                ) {
                    // Create action
                }
            } else {
                List {
                    ForEach(templates) { template in
                        NavigationLink {
                            TemplateDetailView(template: template)
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
                                    withAnimation {
                                        templates.removeAll { $0.id == template.id }
                                    }
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
                NavigationLink {
                    TemplateFormView(template: nil)
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .confirmationDialog($deleteConfig)
    }
}

private struct TemplateRow: View {
    let template: MockTemplate

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(template.name)
                .font(.body)

            HStack(spacing: 4) {
                Text("\(template.exerciseCount) exercises")

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

#Preview("With Templates") {
    NavigationStack {
        TemplateListView()
    }
}

#Preview("Empty") {
    NavigationStack {
        TemplateListView()
            .onAppear {
                // Would clear templates in real app
            }
    }
}
