import SwiftUI
import SwiftData

@MainActor
struct ExerciseListView: View {
    @State var viewModel: ExerciseListViewModel
    @Environment(LibraryRouter.self) private var router

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
                        message: viewModel.searchQuery.isEmpty
                            ? "Create your first exercise to start building your library."
                            : "No exercises match your search."
                    ) {
                        if viewModel.searchQuery.isEmpty {
                            Button("Create Exercise") {
                                viewModel.createExercise()
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.accent)
                        }
                    }
                } else {
                    exerciseList
                }
            }
        }
        .navigationTitle(viewModel.selectedCategoryId != nil ? "Exercises" : "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if viewModel.selectedCategoryId != nil {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.createExercise()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .task { await viewModel.loadExercises() }
        .onChange(of: router.presentedSheet == nil) { _, isDismissed in
            if isDismissed {
                Task { await viewModel.loadExercises() }
            }
        }
        .errorAlert(errorMessage: $viewModel.errorMessage)
        .sheet(isPresented: $viewModel.showCategoryManager, onDismiss: {
            Task { await viewModel.loadExercises() }
        }) {
            CategoryManagerSheet(
                viewModel: CategoryManagerViewModel(
                    categoryService: viewModel.categoryService
                )
            )
            .presentationBackground(Color.bgPrimary)
        }
        .background(Color.bgPrimary)
        .tapToDismissKeyboard()
    }

    // MARK: - Exercise List

    private var exerciseList: some View {
        List {
            ForEach(viewModel.exercises, id: \.id) { exercise in
                exerciseRow(exercise)
            }
            .listRowBackground(Color.bgCard)
        }
        .listStyle(.insetGrouped)
        .scrollDismissesKeyboard(.interactively)
        .contentMargins(.top, .spacingXs)
        .scrollContentBackground(.hidden)
        .background(Color.bgPrimary)
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        SearchBar(
            placeholder: "Search exercises",
            text: Binding(
                get: { viewModel.searchQuery },
                set: { newValue in
                    Task { await viewModel.search(query: newValue) }
                }
            ),
            onClear: { Task { await viewModel.search(query: "") } }
        )
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
                Task { await viewModel.setCategoryFilter(nil) }
            } label: {
                menuItem("All Categories", isSelected: viewModel.selectedCategoryFilter == nil)
            }
            ForEach(viewModel.allCategories, id: \.id) { category in
                Button {
                    Task { await viewModel.setCategoryFilter(category) }
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
                Task { await viewModel.setTypeFilter(nil) }
            } label: {
                menuItem("All Types", isSelected: viewModel.selectedTypeFilter == nil)
            }
            ForEach(ExerciseType.allCases, id: \.self) { type in
                Button {
                    Task { await viewModel.setTypeFilter(type) }
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
                        Task { await viewModel.setSortOption(option) }
                    } label: {
                        menuItem(option.displayName, isSelected: viewModel.sortOption == option)
                    }
                }
            }
            Section("Filter") {
                Button {
                    Task { await viewModel.toggleFavoritesFilter() }
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

    // MARK: - Exercise Row

    private func exerciseRow(_ exercise: SchemaV1.Exercise) -> some View {
        let isPendingDelete = viewModel.exercisePendingDelete?.id == exercise.id

        return Button {
            if !isPendingDelete {
                viewModel.selectExercise(exercise)
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: .spacing2xs) {
                    Text(exercise.name)
                        .foregroundStyle(
                            isPendingDelete ? Color.textTertiary :
                            exercise.isArchived ? Color.textTertiary : Color.textPrimary
                        )
                    Text(exercise.type.displayName)
                        .font(.caption)
                        .foregroundStyle(isPendingDelete ? Color.textTertiary : Color.textSecondary)
                }

                Spacer()

                if isPendingDelete {
                    deleteConfirmationButtons(exercise)
                } else {
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

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(Color.textTertiary)
                }
            }
        }
        .opacity(isPendingDelete ? 0.5 : 1.0)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button {
                viewModel.requestDelete(exercise)
            } label: {
                Label("Delete", systemImage: "trash")
            }
            .tint(.destructive)
            Button {
                viewModel.editExercise(exercise)
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            .tint(.accent)
        }
    }

    private func deleteConfirmationButtons(_ exercise: SchemaV1.Exercise) -> some View {
        HStack(spacing: .spacingSm) {
            Button {
                viewModel.cancelDelete()
            } label: {
                Text("Cancel")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.textSecondary)
                    .padding(.horizontal, .spacingSm)
                    .padding(.vertical, .spacingXs)
                    .background(Color.bgCardHover)
                    .clipShape(RoundedRectangle(cornerRadius: .radiusSm))
            }
            .buttonStyle(.plain)

            Button {
                Task { await viewModel.confirmDelete() }
            } label: {
                Text("Confirm")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, .spacingSm)
                    .padding(.vertical, .spacingXs)
                    .background(Color.destructive)
                    .clipShape(RoundedRectangle(cornerRadius: .radiusSm))
            }
            .buttonStyle(.plain)
        }
    }
}
