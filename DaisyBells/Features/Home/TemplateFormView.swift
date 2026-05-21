import SwiftUI
import SwiftData

@MainActor
struct TemplateFormView: View {
    @State var viewModel: TemplateFormViewModel
    @Environment(DependencyContainer.self) private var container
    @State private var keyboardCoordinator = KeyboardFocusCoordinator()
    @State private var focusedField: FocusedSetField?
    @FocusState private var nameFocused: Bool
    @FocusState private var notesFocused: Bool
    @FocusState private var exerciseNotesFocused: Bool

    private func rebuildFocusList() {
        var inputs: [SetFocusInput] = []
        for exercise in viewModel.exercises {
            let sortedSets = exercise.sets.sorted { $0.order < $1.order }
            for (idx, set) in sortedSets.enumerated() {
                inputs.append(SetFocusInput(
                    exerciseName: exercise.exerciseName,
                    exerciseType: exercise.exerciseType,
                    setNumber: idx + 1,
                    setID: AnyHashable(set.id)
                ))
            }
        }
        keyboardCoordinator.update(from: inputs)
    }

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
                    focusedField = nil
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
        .tapToDismissKeyboard()
        .environment(keyboardCoordinator)
        .onChange(of: viewModel.exercises.map(\.id)) { _, _ in
            rebuildFocusList()
        }
        .onChange(of: viewModel.exercises.flatMap { $0.sets.map(\.id) }) { _, _ in
            rebuildFocusList()
        }
        .task {
            rebuildFocusList()
        }
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
                .focused($nameFocused)
                .submitLabel(.done)
                .textInputAutocapitalization(.words)
                .onSubmit { nameFocused = false }
                .keyboardDoneToolbar(isFocused: nameFocused) { nameFocused = false }
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.textPrimary)
                .task {
                    if !viewModel.isEditing { nameFocused = true }
                }

            Divider()
                .background(Color.borderSubtle)
                .padding(.top, 10)

            TextField("Notes", text: $viewModel.notes, axis: .vertical)
                .focused($notesFocused)
                .textInputAutocapitalization(.sentences)
                .keyboardDoneToolbar(isFocused: notesFocused) { notesFocused = false }
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

    private func exerciseCard(_ templateExercise: DraftTemplateExercise) -> some View {
        let exerciseType = templateExercise.exerciseType
        let sets = templateExercise.sets.sorted { $0.order < $1.order }
        let previousSets = viewModel.previousPerformance[templateExercise.exerciseId] ?? []

        return ExerciseCardContainer {
            ExerciseCardHeader(name: templateExercise.exerciseName) {
                Menu {
                    Button(role: .destructive) {
                        viewModel.removeExercise(templateExercise)
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

            // Exercise notes
            TextField("Add note...", text: Binding(
                get: { templateExercise.exerciseNotes ?? "" },
                set: { newValue in
                    Task { await viewModel.updateExerciseNotes(templateExercise, notes: newValue.isEmpty ? nil : newValue) }
                }
            ), axis: .vertical)
            .focused($exerciseNotesFocused)
            .textInputAutocapitalization(.sentences)
            .keyboardDoneToolbar(isFocused: exerciseNotesFocused) { exerciseNotesFocused = false }
            .font(.system(size: 12))
            .foregroundStyle(Color.textSecondary)
            .lineLimit(1...3)
            .padding(.horizontal, 14)
            .padding(.bottom, .spacingXs)

            SetColumnHeaders(exerciseType: exerciseType)

            Rectangle()
                .fill(Color.borderSubtle)
                .frame(height: 1)

            ForEach(Array(sets.enumerated()), id: \.element.id) { index, templateSet in
                let previousSet = index < previousSets.count ? previousSets[index] : nil
                let sameAsLastSet = index > 0 ? sets[index - 1] : nil
                EditableSetRow(
                    exerciseType: exerciseType,
                    setNumber: index + 1,
                    badgeStyle: .neutral,
                    setID: AnyHashable(templateSet.id),
                    focusedField: $focusedField,
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
                    sameAsLastWeight: sameAsLastSet?.weight,
                    sameAsLastReps: sameAsLastSet?.reps,
                    sameAsLastBodyweightModifier: sameAsLastSet?.bodyweightModifier,
                    sameAsLastTime: sameAsLastSet?.time,
                    sameAsLastDistance: sameAsLastSet?.distance,
                    resolveNextField: { [keyboardCoordinator] field in
                        keyboardCoordinator.next(of: field)
                    },
                    onWeightChange: { newVal in
                        viewModel.updateSet(
                            templateSet, in: templateExercise,
                            weight: newVal, reps: templateSet.reps,
                            bodyweightModifier: templateSet.bodyweightModifier,
                            time: templateSet.time, distance: templateSet.distance,
                            notes: templateSet.notes
                        )
                    },
                    onRepsChange: { newVal in
                        viewModel.updateSet(
                            templateSet, in: templateExercise,
                            weight: templateSet.weight, reps: newVal,
                            bodyweightModifier: templateSet.bodyweightModifier,
                            time: templateSet.time, distance: templateSet.distance,
                            notes: templateSet.notes
                        )
                    },
                    onBodyweightModifierChange: { newVal in
                        viewModel.updateSet(
                            templateSet, in: templateExercise,
                            weight: templateSet.weight, reps: templateSet.reps,
                            bodyweightModifier: newVal,
                            time: templateSet.time, distance: templateSet.distance,
                            notes: templateSet.notes
                        )
                    },
                    onTimeChange: { newVal in
                        viewModel.updateSet(
                            templateSet, in: templateExercise,
                            weight: templateSet.weight, reps: templateSet.reps,
                            bodyweightModifier: templateSet.bodyweightModifier,
                            time: newVal, distance: templateSet.distance,
                            notes: templateSet.notes
                        )
                    },
                    onDistanceChange: { newVal in
                        viewModel.updateSet(
                            templateSet, in: templateExercise,
                            weight: templateSet.weight, reps: templateSet.reps,
                            bodyweightModifier: templateSet.bodyweightModifier,
                            time: templateSet.time, distance: newVal,
                            notes: templateSet.notes
                        )
                    },
                    onNotesChange: { newVal in
                        viewModel.updateSet(
                            templateSet, in: templateExercise,
                            weight: templateSet.weight, reps: templateSet.reps,
                            bodyweightModifier: templateSet.bodyweightModifier,
                            time: templateSet.time, distance: templateSet.distance,
                            notes: newVal
                        )
                    }
                )
                .contextMenu {
                    Button(role: .destructive) {
                        viewModel.removeSet(templateSet, from: templateExercise)
                    } label: {
                        Label("Delete Set", systemImage: "trash")
                    }
                }
            }

            Button {
                viewModel.addSet(to: templateExercise)
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
