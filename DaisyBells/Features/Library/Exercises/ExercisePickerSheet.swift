import SwiftUI
import SwiftData

@MainActor
struct ExercisePickerSheet: View {
    @State var viewModel: ExercisePickerViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var searchFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: .spacingSm) {
                searchBar
                filterBar
            }
            .padding(.horizontal, .spacingBase)
            .padding(.bottom, .spacingXs)

            Group {
                if viewModel.isLoading {
                    LoadingSpinnerView()
                } else if viewModel.exercises.isEmpty {
                    EmptyStateView(
                        icon: "dumbbell",
                        title: "No Exercises",
                        message: hasActiveFilters
                            ? "No exercises match your filters."
                            : "Create your first exercise to get started."
                    ) {
                        Button(emptyStateCreateLabel) {
                            viewModel.presentExerciseForm(prefillName: viewModel.searchQuery)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.accent)
                    }
                } else {
                    exerciseList
                }
            }
        }
        .navigationTitle("Select Exercises")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.presentExerciseForm()
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Create Exercise")
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Add (\(viewModel.selectedIds.count))") {
                    viewModel.confirmSelection()
                }
                .disabled(viewModel.selectedIds.isEmpty)
            }
        }
        .task { await viewModel.loadExercises() }
        .onChange(of: viewModel.shouldDismiss) { _, shouldDismiss in
            if shouldDismiss { dismiss() }
        }
        .sheet(isPresented: $viewModel.showCategoryManager, onDismiss: {
            Task { await viewModel.loadExercises() }
        }) {
            CategoryManagerSheet(
                viewModel: CategoryManagerViewModel(
                    categoryService: viewModel.categoryService
                )
            )
        }
        .sheet(isPresented: $viewModel.showExerciseForm) {
            NavigationStack {
                ExerciseFormView(
                    viewModel: ExerciseFormViewModel(
                        exerciseService: viewModel.exerciseService,
                        categoryService: viewModel.categoryService,
                        initialName: viewModel.exerciseFormPrefillName,
                        onSaved: { id in
                            Task { await viewModel.onExerciseCreated(id) }
                        },
                        onDismiss: { viewModel.showExerciseForm = false }
                    )
                )
            }
        }
        .background(Color.bgPrimary)
    }

    private var emptyStateCreateLabel: String {
        let query = viewModel.searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        return query.isEmpty ? "Create Exercise" : "Create \"\(query)\""
    }

    private var hasActiveFilters: Bool {
        !viewModel.searchQuery.isEmpty
            || viewModel.selectedCategoryFilter != nil
            || viewModel.selectedTypeFilter != nil
            || viewModel.showFavoritesOnly
            || viewModel.showArchived
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: .spacingSm) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.textTertiary)
            TextField("Search exercises", text: Binding(
                get: { viewModel.searchQuery },
                set: { viewModel.search(query: $0) }
            ))
            .focused($searchFocused)
            .doneKeyboardToolbar(isFocused: searchFocused) { searchFocused = false }
            .foregroundStyle(Color.textPrimary)
            if !viewModel.searchQuery.isEmpty {
                Button {
                    viewModel.search(query: "")
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

    // MARK: - Filter Bar

    private var filterBar: some View {
        HStack(spacing: .spacingSm) {
            categoryFilterButton
            typeFilterButton
            sortButton
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private var categoryFilterButton: some View {
        Menu {
            Button {
                viewModel.setCategoryFilter(nil)
            } label: {
                menuItem("All Categories", isSelected: viewModel.selectedCategoryFilter == nil)
            }
            ForEach(viewModel.categories, id: \.id) { category in
                Button {
                    viewModel.setCategoryFilter(category)
                } label: {
                    menuItem(category.name, isSelected: viewModel.selectedCategoryFilter?.id == category.id)
                }
            }
            Divider()
            Button {
                viewModel.showCategoryManager = true
            } label: {
                Label("Manage Categories", systemImage: "folder.badge.gearshape")
            }
        } label: {
            filterChip(
                title: viewModel.selectedCategoryFilter?.name ?? "Category",
                isActive: viewModel.selectedCategoryFilter != nil
            )
        }
        .frame(maxWidth: .infinity)
    }

    private var typeFilterButton: some View {
        Menu {
            Button {
                viewModel.setTypeFilter(nil)
            } label: {
                menuItem("All Types", isSelected: viewModel.selectedTypeFilter == nil)
            }
            ForEach(ExerciseType.allCases, id: \.self) { type in
                Button {
                    viewModel.setTypeFilter(type)
                } label: {
                    menuItem(type.displayName, isSelected: viewModel.selectedTypeFilter == type)
                }
            }
        } label: {
            filterChip(
                title: viewModel.selectedTypeFilter?.displayName ?? "Type",
                isActive: viewModel.selectedTypeFilter != nil
            )
        }
        .frame(maxWidth: .infinity)
    }

    private var sortButton: some View {
        Menu {
            Section("Sort By") {
                ForEach(ExerciseSortOption.allCases, id: \.self) { option in
                    Button {
                        viewModel.setSortOption(option)
                    } label: {
                        menuItem(option.displayName, isSelected: viewModel.sortOption == option)
                    }
                }
            }
            Section("Filter") {
                Button {
                    viewModel.toggleFavoritesFilter()
                } label: {
                    menuItem("Favorites Only", isSelected: viewModel.showFavoritesOnly)
                }
                Button {
                    Task { await viewModel.toggleArchivedFilter() }
                } label: {
                    menuItem("Show Archived", isSelected: viewModel.showArchived)
                }
            }
        } label: {
            filterChip(
                icon: "arrow.up.arrow.down",
                title: nil,
                isActive: viewModel.sortOption != .alphabetical || viewModel.showFavoritesOnly || viewModel.showArchived
            )
        }
    }

    private func filterChip(icon: String? = nil, title: String?, isActive: Bool) -> some View {
        HStack(spacing: .spacingXs) {
            if let icon {
                Image(systemName: icon)
                    .font(.subheadline)
            }
            if let title {
                Text(title)
                    .font(.subheadline)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, .spacingSm)
        .padding(.vertical, .spacingSm)
        .frame(maxWidth: title != nil ? .infinity : nil)
        .foregroundStyle(isActive ? Color.accent : Color.textSecondary)
        .background(isActive ? Color.accentBg : Color.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: .radiusSm))
        .overlay(
            RoundedRectangle(cornerRadius: .radiusSm)
                .stroke(isActive ? Color.accent.opacity(0.3) : Color.borderSubtle, lineWidth: 1)
        )
    }

    @ViewBuilder
    private func menuItem(_ title: String, isSelected: Bool) -> some View {
        if isSelected {
            Label(title, systemImage: "checkmark")
        } else {
            Text(title)
        }
    }

    // MARK: - Exercise List

    private var exerciseList: some View {
        List {
            ForEach(viewModel.exercises, id: \.id) { exercise in
                Button {
                    viewModel.toggleExercise(exercise)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: .spacing2xs) {
                            Text(exercise.name)
                                .foregroundStyle(exercise.isArchived ? Color.textTertiary : Color.textPrimary)
                            Text(exercise.type.displayName)
                                .font(.caption)
                                .foregroundStyle(Color.textSecondary)
                        }
                        Spacer()
                        if exercise.isFavorite {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundStyle(Color.accent)
                        }
                        if exercise.isArchived {
                            Image(systemName: "archivebox")
                                .font(.caption)
                                .foregroundStyle(Color.textTertiary)
                        }
                        if viewModel.selectedIds.contains(exercise.persistentModelID) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color.accent)
                        } else {
                            Image(systemName: "circle")
                                .foregroundStyle(Color.textTertiary)
                        }
                    }
                }
            }
            .listRowBackground(Color.bgCard)
        }
        .listStyle(.insetGrouped)
        .contentMargins(.top, .spacingXs)
        .scrollContentBackground(.hidden)
        .background(Color.bgPrimary)
    }
}
