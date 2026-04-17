import SwiftUI
import SwiftData

@MainActor
struct AnalyticsDashboardView: View {
    @State var viewModel: AnalyticsDashboardViewModel

    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingSpinnerView()
            } else if hasNoData {
                EmptyStateView(
                    icon: "chart.bar",
                    title: "No Analytics Yet",
                    message: "Complete a workout to see your stats here."
                )
            } else {
                dashboardContent
            }
        }
        .navigationTitle("Analytics")
        .navigationBarTitleDisplayMode(.large)
        .task { await viewModel.loadAnalytics() }
        .refreshable { await viewModel.refresh() }
        .errorAlert(errorMessage: $viewModel.errorMessage)
        .background(Color.bgPrimary)
    }

    private var hasNoData: Bool {
        viewModel.workoutsThisWeek == 0
            && viewModel.workoutsThisMonth == 0
            && viewModel.personalRecords.isEmpty
            && viewModel.recentExercises.isEmpty
    }

    // MARK: - Content

    private var dashboardContent: some View {
        ScrollView {
            VStack(spacing: .spacingXl) {
                summarySection
                if !viewModel.personalRecords.isEmpty {
                    prSection
                }
                if !viewModel.recentExercises.isEmpty {
                    recentExercisesSection
                }
            }
            .padding(.horizontal, .spacingBase)
            .padding(.vertical, .spacingSm)
        }
    }

    // MARK: - Summary

    private var summarySection: some View {
        HStack(spacing: .spacingSm) {
            metricCard(value: viewModel.workoutsThisWeek, label: "This Week")
            metricCard(value: viewModel.workoutsThisMonth, label: "This Month")
        }
    }

    private func metricCard(value: Int, label: String) -> some View {
        VStack(spacing: .spacingXs) {
            Text("\(value)")
                .font(.title.weight(.bold))
                .foregroundStyle(Color.accent)
            Text(label)
                .font(.caption)
                .foregroundStyle(Color.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.spacingBase)
        .background(Color.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: .radiusLg))
        .overlay(
            RoundedRectangle(cornerRadius: .radiusLg)
                .stroke(Color.borderSubtle, lineWidth: 1)
        )
    }

    // MARK: - Personal Records

    private var prSection: some View {
        VStack(alignment: .leading, spacing: .spacingMd) {
            Text("Recent PRs")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.textPrimary)

            VStack(spacing: 0) {
                ForEach(viewModel.personalRecords) { record in
                    prRow(record)
                    if record.id != viewModel.personalRecords.last?.id {
                        Divider()
                            .background(Color.borderSubtle)
                    }
                }
            }
            .padding(.spacingMd)
            .background(Color.bgCard)
            .clipShape(RoundedRectangle(cornerRadius: .radiusLg))
            .overlay(
                RoundedRectangle(cornerRadius: .radiusLg)
                    .stroke(Color.borderSubtle, lineWidth: 1)
            )
        }
    }

    private func prRow(_ record: PersonalRecord) -> some View {
        HStack {
            Text(record.exerciseName)
                .font(.subheadline)
                .foregroundStyle(Color.textPrimary)
                .lineLimit(1)

            Spacer()

            Text(record.displayValue(displayWeightUnit: viewModel.units, displayDistanceUnit: viewModel.distanceUnits))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.accent)

            Text(record.achievedAt.relativeDescription)
                .font(.caption)
                .foregroundStyle(Color.textTertiary)
        }
        .padding(.vertical, .spacingXs)
    }

    // MARK: - Recently Trained

    private var recentExercisesSection: some View {
        VStack(alignment: .leading, spacing: .spacingMd) {
            Text("Recently Trained")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.textPrimary)

            VStack(spacing: 0) {
                ForEach(viewModel.recentExercises, id: \.id) { exercise in
                    Button {
                        viewModel.selectExercise(exercise)
                    } label: {
                        recentExerciseRow(exercise)
                    }
                    .buttonStyle(.plain)

                    if exercise.id != viewModel.recentExercises.last?.id {
                        Divider()
                            .background(Color.borderSubtle)
                    }
                }
            }
            .padding(.spacingMd)
            .background(Color.bgCard)
            .clipShape(RoundedRectangle(cornerRadius: .radiusLg))
            .overlay(
                RoundedRectangle(cornerRadius: .radiusLg)
                    .stroke(Color.borderSubtle, lineWidth: 1)
            )
        }
    }

    private func recentExerciseRow(_ exercise: SchemaV1.Exercise) -> some View {
        HStack {
            Text(exercise.name)
                .font(.subheadline)
                .foregroundStyle(Color.textPrimary)
                .lineLimit(1)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.textTertiary)
        }
        .padding(.vertical, .spacingXs)
    }
}
