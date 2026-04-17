import SwiftUI
import SwiftData

@MainActor
struct ExerciseAnalyticsView: View {
    @State var viewModel: ExerciseAnalyticsViewModel

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
        .task { await viewModel.loadAnalytics() }
        .refreshable { await viewModel.refresh() }
        .errorAlert(errorMessage: $viewModel.errorMessage)
        .background(Color.bgPrimary)
    }

    // MARK: - Content

    private func exerciseContent(_ exercise: SchemaV1.Exercise) -> some View {
        List {
            performanceSection(exercise)
            if !viewModel.recentSets.isEmpty {
                recentSetsSection(exercise)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.bgPrimary)
    }

    // MARK: - Performance

    private func performanceSection(_ exercise: SchemaV1.Exercise) -> some View {
        Section {
            statRow(
                label: "Total Volume",
                value: formatVolume(viewModel.totalVolume, exercise: exercise)
            )
            statRow(
                label: "Personal Best",
                value: viewModel.personalBest?.displayValue(displayWeightUnit: viewModel.units, displayDistanceUnit: viewModel.distanceUnits) ?? "—"
            )
            statRow(
                label: "Last Performed",
                value: viewModel.lastPerformed?.relativeDescription ?? "Never"
            )
        } header: {
            Text("Performance")
                .foregroundStyle(Color.textSecondary)
        }
        .listRowBackground(Color.bgCard)
    }

    // MARK: - Recent Sets

    private func recentSetsSection(_ exercise: SchemaV1.Exercise) -> some View {
        Section {
            ForEach(viewModel.recentSets, id: \.id) { set in
                HStack {
                    Text(formatSet(set, exercise: exercise))
                        .font(.subheadline)
                        .foregroundStyle(Color.textPrimary)
                    Spacer()
                    if let date = set.completedAt {
                        Text(date.relativeDescription)
                            .font(.caption)
                            .foregroundStyle(Color.textTertiary)
                    }
                }
            }
        } header: {
            Text("Recent Sets")
                .foregroundStyle(Color.textSecondary)
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

    private func formatVolume(_ volume: Double, exercise: SchemaV1.Exercise) -> String {
        guard volume > 0 else { return "—" }
        let displayUnit = exercise.resolvedWeightUnit(default: viewModel.units)
        let storedUnit = exercise.resolvedTotalVolumeUnit ?? displayUnit
        let converted = volume.convert(from: storedUnit, to: displayUnit)
        return converted.volumeString(units: displayUnit)
    }

    private func formatSet(_ set: SchemaV1.LoggedSet, exercise: SchemaV1.Exercise) -> String {
        let weightDisplayUnit = exercise.resolvedWeightUnit(default: viewModel.units)
        let distanceDisplayUnit = exercise.resolvedDistanceUnit(default: viewModel.distanceUnits)
        let storedWeightUnit = set.resolvedWeightUnit ?? weightDisplayUnit
        let storedDistanceUnit = set.resolvedDistanceUnit ?? distanceDisplayUnit

        switch exercise.type {
        case .weightAndReps:
            let weightStr = set.weight.map { $0.convert(from: storedWeightUnit, to: weightDisplayUnit).weightString(units: weightDisplayUnit) } ?? "—"
            let repsStr = set.reps.map { "\($0) reps" } ?? "—"
            return "\(weightStr) × \(repsStr)"

        case .bodyweightAndReps:
            var parts: [String] = []
            if let reps = set.reps {
                parts.append("\(reps) reps")
            }
            if let modifier = set.bodyweightModifier, modifier != 0 {
                let converted = modifier.convert(from: storedWeightUnit, to: weightDisplayUnit)
                parts.append(converted.bodyweightModifierString(units: weightDisplayUnit))
            }
            return parts.isEmpty ? "—" : parts.joined(separator: " ")

        case .reps:
            return set.reps.map { "\($0) reps" } ?? "—"

        case .time:
            return set.time?.setDurationString ?? "—"

        case .distanceAndTime:
            var parts: [String] = []
            if let distance = set.distance {
                let converted = distance.convertDistance(from: storedDistanceUnit, to: distanceDisplayUnit)
                parts.append(converted.distanceString(units: distanceDisplayUnit))
            }
            if let time = set.time {
                parts.append(time.setDurationString)
            }
            return parts.isEmpty ? "—" : parts.joined(separator: " in ")

        case .weightAndTime:
            var parts: [String] = []
            if let weight = set.weight {
                let converted = weight.convert(from: storedWeightUnit, to: weightDisplayUnit)
                parts.append(converted.weightString(units: weightDisplayUnit))
            }
            if let time = set.time {
                parts.append(time.setDurationString)
            }
            return parts.isEmpty ? "—" : parts.joined(separator: " for ")
        }
    }
}
