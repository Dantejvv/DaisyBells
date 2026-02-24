import SwiftUI
import SwiftData

@MainActor
struct TemplateListView: View {
    @State var viewModel: TemplateListViewModel
    @Environment(LibraryRouter.self) private var router

    @State private var expandedTemplateIds: Set<UUID> = []

    var body: some View {
        VStack(spacing: 0) {
            searchBar
                .padding(.horizontal, .spacingBase)
                .padding(.bottom, .spacingXs)

            Group {
                if viewModel.isLoading {
                    LoadingSpinnerView()
                } else if viewModel.templates.isEmpty {
                    EmptyStateView(
                        icon: "doc.text",
                        title: "No Workout Templates",
                        message: viewModel.searchQuery.isEmpty
                            ? "Create your first template to plan your workouts."
                            : "No templates match your search."
                    ) {
                        if viewModel.searchQuery.isEmpty {
                            Button("Create Template") {
                                viewModel.createTemplate()
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.accent)
                        }
                    }
                } else {
                    templateList
                }
            }
        }
        .task { await viewModel.loadTemplates() }
        .onChange(of: router.presentedSheet == nil) { _, isDismissed in
            if isDismissed {
                Task { await viewModel.loadTemplates() }
            }
        }
        .errorAlert(errorMessage: $viewModel.errorMessage)
        .background(Color.bgPrimary)
    }

    // MARK: - Template List

    private var templateList: some View {
        List {
            ForEach(viewModel.templates, id: \.id) { template in
                let exercises = template.templateExercises
                    .sorted { $0.order < $1.order }
                    .map { TemplateCard.ExerciseInfo(from: $0) }

                TemplateCard(
                    name: template.name,
                    exercises: exercises,
                    isExpanded: expandedTemplateIds.contains(template.id),
                    isPendingDelete: viewModel.templatePendingDelete?.id == template.id,
                    startDisabled: nil,
                    onToggleExpand: {
                        withAnimation(.snappy(duration: 0.2)) {
                            if expandedTemplateIds.contains(template.id) {
                                expandedTemplateIds.remove(template.id)
                            } else {
                                expandedTemplateIds.insert(template.id)
                            }
                        }
                    },
                    onStart: nil,
                    onEdit: { viewModel.editTemplate(template) },
                    onRequestDelete: { viewModel.requestDelete(template) },
                    onCancelDelete: { viewModel.cancelDelete() },
                    onConfirmDelete: { Task { await viewModel.confirmDelete() } },
                    onViewDetail: { viewModel.selectTemplate(template) },
                    style: .listRow
                )
                .listRowInsets(EdgeInsets())
            }
            .listRowBackground(Color.bgCard)
        }
        .listStyle(.insetGrouped)
        .contentMargins(.top, .spacingXs)
        .scrollContentBackground(.hidden)
        .background(Color.bgPrimary)
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: .spacingSm) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.textTertiary)
            TextField("Search templates", text: Binding(
                get: { viewModel.searchQuery },
                set: { newValue in
                    Task { await viewModel.search(query: newValue) }
                }
            ))
            .foregroundStyle(Color.textPrimary)
            if !viewModel.searchQuery.isEmpty {
                Button {
                    Task { await viewModel.search(query: "") }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.textTertiary)
                }
            }
        }
        .padding(.horizontal, .spacingSm)
        .padding(.vertical, .spacingSm)
        .background(Color.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: .radiusMd))
    }

}
