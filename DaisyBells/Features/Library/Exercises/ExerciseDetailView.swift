import SwiftUI
import SwiftData

@MainActor
struct ExerciseDetailView: View {
    @State var viewModel: ExerciseDetailViewModel
    @State private var showDeleteConfirmation = false

    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingSpinnerView()
            } else if let exercise = viewModel.exercise {
                exerciseContent(exercise)
            } else {
                Color.clear
            }
        }
        .navigationTitle(viewModel.exercise?.name ?? "Exercise")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    viewModel.editExercise()
                } label: {
                    Text("Edit")
                }
            }
        }
        .task { await viewModel.loadExercise() }
        .errorAlert(errorMessage: $viewModel.errorMessage)
        .destructiveConfirmation(
            title: viewModel.canDelete ? "Delete Exercise" : "Archive Exercise",
            message: viewModel.canDelete
                ? "This exercise will be permanently deleted."
                : "This exercise has workout history and will be archived instead.",
            isPresented: $showDeleteConfirmation,
            onConfirm: {
                Task { await viewModel.deleteExercise() }
            }
        )
        .background(Color.bgPrimary)
    }

    // MARK: - Content

    private func exerciseContent(_ exercise: SchemaV1.Exercise) -> some View {
        List {
            headerSection(exercise)
            if !exercise.categories.isEmpty {
                categoriesSection(exercise)
            }
            if let notes = exercise.notes, !notes.isEmpty {
                notesSection(notes)
            }
            unitSection(exercise)
            statsSection
            actionsSection
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.bgPrimary)
    }

    // MARK: - Sections

    private func headerSection(_ exercise: SchemaV1.Exercise) -> some View {
        Section {
            HStack {
                Text("Type")
                    .foregroundStyle(Color.textSecondary)
                Spacer()
                Text(exercise.type.displayName)
                    .foregroundStyle(Color.textPrimary)
            }

            HStack {
                Text("Favorite")
                    .foregroundStyle(Color.textSecondary)
                Spacer()
                Button {
                    Task { await viewModel.toggleFavorite() }
                } label: {
                    Image(systemName: exercise.isFavorite ? "star.fill" : "star")
                        .foregroundStyle(exercise.isFavorite ? Color.accent : Color.textTertiary)
                }
            }

            if exercise.isArchived {
                HStack {
                    Text("Status")
                        .foregroundStyle(Color.textSecondary)
                    Spacer()
                    Text("Archived")
                        .foregroundStyle(Color.warning)
                }
            }
        }
        .listRowBackground(Color.bgCard)
    }

    private func categoriesSection(_ exercise: SchemaV1.Exercise) -> some View {
        Section {
            FlowLayout(spacing: .spacingSm) {
                ForEach(exercise.categories, id: \.id) { category in
                    Text(category.name)
                        .font(.subheadline)
                        .foregroundStyle(Color.accent)
                        .padding(.horizontal, .spacingSm)
                        .padding(.vertical, .spacingXs)
                        .background(Color.accentBg)
                        .clipShape(RoundedRectangle(cornerRadius: .radiusSm))
                }
            }
        } header: {
            Text("Categories")
                .foregroundStyle(Color.textSecondary)
        }
        .listRowBackground(Color.bgCard)
    }

    private func notesSection(_ notes: String) -> some View {
        Section {
            Text(notes)
                .foregroundStyle(Color.textPrimary)
        } header: {
            Text("Notes")
                .foregroundStyle(Color.textSecondary)
        }
        .listRowBackground(Color.bgCard)
    }

    @ViewBuilder
    private func unitSection(_ exercise: SchemaV1.Exercise) -> some View {
        switch exercise.type {
        case .weightAndReps, .bodyweightAndReps, .weightAndTime:
            Section {
                Picker("Weight Unit", selection: Binding(
                    get: { exercise.preferredWeightUnit ?? viewModel.defaultWeightUnit },
                    set: { newUnit in
                        Task {
                            await viewModel.updateWeightUnit(
                                newUnit == viewModel.defaultWeightUnit ? nil : newUnit
                            )
                        }
                    }
                )) {
                    ForEach(Units.allCases, id: \.self) { unit in
                        Text(unit.displayName).tag(unit)
                    }
                }
            } header: {
                Text("Unit")
                    .foregroundStyle(Color.textSecondary)
            } footer: {
                if exercise.preferredWeightUnit == nil {
                    Text("Using global default")
                        .foregroundStyle(Color.textTertiary)
                }
            }
            .listRowBackground(Color.bgCard)
        case .distanceAndTime:
            Section {
                Picker("Distance Unit", selection: Binding(
                    get: { exercise.preferredDistanceUnit ?? viewModel.defaultDistanceUnit },
                    set: { newUnit in
                        Task {
                            await viewModel.updateDistanceUnit(
                                newUnit == viewModel.defaultDistanceUnit ? nil : newUnit
                            )
                        }
                    }
                )) {
                    ForEach(DistanceUnits.allCases, id: \.self) { unit in
                        Text(unit.displayName).tag(unit)
                    }
                }
            } header: {
                Text("Unit")
                    .foregroundStyle(Color.textSecondary)
            } footer: {
                if exercise.preferredDistanceUnit == nil {
                    Text("Using global default")
                        .foregroundStyle(Color.textTertiary)
                }
            }
            .listRowBackground(Color.bgCard)
        case .reps, .time:
            EmptyView()
        }
    }

    private var statsSection: some View {
        Section {
            statRow(
                label: "Last Performed",
                value: viewModel.performanceStats?.lastPerformed?.relativeDescription ?? "Never"
            )
            statRow(
                label: "Personal Record",
                value: viewModel.performanceStats?.personalRecord?.displayValue ?? "—"
            )
            statRow(
                label: "Total Volume",
                value: formatVolume(viewModel.performanceStats?.totalVolume)
            )
        } header: {
            Text("Performance")
                .foregroundStyle(Color.textSecondary)
        }
        .listRowBackground(Color.bgCard)
    }

    private var actionsSection: some View {
        Section {
            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                HStack {
                    Spacer()
                    Text(viewModel.canDelete ? "Delete Exercise" : "Archive Exercise")
                        .foregroundStyle(Color.destructive)
                    Spacer()
                }
            }
        }
        .listRowBackground(Color.bgCard)
    }

    // MARK: - Helpers

    private func statRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(Color.textSecondary)
            Spacer()
            Text(value)
                .foregroundStyle(Color.textPrimary)
        }
    }

    private func formatVolume(_ volume: Double?) -> String {
        guard let volume, volume > 0 else { return "—" }
        if volume >= 1000 {
            return String(format: "%.0f", volume)
        }
        return String(format: "%.1f", volume)
    }
}

// MARK: - Flow Layout

private struct FlowLayout: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth, currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            maxX = max(maxX, currentX - spacing)
        }

        return (CGSize(width: maxX, height: currentY + lineHeight), positions)
    }
}