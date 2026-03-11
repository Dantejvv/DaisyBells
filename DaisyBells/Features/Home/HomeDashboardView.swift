import SwiftUI
import SwiftData

@MainActor
struct HomeDashboardView: View {
    @State var viewModel: HomeDashboardViewModel
    @Environment(HomeRouter.self) private var router

    @State private var expandedTemplateIds: Set<UUID> = []
    @State private var expandedDayIds: Set<UUID> = []
    @State private var swipedDayId: UUID?

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
        VStack(alignment: .leading, spacing: .spacingMd) {
            // Header
            HStack {
                Text(split.name)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.textPrimary)

                Spacer()

                Text("\(viewModel.completedDayCount)/\(viewModel.splitDays.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.accent)
                    .padding(.horizontal, .spacingSm)
                    .padding(.vertical, .spacing2xs)
                    .background(Color.accentBg)
                    .clipShape(Capsule())

                Button("Manage") {
                    router.navigateToSplitList()
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.accent)
            }

            // Progress bar
            splitProgressBar

            // Day list
            VStack(spacing: .spacingXs) {
                ForEach(Array(viewModel.splitDays.enumerated()), id: \.element.id) { index, day in
                    splitDayRow(day, index: index)
                }
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

    private var splitProgressBar: some View {
        GeometryReader { geo in
            let total = viewModel.splitDays.count
            let progress = total > 0 ? CGFloat(viewModel.completedDayCount) / CGFloat(total) : 0

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.bgInput)
                    .frame(height: 6)

                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.accent)
                    .frame(width: geo.size.width * progress, height: 6)
            }
        }
        .frame(height: 6)
    }

    // MARK: - Split Day Row

    private func splitDayRow(_ day: SchemaV1.SplitDay, index: Int) -> some View {
        let isCurrent = index == viewModel.currentDayIndex
        let isPrevious = index == viewModel.currentDayIndex - 1
        let isNext = index == viewModel.currentDayIndex + 1
        let isExpanded = expandedDayIds.contains(day.id)
        let isSwiped = swipedDayId == day.id

        return ZStack(alignment: .trailing) {
            // Swipe action buttons (behind the row)
            HStack(spacing: 0) {
                Button {
                    withAnimation(.snappy(duration: 0.2)) {
                        Task { await viewModel.setCurrentDay(index: index) }
                        swipedDayId = nil
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.callout)
                        Text("Set Next")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundStyle(.white)
                    .frame(width: 72, height: 56)
                    .background(Color.accent)
                }

                Button {
                    withAnimation(.snappy(duration: 0.2)) {
                        Task { await viewModel.skipDay(at: index) }
                        swipedDayId = nil
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "forward.fill")
                            .font(.callout)
                        Text("Skip")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundStyle(.white)
                    .frame(width: 72, height: 56)
                    .background(Color.textSecondary)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: .radiusMd))

            // Foreground row content
            VStack(alignment: .leading, spacing: 0) {
                // Main row
                HStack(spacing: .spacingSm) {
                    // Completion indicator
                    ZStack {
                        Circle()
                            .fill(day.isCompletedInCycle ? Color.success.opacity(0.15) : Color.bgInput)
                            .frame(width: 28, height: 28)

                        if day.isCompletedInCycle {
                            Image(systemName: "checkmark")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(Color.success)
                        } else if isCurrent {
                            Circle()
                                .fill(Color.accent)
                                .frame(width: 10, height: 10)
                        }
                    }

                    // Day info
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: .spacingXs) {
                            Text(day.name)
                                .font(.subheadline.weight(isCurrent ? .semibold : .regular))
                                .foregroundStyle(isCurrent ? Color.textPrimary : (day.isCompletedInCycle ? Color.textTertiary : Color.textSecondary))

                            if isCurrent {
                                Text("UP NEXT")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(Color.accent)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.accentBg)
                                    .clipShape(Capsule())
                            }
                        }

                        Text("\(day.assignedWorkouts.count) workout\(day.assignedWorkouts.count == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundStyle(Color.textTertiary)
                    }

                    Spacer()

                    // Expand chevron
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color.textTertiary)
                }
                .padding(.vertical, .spacingSm)
                .padding(.horizontal, .spacingSm)

                // Expanded workout list
                if isExpanded {
                    VStack(spacing: .spacingXs) {
                        ForEach(day.assignedWorkouts, id: \.id) { template in
                            HStack {
                                Text(template.name)
                                    .font(.caption)
                                    .foregroundStyle(Color.textSecondary)

                                Spacer()

                                Button {
                                    Task { await viewModel.startWorkoutFromTemplate(template) }
                                } label: {
                                    Text("Start")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(viewModel.hasActiveWorkout ? Color.textTertiary : Color.accent)
                                }
                                .buttonStyle(.plain)
                                .disabled(viewModel.hasActiveWorkout)
                            }
                            .padding(.horizontal, .spacingSm)
                        }
                    }
                    .padding(.bottom, .spacingSm)
                    .padding(.leading, 36)
                }
            }
            .background(
                isCurrent
                    ? Color.accentBg
                    : (isPrevious || isNext ? Color.bgInput.opacity(0.5) : Color.bgCard)
            )
            .clipShape(RoundedRectangle(cornerRadius: .radiusMd))
            .offset(x: isSwiped ? -144 : 0)
            .gesture(
                DragGesture(minimumDistance: 20)
                    .onEnded { value in
                        withAnimation(.snappy(duration: 0.2)) {
                            if value.translation.width < -50 {
                                swipedDayId = day.id
                            } else {
                                swipedDayId = nil
                            }
                        }
                    }
            )
            .onTapGesture {
                if isSwiped {
                    withAnimation(.snappy(duration: 0.2)) {
                        swipedDayId = nil
                    }
                } else {
                    withAnimation(.snappy(duration: 0.2)) {
                        if isExpanded {
                            expandedDayIds.remove(day.id)
                        } else {
                            expandedDayIds.insert(day.id)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Templates Section

    private var templatesSection: some View {
        VStack(alignment: .leading, spacing: .spacingMd) {
            templatesSectionHeader

            if viewModel.templates.isEmpty {
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
                            isPendingDelete: viewModel.templatePendingDelete?.id == template.id,
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
                            onRequestDelete: { viewModel.requestDelete(template) },
                            onCancelDelete: { viewModel.cancelDelete() },
                            onConfirmDelete: { Task { await viewModel.confirmDelete() } },
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
