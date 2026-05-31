import SwiftUI
import SwiftData

@MainActor
struct TemplateDetailView: View {
    @State var viewModel: TemplateDetailViewModel
    @State private var showDeleteConfirmation = false
    var onSheetDismissed: Bool = false

    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingSpinnerView()
            } else if let template = viewModel.template {
                templateContent(template)
            } else {
                Color.clear
            }
        }
        .navigationTitle(viewModel.template?.name ?? "Template")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    viewModel.editTemplate()
                } label: {
                    Text("Edit")
                }
            }
        }
        .task { await viewModel.loadTemplate() }
        .onChange(of: onSheetDismissed) {
            Task { await viewModel.loadTemplate() }
        }
        .errorAlert(errorMessage: $viewModel.errorMessage)
        .destructiveConfirmation(
            title: "Delete Template",
            message: "This template will be permanently deleted.",
            isPresented: $showDeleteConfirmation,
            onConfirm: {
                Task { await viewModel.deleteTemplate() }
            }
        )
        .background(Color.bgPrimary)
    }

    // MARK: - Content

    private func templateContent(_ template: SchemaV1.WorkoutTemplate) -> some View {
        ScrollView {
            VStack(spacing: 14) {
                statusCard(template)

                if viewModel.exercises.isEmpty {
                    EmptyStateView(
                        icon: "list.bullet",
                        title: "No Exercises",
                        message: "This template has no exercises."
                    )
                    .padding(.vertical, .spacing2xl)
                } else {
                    ForEach(viewModel.exercises, id: \.id) { templateExercise in
                        exerciseCard(templateExercise)
                    }
                }

                actionsCard
            }
            .padding(.horizontal, .spacingBase)
            .padding(.bottom, .spacing4xl)
        }
    }

    // MARK: - Status Card

    private func statusCard(_ template: SchemaV1.WorkoutTemplate) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Stats row
            HStack(spacing: .spacingXl) {
                statusStatItem(label: "Exercises", value: "\(viewModel.exercises.count)")
                statusStatItem(label: "Sets", value: "\(totalSetCount)")
            }
            .frame(maxWidth: .infinity)

            // Notes
            if let notes = template.notes, !notes.isEmpty {
                Divider()
                    .background(Color.borderSubtle)
                    .padding(.top, 10)

                Text(notes)
                    .font(.footnote)
                    .foregroundStyle(Color.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, .spacingSm)
            }
        }
        .padding(14)
        .padding(.horizontal, 2)
        .cardSurface()
    }

    private func statusStatItem(label: String, value: String) -> some View {
        VStack(spacing: .spacing2xs) {
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.textPrimary)
            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundStyle(Color.textTertiary)
        }
    }

    private var totalSetCount: Int {
        viewModel.exercises.reduce(0) { total, templateExercise in
            let templateSets = templateExercise.sets.count
            let previousSets = templateExercise.exercise.flatMap { viewModel.previousPerformance[$0.id] }?.count ?? 0
            return total + (templateSets > 0 ? templateSets : max(previousSets, 1))
        }
    }

    // MARK: - Exercise Card

    private func exerciseCard(_ templateExercise: SchemaV1.TemplateExercise) -> some View {
        let exercise = templateExercise.exercise
        let exerciseType = exercise?.type ?? .weightAndReps
        let templateSets = templateExercise.sets.sorted { $0.order < $1.order }
        let previousSets = exercise.flatMap { viewModel.previousPerformance[$0.id] } ?? []
        let setCount = templateSets.isEmpty ? max(previousSets.count, 1) : templateSets.count
        let weightUnit = exercise?.resolvedWeightUnit(default: viewModel.defaultWeightUnit) ?? viewModel.defaultWeightUnit
        let distanceUnit = exercise?.resolvedDistanceUnit(default: viewModel.defaultDistanceUnit) ?? viewModel.defaultDistanceUnit

        return ExerciseCardContainer {
            ExerciseCardHeader(name: exercise?.name ?? "Unknown Exercise") {
                Text(exerciseType.displayName)
                    .font(.caption2)
                    .foregroundStyle(Color.textTertiary)
            }

            if let notes = exercise?.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption2)
                    .foregroundStyle(Color.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, .spacingSm)
                    .padding(.vertical, .spacingSm)
                    .background(Color.white.opacity(0.02))
                    .clipShape(RoundedRectangle(cornerRadius: .radiusSm))
                    .overlay(
                        RoundedRectangle(cornerRadius: .radiusSm)
                            .stroke(Color.borderSubtle, lineWidth: 1)
                    )
                    .padding(.horizontal, 14)
                    .padding(.bottom, .spacingXs)
            }

            SetColumnHeaders(exerciseType: exerciseType, weightUnit: weightUnit, distanceUnit: distanceUnit)

            Rectangle()
                .fill(Color.borderSubtle)
                .frame(height: 1)

            ForEach(0..<setCount, id: \.self) { index in
                let templateSet = index < templateSets.count ? templateSets[index] : nil
                let previousSet = index < previousSets.count ? previousSets[index] : nil

                // Template set values are in current unit; previous set values need conversion
                let prevWeight = convertWeight(previousSet?.weight, storedUnit: previousSet?.resolvedWeightUnit, displayUnit: weightUnit)
                let prevBWMod = convertWeight(previousSet?.bodyweightModifier, storedUnit: previousSet?.resolvedWeightUnit, displayUnit: weightUnit)
                let prevDistance = convertDistance(previousSet?.distance, storedUnit: previousSet?.resolvedDistanceUnit, displayUnit: distanceUnit)

                ReadOnlySetRow(
                    exerciseType: exerciseType,
                    setNumber: index + 1,
                    badgeStyle: .neutral,
                    weightUnit: weightUnit,
                    distanceUnit: distanceUnit,
                    weight: templateSet?.weight ?? prevWeight,
                    reps: templateSet?.reps ?? previousSet?.reps,
                    bodyweightModifier: templateSet?.bodyweightModifier ?? prevBWMod,
                    time: templateSet?.time ?? previousSet?.time,
                    distance: templateSet?.distance ?? prevDistance,
                    notes: templateSet != nil ? nil : previousSet?.notes
                )
            }

            Spacer()
                .frame(height: .spacingSm)
        }
    }

    // MARK: - Actions

    private var actionsCard: some View {
        VStack(spacing: 0) {
            actionButton(title: "Duplicate Template", color: .accent) {
                Task { await viewModel.duplicateTemplate() }
            }

            Rectangle()
                .fill(Color.borderSubtle)
                .frame(height: 1)

            actionButton(title: "Delete Template", color: .destructive) {
                showDeleteConfirmation = true
            }
        }
        .cardSurface()
    }

    private func actionButton(title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(color)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
    }

    // MARK: - Unit Conversion Helpers

    private func convertWeight(_ value: Double?, storedUnit: Units?, displayUnit: Units) -> Double? {
        guard let value else { return nil }
        let from = storedUnit ?? displayUnit
        return value.convert(from: from, to: displayUnit)
    }

    private func convertDistance(_ value: Double?, storedUnit: DistanceUnits?, displayUnit: DistanceUnits) -> Double? {
        guard let value else { return nil }
        let from = storedUnit ?? displayUnit
        return value.convertDistance(from: from, to: displayUnit)
    }
}
