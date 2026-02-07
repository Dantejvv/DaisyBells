import SwiftUI

/// Analytics dashboard with summary cards and recent PRs
struct AnalyticsDashboardView: View {
    @State private var viewModel: AnalyticsDashboardViewModel

    init(viewModel: AnalyticsDashboardViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingSpinnerView(message: "Loading analytics...")
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        // Hero Card
                        VStack(spacing: 16) {
                            Text("\(viewModel.workoutsThisWeek)")
                                .font(.system(size: 72, weight: .bold, design: .rounded))

                            Text("workouts this week")
                                .font(.title3)
                                .foregroundStyle(.secondary)

                            HStack(spacing: 24) {
                                SupportingStat(value: "\(viewModel.workoutsThisMonth)", label: "this month")

                                Divider()
                                    .frame(height: 32)

                                SupportingStat(value: "\(viewModel.personalRecords.count)", label: "PRs")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                        .padding(.horizontal)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)

                        // Recent PRs
                        if !viewModel.personalRecords.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Recent PRs")
                                        .font(.headline)
                                    Spacer()
                                }
                                .padding(.horizontal)

                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                    ForEach(viewModel.personalRecords) { pr in
                                        PRCard(record: pr)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }

                        // Recent Exercises
                        if !viewModel.recentExercises.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Recent Exercises")
                                        .font(.headline)
                                    Spacer()
                                }
                                .padding(.horizontal)

                                ForEach(viewModel.recentExercises) { exercise in
                                    Button {
                                        viewModel.selectExercise(exercise)
                                    } label: {
                                        RecentExerciseRow(exercise: exercise)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.vertical)
                }
                .background(Color(.systemGroupedBackground))
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Analytics")
                    .font(.title.weight(.semibold))
            }
        }
        .errorAlert(Binding(
            get: { viewModel.errorMessage },
            set: { viewModel.errorMessage = $0 }
        ))
        .task { await viewModel.loadAnalytics() }
    }
}

private struct SupportingStat: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(.title2, design: .rounded))
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

private struct PRCard: View {
    let record: PersonalRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundStyle(.yellow)
                Text("PR")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(record.achievedAt.shortDateFormat)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Text(record.exerciseName)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(1)

            Text(record.displayValue)
                .font(.headline)
                .fontWeight(.bold)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct RecentExerciseRow: View {
    let exercise: SchemaV1.Exercise

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)

                Text(exercise.type.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let lastPerformed = exercise.lastPerformedAt {
                Text(lastPerformed.relativeDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
