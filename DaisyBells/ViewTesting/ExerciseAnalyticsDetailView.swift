import SwiftUI

/// Per-exercise analytics and stats
struct ExerciseAnalyticsDetailView: View {
    let exercise: MockRecentExercise

    var body: some View {
        List {
            // Summary section
            Section {
                SummaryRow(label: "Times Performed", value: "\(exercise.timesPerformed)")

                if let volume = exercise.totalVolume {
                    SummaryRow(label: "Total Volume", value: formatVolume(volume))
                }

                if let pr = exercise.personalBest {
                    HStack {
                        Text("Personal Best")
                            .foregroundStyle(.secondary)
                        Spacer()
                        HStack(spacing: 6) {
                            Image(systemName: "trophy.fill")
                                .foregroundStyle(.yellow)
                                .font(.caption)
                            Text(pr)
                                .fontWeight(.semibold)
                        }
                    }
                }

                HStack {
                    Text("Last Performed")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(formattedLastPerformed)
                }
            }

            // Recent performance chart placeholder
            Section("Recent Performance") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Last 10 Sessions")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    // Simple bar chart placeholder
                    HStack(alignment: .bottom, spacing: 6) {
                        ForEach(mockRecentData.indices, id: \.self) { index in
                            VStack(spacing: 4) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(index == mockRecentData.count - 1 ? Color.accentColor : Color.accentColor.opacity(0.5))
                                    .frame(width: 24, height: CGFloat(mockRecentData[index]) * 2)

                                Text("\(index + 1)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .frame(height: 120, alignment: .bottom)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)

                    Text("Session number")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(.vertical, 8)
            }

            // Recent sets
            Section("Recent Sets") {
                ForEach(mockRecentSets) { session in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(session.date)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Spacer()
                            Text("\(session.sets.count) sets")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        HStack(spacing: 8) {
                            ForEach(session.sets, id: \.self) { set in
                                Text(set)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color(.secondarySystemFill))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            // Progression tips
            Section("Tips") {
                VStack(alignment: .leading, spacing: 8) {
                    Label {
                        Text("You've improved 15% over the last month")
                    } icon: {
                        Image(systemName: "arrow.up.right")
                            .foregroundStyle(.green)
                    }
                    .font(.subheadline)

                    Label {
                        Text("Try increasing weight by 5 lbs next session")
                    } icon: {
                        Image(systemName: "lightbulb")
                            .foregroundStyle(.yellow)
                    }
                    .font(.subheadline)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle(exercise.name)
    }

    private var formattedLastPerformed: String {
        let formatter = DateFormatter()
        let calendar = Calendar.current

        if calendar.isDateInToday(exercise.lastPerformed) {
            return "Today"
        } else if calendar.isDateInYesterday(exercise.lastPerformed) {
            return "Yesterday"
        } else if let daysAgo = calendar.dateComponents([.day], from: exercise.lastPerformed, to: Date()).day {
            return "\(daysAgo) days ago"
        }
        formatter.dateFormat = "MMM d"
        return formatter.string(from: exercise.lastPerformed)
    }

    private func formatVolume(_ volume: Double) -> String {
        if volume >= 1000 {
            return String(format: "%.1fK lbs", volume / 1000)
        }
        return "\(Int(volume)) lbs"
    }

    // Mock chart data (representing performance values)
    private var mockRecentData: [Int] {
        [45, 50, 48, 52, 55, 53, 58, 56, 60, 62]
    }

    // Mock recent sessions
    private var mockRecentSets: [MockSessionSummary] {
        [
            MockSessionSummary(date: "Today", sets: ["185×8", "185×8", "185×7", "185×6"]),
            MockSessionSummary(date: "3 days ago", sets: ["180×8", "180×8", "180×8"]),
            MockSessionSummary(date: "1 week ago", sets: ["175×10", "175×9", "175×8"]),
        ]
    }
}

private struct SummaryRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
        }
    }
}

private struct MockSessionSummary: Identifiable {
    let id = UUID()
    let date: String
    let sets: [String]
}

#Preview("Weight Exercise") {
    NavigationStack {
        ExerciseAnalyticsDetailView(
            exercise: MockRecentExercise(
                name: "Bench Press",
                type: .weightAndReps,
                lastPerformed: Date(),
                lastPerformance: "185 × 8",
                timesPerformed: 24,
                totalVolume: 45000,
                personalBest: "225 × 5"
            )
        )
    }
}

#Preview("Bodyweight Exercise") {
    NavigationStack {
        ExerciseAnalyticsDetailView(
            exercise: MockRecentExercise(
                name: "Pull-ups",
                type: .bodyweightAndReps,
                lastPerformed: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
                lastPerformance: "12 reps",
                timesPerformed: 30,
                personalBest: "15 reps"
            )
        )
    }
}
