import SwiftUI

/// Analytics dashboard with summary cards, recent exercises, and PRs
struct AnalyticsDashboardView: View {
    @State private var isLoading = false

    // Mock data
    private let workoutsThisWeek = 3
    private let workoutsThisMonth = 12
    private let totalWorkouts = 47
    private let recentExercises = MockAnalyticsData.recentExercises
    private let personalRecords = MockAnalyticsData.personalRecords

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Summary cards
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    SummaryCard(
                        title: "This Week",
                        value: "\(workoutsThisWeek)",
                        subtitle: "workouts",
                        systemImage: "calendar",
                        color: .blue
                    )

                    SummaryCard(
                        title: "This Month",
                        value: "\(workoutsThisMonth)",
                        subtitle: "workouts",
                        systemImage: "calendar.badge.clock",
                        color: .green
                    )

                    SummaryCard(
                        title: "Total",
                        value: "\(totalWorkouts)",
                        subtitle: "workouts",
                        systemImage: "flame",
                        color: .orange
                    )

                    SummaryCard(
                        title: "PRs Set",
                        value: "\(personalRecords.count)",
                        subtitle: "all time",
                        systemImage: "trophy",
                        color: .yellow
                    )
                }
                .padding(.horizontal)

                // Recent PRs
                if !personalRecords.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Recent PRs")
                                .font(.headline)
                            Spacer()
                        }
                        .padding(.horizontal)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(personalRecords) { pr in
                                    PRCard(record: pr)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }

                // Recent exercises
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Recent Exercises")
                            .font(.headline)
                        Spacer()
                    }
                    .padding(.horizontal)

                    VStack(spacing: 0) {
                        ForEach(recentExercises) { exercise in
                            NavigationLink {
                                ExerciseAnalyticsDetailView(exercise: exercise)
                            } label: {
                                RecentExerciseRow(exercise: exercise)
                            }
                            .buttonStyle(.plain)

                            if exercise.id != recentExercises.last?.id {
                                Divider()
                                    .padding(.leading)
                            }
                        }
                    }
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Analytics")
    }
}

private struct SummaryCard: View {
    let title: String
    let value: String
    let subtitle: String
    let systemImage: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: systemImage)
                    .foregroundStyle(color)
                Spacer()
            }

            Text(value)
                .font(.system(.title, design: .rounded))
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: 2) {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct PRCard: View {
    let record: MockPersonalRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundStyle(.yellow)
                Text("PR")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
            }

            Text(record.exerciseName)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(1)

            Text(record.value)
                .font(.headline)
                .fontWeight(.bold)

            Text(formattedDate)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(width: 140)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: record.date)
    }
}

private struct RecentExerciseRow: View {
    let exercise: MockRecentExercise

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.body)
                    .foregroundStyle(.primary)

                Text("Last: \(formattedDate)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(exercise.lastPerformance)
                    .font(.subheadline)
                    .foregroundStyle(.primary)

                Text("\(exercise.timesPerformed)x performed")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        let calendar = Calendar.current

        if calendar.isDateInToday(exercise.lastPerformed) {
            return "Today"
        } else if calendar.isDateInYesterday(exercise.lastPerformed) {
            return "Yesterday"
        } else {
            formatter.dateFormat = "MMM d"
            return formatter.string(from: exercise.lastPerformed)
        }
    }
}

#Preview {
    NavigationStack {
        AnalyticsDashboardView()
    }
}
