import SwiftUI
import SwiftData

@MainActor
struct TemplateFormView: View {
    @State var viewModel: TemplateFormViewModel
    @Environment(DependencyContainer.self) private var container

    var body: some View {
        Group {
            if viewModel.exercises.isEmpty && !viewModel.isEditing {
                emptyState
            } else {
                formContent
            }
        }
        .navigationTitle(viewModel.isEditing ? "Edit Template" : "New Template")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    viewModel.cancel()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    Task { await viewModel.save() }
                }
                .disabled(viewModel.isSaving || viewModel.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .task { await viewModel.load() }
        .errorAlert(errorMessage: $viewModel.errorMessage)
        .sheet(isPresented: $viewModel.showExercisePicker) {
            NavigationStack {
                ExercisePickerSheet(
                    viewModel: ExercisePickerViewModel(
                        exerciseService: container.exerciseService,
                        categoryService: container.categoryService,
                        onSelect: { exerciseIds in
                            Task { await viewModel.onExercisesSelected(exerciseIds) }
                        }
                    )
                )
            }
        }
        .background(Color.bgPrimary)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 0) {
            headerCard
                .padding(.horizontal, .spacingBase)
                .padding(.top, .spacingSm)

            Spacer()

            EmptyStateView(
                icon: "list.bullet.rectangle",
                title: "No Exercises",
                message: "Add exercises to build your template."
            ) {
                Button("Add Exercise") {
                    viewModel.addExercise()
                }
                .buttonStyle(.borderedProminent)
                .tint(.accent)
            }

            Spacer()
        }
    }

    // MARK: - Form Content

    private var formContent: some View {
        ScrollView {
            VStack(spacing: 14) {
                headerCard

                ForEach(viewModel.exercises, id: \.id) { templateExercise in
                    exerciseCard(templateExercise)
                }

                addExerciseButton
            }
            .padding(.horizontal, .spacingBase)
            .padding(.bottom, .spacing4xl)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    // MARK: - Header Card

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            TextField("Template name", text: $viewModel.name)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.textPrimary)

            Divider()
                .background(Color.borderSubtle)
                .padding(.top, 10)

            TextField("Notes...", text: $viewModel.notes, axis: .vertical)
                .font(.system(size: 13))
                .foregroundStyle(Color.textSecondary)
                .lineLimit(3...6)
                .padding(.top, .spacingSm)
        }
        .padding(14)
        .padding(.horizontal, 2)
        .background(Color.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: .radiusLg))
        .overlay(
            RoundedRectangle(cornerRadius: .radiusLg)
                .stroke(Color.borderSubtle, lineWidth: 1)
        )
    }

    // MARK: - Exercise Card

    private func exerciseCard(_ templateExercise: SchemaV1.TemplateExercise) -> some View {
        let exercise = templateExercise.exercise
        let exerciseType = exercise?.type ?? .weightAndReps
        let sets = templateExercise.sets.sorted { $0.order < $1.order }
        let previousSets = exercise.flatMap { viewModel.previousPerformance[$0.id] } ?? []

        return ExerciseCardContainer {
            ExerciseCardHeader(name: exercise?.name ?? "Unknown Exercise") {
                Menu {
                    Button(role: .destructive) {
                        Task { await viewModel.removeExercise(templateExercise) }
                    } label: {
                        Label("Remove Exercise", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.textTertiary)
                        .frame(width: 28, height: 28)
                }
            }

            SetColumnHeaders(exerciseType: exerciseType)

            Rectangle()
                .fill(Color.borderSubtle)
                .frame(height: 1)

            ForEach(Array(sets.enumerated()), id: \.element.id) { index, templateSet in
                let previousSet = index < previousSets.count ? previousSets[index] : nil
                EditableSetRow(
                    exerciseType: exerciseType,
                    setNumber: index + 1,
                    badgeStyle: .neutral,
                    weight: templateSet.weight,
                    reps: templateSet.reps,
                    bodyweightModifier: templateSet.bodyweightModifier,
                    time: templateSet.time,
                    distance: templateSet.distance,
                    notes: templateSet.notes,
                    previousWeight: previousSet?.weight,
                    previousReps: previousSet?.reps,
                    previousBodyweightModifier: previousSet?.bodyweightModifier,
                    previousTime: previousSet?.time,
                    previousDistance: previousSet?.distance,
                    previousNotes: previousSet?.notes,
                    onWeightChange: { newVal in
                        Task {
                            await viewModel.updateSet(
                                templateSet, weight: newVal, reps: templateSet.reps,
                                bodyweightModifier: templateSet.bodyweightModifier,
                                time: templateSet.time, distance: templateSet.distance,
                                notes: templateSet.notes
                            )
                        }
                    },
                    onRepsChange: { newVal in
                        Task {
                            await viewModel.updateSet(
                                templateSet, weight: templateSet.weight, reps: newVal,
                                bodyweightModifier: templateSet.bodyweightModifier,
                                time: templateSet.time, distance: templateSet.distance,
                                notes: templateSet.notes
                            )
                        }
                    },
                    onBodyweightModifierChange: { newVal in
                        Task {
                            await viewModel.updateSet(
                                templateSet, weight: templateSet.weight, reps: templateSet.reps,
                                bodyweightModifier: newVal,
                                time: templateSet.time, distance: templateSet.distance,
                                notes: templateSet.notes
                            )
                        }
                    },
                    onTimeChange: { newVal in
                        Task {
                            await viewModel.updateSet(
                                templateSet, weight: templateSet.weight, reps: templateSet.reps,
                                bodyweightModifier: templateSet.bodyweightModifier,
                                time: newVal, distance: templateSet.distance,
                                notes: templateSet.notes
                            )
                        }
                    },
                    onDistanceChange: { newVal in
                        Task {
                            await viewModel.updateSet(
                                templateSet, weight: templateSet.weight, reps: templateSet.reps,
                                bodyweightModifier: templateSet.bodyweightModifier,
                                time: templateSet.time, distance: newVal,
                                notes: templateSet.notes
                            )
                        }
                    },
                    onNotesChange: { newVal in
                        Task {
                            await viewModel.updateSet(
                                templateSet, weight: templateSet.weight, reps: templateSet.reps,
                                bodyweightModifier: templateSet.bodyweightModifier,
                                time: templateSet.time, distance: templateSet.distance,
                                notes: newVal
                            )
                        }
                    }
                )
                .contextMenu {
                    Button(role: .destructive) {
                        Task { await viewModel.removeSet(templateSet, from: templateExercise) }
                    } label: {
                        Label("Delete Set", systemImage: "trash")
                    }
                }
            }

            Button {
                Task { await viewModel.addSet(to: templateExercise) }
            } label: {
                Text("+ Add Set")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.top, .spacingSm)
                    .padding(.bottom, 10)
            }
        }
    }

    // MARK: - Add Exercise Button

    private var addExerciseButton: some View {
        Button {
            viewModel.addExercise()
        } label: {
            HStack(spacing: .spacingSm) {
                Image(systemName: "plus")
                    .font(.system(size: 13, weight: .semibold))
                Text("Add Exercise")
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(Color.accent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.bgCard)
            .clipShape(RoundedRectangle(cornerRadius: .radiusLg))
            .overlay(
                RoundedRectangle(cornerRadius: .radiusLg)
                    .strokeBorder(Color.borderDefault, style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
            )
        }
    }
}
