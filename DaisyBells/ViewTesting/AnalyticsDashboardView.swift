import SwiftUI

/// Analytics dashboard with summary cards, recent exercises, and PRs
struct AnalyticsDashboardView: View {
    @State private var isLoading = false

    // Mock data
    private let workoutsThisWeek = 3
    private let workoutsThisMonth = 12
    private let totalWorkouts = 47
    private let personalRecords = MockAnalyticsData.personalRecords

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Hero Card
                VStack(spacing: 16) {
                    Text("\(workoutsThisWeek)")
                        .font(.system(size: 72, weight: .bold, design: .rounded))

                    Text("workouts this week")
                        .font(.title3)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 24) {
                        SupportingStat(value: "\(workoutsThisMonth)", label: "this month")

                        Divider()
                            .frame(height: 32)

                        SupportingStat(value: "\(totalWorkouts)", label: "total")

                        Divider()
                            .frame(height: 32)

                        SupportingStat(value: "\(personalRecords.count)", label: "PRs")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .padding(.horizontal)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
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

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(personalRecords) { pr in
                                PRCard(record: pr)
                            }
                        }
                        .padding(.horizontal)
                    }
                }

            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Analytics")
                    .font(.title.weight(.semibold))
            }
        }
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
                Spacer()
                Text(formattedDate)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Text(record.exerciseName)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(1)

            Text(record.value)
                .font(.headline)
                .fontWeight(.bold)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: record.date)
    }
}


#Preview {
    NavigationStack {
        AnalyticsDashboardView()
    }
}
