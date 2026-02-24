import SwiftUI
import SwiftData

@MainActor
struct SplitListView: View {
    @State var viewModel: SplitListViewModel
    @Environment(HomeRouter.self) private var router

    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingSpinnerView()
            } else if viewModel.splits.isEmpty {
                EmptyStateView(
                    icon: "calendar",
                    title: "No Splits Yet",
                    message: "Create a split to organize your training week."
                ) {
                    Button("Create Split") {
                        viewModel.createSplit()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.accent)
                }
            } else {
                splitList
            }
        }
        .navigationTitle("Splits")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    viewModel.createSplit()
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .task { await viewModel.loadSplits() }
        .onChange(of: router.presentedSheet == nil) { _, isDismissed in
            if isDismissed {
                Task { await viewModel.loadSplits() }
            }
        }
        .errorAlert(errorMessage: $viewModel.errorMessage)
        .background(Color.bgPrimary)
        .preferredColorScheme(.dark)
    }

    // MARK: - Split List

    private var splitList: some View {
        List {
            noneRow

            ForEach(viewModel.splits, id: \.id) { split in
                splitRow(split)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            viewModel.requestDelete(split)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }

                        Button {
                            viewModel.editSplit(split)
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(.accent)
                    }
            }
            .listRowBackground(Color.bgCard)

            Button {
                viewModel.createSplit()
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(Color.accent)
                    Text("Add Split")
                        .foregroundStyle(Color.accent)
                }
            }
            .listRowBackground(Color.bgCard)
        }
        .listStyle(.insetGrouped)
        .contentMargins(.top, .spacingXs)
        .scrollContentBackground(.hidden)
        .background(Color.bgPrimary)
    }

    // MARK: - None Row

    private var noneRow: some View {
        Button {
            viewModel.clearActiveSplit()
        } label: {
            HStack {
                Text("None")
                    .font(.body.weight(.medium))
                    .foregroundStyle(Color.textPrimary)

                Spacer()

                if viewModel.activeSplitId == nil {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.accent)
                        .font(.title3)
                }
            }
        }
        .buttonStyle(.plain)
        .listRowBackground(Color.bgCard)
    }

    // MARK: - Split Row

    private func splitRow(_ split: SchemaV1.Split) -> some View {
        let isPendingDelete = viewModel.splitPendingDelete?.id == split.id
        let isActive = viewModel.activeSplitId == split.id
        let dayCount = split.days.count

        return Button {
            if !isPendingDelete {
                viewModel.setActiveSplit(split)
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: .spacing2xs) {
                    Text(split.name)
                        .font(.body.weight(.medium))
                        .foregroundStyle(isPendingDelete ? Color.textTertiary : Color.textPrimary)
                    Text("\(dayCount) day\(dayCount == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(isPendingDelete ? Color.textTertiary : Color.textSecondary)
                }

                Spacer()

                if isPendingDelete {
                    deleteConfirmationButtons(split)
                } else if isActive {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.accent)
                        .font(.title3)
                }
            }
        }
        .buttonStyle(.plain)
        .opacity(isPendingDelete ? 0.5 : 1.0)
    }

    // MARK: - Delete Confirmation

    private func deleteConfirmationButtons(_ split: SchemaV1.Split) -> some View {
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
