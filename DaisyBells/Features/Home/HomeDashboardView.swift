import SwiftUI
import SwiftData

@MainActor
struct HomeDashboardView: View {
    @State var viewModel: HomeDashboardViewModel
    @Environment(HomeRouter.self) private var router

    @State private var expandedTemplateIds: Set<UUID> = []
    @State private var selectedDayId: UUID?

    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingSpinnerView()
            } else {
                dashboardContent
            }
        }
        .task { await viewModel.loadDashboard() }
        .onChange(of: router.presentedSheet == nil) { _, isDismissed in
            if isDismissed {
                Task { await viewModel.loadDashboard() }
            }
        }
        .onChange(of: viewModel.hasActiveWorkout) { oldValue, newValue in
            if oldValue && !newValue {
                Task { await viewModel.loadDashboard() }
            }
        }
        .alert(
            "Delete Template",
            isPresented: $viewModel.showDeleteConfirmation
        ) {
            Button("Delete", role: .destructive) {
                Task { await viewModel.confirmDelete() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete \"\(viewModel.templatePendingDelete?.name ?? "this template")\"?")
        }
        .errorAlert(errorMessage: $viewModel.errorMessage)
        .background(Color.bgPrimary)
    }

    // MARK: - Dashboard Content

    private var dashboardContent: some View {
        ScrollView {
            VStack(spacing: .spacingXl) {
                splitSection
                templatesSection
            }
            .padding(.horizontal, .spacingBase)
            .padding(.vertical, .spacingSm)
        }
    }

    // MARK: - Split Section

    private var splitSection: some View {
        Group {
            if let split = viewModel.activeSplit {
                expandedSplitDashboard(split)
            } else {
                collapsedSplitDashboard
            }
        }
    }

    private var collapsedSplitDashboard: some View {
        HStack(spacing: .spacingMd) {
            VStack(alignment: .leading, spacing: .spacingXs) {
                Text("No Active Split")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.textPrimary)
                Text("Set up a training split to track your rotation")
                    .font(.caption)
                    .foregroundStyle(Color.textTertiary)
            }

            Spacer()

            Button("Manage") {
                router.navigateToSplitList()
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(Color.accent)
        }
        .padding(.spacingBase)
        .background(Color.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: .radiusLg))
        .overlay(
            RoundedRectangle(cornerRadius: .radiusLg)
                .stroke(Color.borderSubtle, lineWidth: 1)
        )
    }

    private func expandedSplitDashboard(_ split: SchemaV1.Split) -> some View {
        let completed = viewModel.completedDayCount
        let total = viewModel.splitDays.count
        let progress = total > 0 ? CGFloat(completed) / CGFloat(total) : 0

        return VStack(spacing: .spacingXl) {
            // Mini ring + text header
            HStack(spacing: .spacingMd) {
                ZStack {
                    Circle()
                        .stroke(Color.bgInput, lineWidth: 4)
                        .frame(width: 48, height: 48)

                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(Color.accent, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 48, height: 48)
                        .rotationEffect(.degrees(-90))

                    Text("\(completed)/\(total)")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.textPrimary)
                }

                VStack(alignment: .leading, spacing: .spacing2xs) {
                    Text(split.name)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Color.textPrimary)

                    Text("\(completed) of \(total) days")
                        .font(.caption)
                        .foregroundStyle(Color.textTertiary)
                }

                Spacer()

                Button("Manage") {
                    router.navigateToSplitList()
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.accent)
            }

            // Day chips grid
            splitDayChips

            if viewModel.isCycleComplete {
                // Cycle complete state
                cycleCompleteCard
                    .transition(.opacity.combined(with: .move(edge: .top)))
            } else if let selectedDay = viewModel.splitDays.first(where: { $0.id == selectedDayId }) {
                // Detail panel for selected day
                splitDayDetailPanel(for: selectedDay)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .onAppear {
            if selectedDayId == nil, !viewModel.splitDays.isEmpty {
                if let suggestedIndex = viewModel.suggestedDayIndex {
                    selectedDayId = viewModel.splitDays[suggestedIndex].id
                } else {
                    selectedDayId = viewModel.splitDays.first?.id
                }
            }
        }
        .onChange(of: viewModel.completedDayCount) {
            guard !viewModel.splitDays.isEmpty else { return }
            if let suggestedIndex = viewModel.suggestedDayIndex {
                withAnimation(.snappy(duration: 0.2)) {
                    selectedDayId = viewModel.splitDays[suggestedIndex].id
                }
            }
        }
    }

    // MARK: - Day Chips

    private var splitDayChips: some View {
        let columns = [
            GridItem(.flexible(), spacing: .spacingSm),
            GridItem(.flexible(), spacing: .spacingSm),
            GridItem(.flexible(), spacing: .spacingSm),
        ]

        return LazyVGrid(columns: columns, spacing: .spacingSm) {
            ForEach(Array(viewModel.splitDays.enumerated()), id: \.element.id) { index, day in
                let isSuggested = index == viewModel.suggestedDayIndex
                let isSelected = selectedDayId == day.id

                Button {
                    withAnimation(.snappy(duration: 0.2)) {
                        selectedDayId = isSelected ? nil : day.id
                    }
                } label: {
                    HStack(spacing: .spacingXs) {
                        if day.isCompletedInCycle {
                            Image(systemName: "checkmark")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(Color.success)
                        }

                        Text(day.name)
                            .font(.subheadline.weight(isSuggested ? .semibold : .regular))
                            .lineLimit(1)
                    }
                    .foregroundStyle(
                        day.isCompletedInCycle ? Color.success :
                        (isSuggested ? Color.white : Color.textPrimary)
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, .spacingSm)
                    .padding(.horizontal, .spacingSm)
                    .background(
                        day.isCompletedInCycle ? Color.successBg :
                        (isSuggested ? Color.accent : Color.bgCard)
                    )
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(
                                isSelected ? Color.accent : Color.borderSubtle,
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Cycle Complete

    private var cycleCompleteCard: some View {
        VStack(spacing: .spacingMd) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 36))
                .foregroundStyle(Color.success)

            Text("Cycle Complete!")
                .font(.headline)
                .foregroundStyle(Color.textPrimary)

            Text("You've completed all days in this split.")
                .font(.subheadline)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)

            Button {
                Task { await viewModel.resetCycle() }
            } label: {
                Text("Start New Cycle")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, .spacingSm)
                    .background(Color.accent)
                    .clipShape(RoundedRectangle(cornerRadius: .radiusMd))
            }
            .buttonStyle(.plain)
        }
        .padding(.spacingBase)
        .background(Color.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: .radiusLg))
        .overlay(
            RoundedRectangle(cornerRadius: .radiusLg)
                .stroke(Color.borderSubtle, lineWidth: 1)
        )
    }

    // MARK: - Detail Panel

    private func splitDayDetailPanel(for day: SchemaV1.SplitDay) -> some View {
        let index = viewModel.splitDays.firstIndex(where: { $0.id == day.id }) ?? 0
        let isSuggested = index == viewModel.suggestedDayIndex

        return VStack(alignment: .leading, spacing: .spacingSm) {
            HStack {
                Text(day.name)
                    .font(.headline)
                    .foregroundStyle(Color.textPrimary)

                if isSuggested {
                    Text("UP NEXT")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Color.accent)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.accentBg)
                        .clipShape(Capsule())
                }

                Spacer()

                if day.isCompletedInCycle {
                    Label("Complete", systemImage: "checkmark.circle.fill")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color.success)
                }
            }

            ForEach(day.assignedWorkouts, id: \.id) { template in
                HStack {
                    Text(template.name)
                        .font(.subheadline)
                        .foregroundStyle(Color.textSecondary)

                    Spacer()

                    if !day.isCompletedInCycle {
                        Button {
                            Task { await viewModel.startSplitDayWorkout(template, dayIndex: index) }
                        } label: {
                            Text("Start")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(viewModel.hasActiveWorkout ? Color.textTertiary : Color.accent)
                        }
                        .buttonStyle(.plain)
                        .disabled(viewModel.hasActiveWorkout)
                    }
                }
            }

            Divider()

            if day.isCompletedInCycle {
                HStack {
                    Button {
                        Task { await viewModel.uncompleteDay(at: index) }
                    } label: {
                        Label("Mark Incomplete", systemImage: "arrow.uturn.backward")
                    }
                    .foregroundStyle(Color.textSecondary)

                    Spacer()
                }
                .font(.subheadline.weight(.medium))
                .buttonStyle(.plain)
            } else {
                HStack {
                    Spacer()

                    Button {
                        Task { await viewModel.skipDay(at: index) }
                    } label: {
                        Label("Skip", systemImage: "forward.fill")
                    }
                    .foregroundStyle(Color.textSecondary)
                }
                .font(.subheadline.weight(.medium))
                .buttonStyle(.plain)
            }
        }
        .padding(.spacingBase)
        .background(Color.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: .radiusLg))
        .overlay(
            RoundedRectangle(cornerRadius: .radiusLg)
                .stroke(Color.borderSubtle, lineWidth: 1)
        )
    }

    // MARK: - Templates Section

    private var templatesSection: some View {
        VStack(alignment: .leading, spacing: .spacingMd) {
            templatesSectionHeader

            if viewModel.templates.isEmpty {
                NewWorkoutCard(
                    isDisabled: viewModel.hasActiveWorkout,
                    onStart: { Task { await viewModel.startEmptyWorkout() } }
                )

                EmptyStateView(
                    icon: "doc.text",
                    title: "No Templates Yet",
                    message: "Create a workout template to get started."
                ) {
                    Button("New Template") {
                        viewModel.presentNewTemplate()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.accent)
                }
            } else {
                VStack(spacing: .spacingSm) {
                    NewWorkoutCard(
                        isDisabled: viewModel.hasActiveWorkout,
                        onStart: { Task { await viewModel.startEmptyWorkout() } }
                    )

                    ForEach(viewModel.templates, id: \.id) { template in
                        let exercises = template.templateExercises
                            .sorted { $0.order < $1.order }
                            .map { TemplateCard.ExerciseInfo(from: $0) }

                        TemplateCard(
                            name: template.name,
                            exercises: exercises,
                            isExpanded: expandedTemplateIds.contains(template.id),
                            startDisabled: viewModel.hasActiveWorkout,
                            onToggleExpand: {
                                withAnimation(.snappy(duration: 0.2)) {
                                    if expandedTemplateIds.contains(template.id) {
                                        expandedTemplateIds.remove(template.id)
                                    } else {
                                        expandedTemplateIds.insert(template.id)
                                    }
                                }
                            },
                            onStart: {
                                Task { await viewModel.startWorkoutFromTemplate(template) }
                            },
                            onEdit: { viewModel.editTemplate(template) },
                            onDelete: { viewModel.requestDelete(template) },
                            onViewDetail: { router.navigateToTemplateDetail(templateId: template.persistentModelID) },
                            style: .card
                        )
                    }
                }
            }
        }
    }

    private var templatesSectionHeader: some View {
        HStack {
            Text("All Templates")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.textPrimary)

            Text("\(viewModel.templates.count)")
                .font(.caption.weight(.medium))
                .foregroundStyle(Color.accent)
                .padding(.horizontal, .spacingSm)
                .padding(.vertical, .spacing2xs)
                .background(Color.accentBg)
                .clipShape(Capsule())

            Spacer()

            Button {
                viewModel.presentNewTemplate()
            } label: {
                HStack(spacing: .spacingXs) {
                    Image(systemName: "plus")
                        .font(.caption.weight(.semibold))
                    Text("New")
                        .font(.subheadline.weight(.medium))
                }
                .foregroundStyle(Color.accent)
            }
        }
    }
}
