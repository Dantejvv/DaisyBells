import SwiftUI

/// Per-exercise analytics and stats
struct ExerciseAnalyticsView: View {
    @State private var viewModel: ExerciseAnalyticsViewModel

    init(viewModel: ExerciseAnalyticsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingSpinnerView(message: "Loading analytics...")
            } else if let exercise = viewModel.exercise {
                exerciseContent(exercise)
            }
        }
        .errorAlert(Binding(
            get: { viewModel.errorMessage },
            set: { viewModel.errorMessage = $0 }
        ))
        .task { await viewModel.loadAnalytics() }
    }

    @ViewBuilder
    private func exerciseContent(_ exercise: SchemaV1.Exercise) -> some View {
        List {
            // Summary section
            Section {
                if exercise.totalVolume > 0 {
                    SummaryRow(
                        label: "Total Volume",
                        value: exercise.totalVolume.volumeString(units: .lbs)
                    )
                }

                if let pr = viewModel.personalBest {
                    HStack {
                        Text("Personal Best")
                            .foregroundStyle(.secondary)
                        Spacer()
                        HStack(spacing: 6) {
                            Image(systemName: "trophy.fill")
                                .foregroundStyle(.yellow)
                                .font(.caption)
                            Text(pr.displayValue)
                                .fontWeight(.semibold)
                        }
                    }
                }

                if let lastPerformed = viewModel.lastPerformed {
                    HStack {
                        Text("Last Performed")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(lastPerformed.relativeDescription)
                    }
                }
            }

            // Recent sets
            if !viewModel.recentSets.isEmpty {
                Section("Recent Sets") {
                    ForEach(viewModel.recentSets) { set in
                        RecentSetRow(set: set, exerciseType: exercise.type)
                    }
                }
            }
        }
        .navigationTitle(exercise.name)
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

private struct RecentSetRow: View {
    let set: SchemaV1.LoggedSet
    let exerciseType: ExerciseType

    var body: some View {
        HStack(spacing: 8) {
            if let date = set.completedAt {
                Text(date.shortDateFormat)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 50, alignment: .leading)
            }

            Text(setDescription)
                .font(.subheadline)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(.secondarySystemFill))
                .clipShape(Capsule())

            Spacer()
        }
    }

    private var setDescription: String {
        switch exerciseType {
        case .weightAndReps:
            let w = set.weight.map { "\(Int($0))" } ?? "—"
            let r = set.reps.map { "\($0)" } ?? "—"
            return "\(w)×\(r)"
        case .bodyweightAndReps:
            let r = set.reps.map { "\($0) reps" } ?? "—"
            return r
        case .reps:
            return set.reps.map { "\($0) reps" } ?? "—"
        case .time:
            return set.time.map { $0.setDurationString } ?? "—"
        case .distanceAndTime:
            let d = set.distance.map { String(format: "%.1f mi", $0) } ?? ""
            let t = set.time.map { $0.setDurationString } ?? ""
            return [d, t].filter { !$0.isEmpty }.joined(separator: " ")
        case .weightAndTime:
            let w = set.weight.map { "\(Int($0)) lbs" } ?? ""
            let t = set.time.map { $0.setDurationString } ?? ""
            return [w, t].filter { !$0.isEmpty }.joined(separator: " ")
        }
    }
}
