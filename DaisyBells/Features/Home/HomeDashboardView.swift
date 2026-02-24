import SwiftUI
import SwiftData

@MainActor
struct HomeDashboardView: View {
    @State var viewModel: HomeDashboardViewModel
    @Environment(HomeRouter.self) private var router

    @State private var expandedTemplateIds: Set<UUID> = []

    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingSpinnerView()
            } else {
                dashboardContent
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if viewModel.hasActiveWorkout {
                    Button {
                        viewModel.resumeActiveWorkout()
                    } label: {
                        HStack(spacing: .spacingXs) {
                            Image(systemName: "figure.run")
                            Text("Resume")
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.success)
                    }
                } else {
                    Button {
                        Task { await viewModel.startEmptyWorkout() }
                    } label: {
                        HStack(spacing: .spacingXs) {
                            Image(systemName: "figure.run")
                            Text("Start")
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.accent)
                    }
                }
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
        .preferredColorScheme(.dark)
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
        VStack(alignment: .leading, spacing: .spacingMd) {
            if let split = viewModel.activeSplit {
                sectionHeader(title: split.name, actionTitle: "Manage") {
                    router.navigateToSplitList()
                }
                splitContent(split)
            } else {
                emptySplitCard
            }
        }
    }

    private func splitContent(_ split: SchemaV1.Split) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: .spacingSm) {
                ForEach(viewModel.splitDays, id: \.id) { day in
                    splitDayCard(day)
                }
            }
        }
    }

    private func splitDayCard(_ day: SchemaV1.SplitDay) -> some View {
        VStack(alignment: .leading, spacing: .spacingSm) {
            Text(day.name)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.textPrimary)

            if day.assignedWorkouts.isEmpty {
                Text("No workouts")
                    .font(.caption)
                    .foregroundStyle(Color.textTertiary)
            } else {
                VStack(alignment: .leading, spacing: .spacingXs) {
                    ForEach(day.assignedWorkouts, id: \.id) { template in
                        HStack(spacing: .spacingSm) {
                            Text(template.name)
                                .font(.caption)
                                .foregroundStyle(Color.textSecondary)
                                .lineLimit(1)

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
                    }
                }
            }
        }
        .padding(.spacingMd)
        .frame(width: 180, alignment: .leading)
        .background(Color.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: .radiusLg))
        .overlay(
            RoundedRectangle(cornerRadius: .radiusLg)
                .stroke(Color.borderSubtle, lineWidth: 1)
        )
    }

    private var emptySplitCard: some View {
        HStack {
            Text("No Split")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.textTertiary)

            Spacer()

            Button {
                router.navigateToSplitList()
            } label: {
                Text("Manage")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.accent)
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

    // MARK: - Helpers

    private func sectionHeader(title: String, actionTitle: String, action: @escaping () -> Void) -> some View {
        HStack {
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.textPrimary)
            Spacer()
            Button {
                action()
            } label: {
                Text(actionTitle)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.accent)
            }
        }
    }
}
