import SwiftUI
import SwiftData

@MainActor
struct SplitFormView: View {
    @State var viewModel: SplitFormViewModel
    @Environment(DependencyContainer.self) private var container
    @Environment(\.dismiss) private var dismiss
    @FocusState private var nameFocused: Bool
    @FocusState private var notesFocused: Bool
    @FocusState private var dayNameFocused: Bool

    var body: some View {
        List {
            nameAndNotesSection
            daysSection
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.bgPrimary)
        .navigationTitle(viewModel.isEditing ? "Edit Split" : "New Split")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    Task { await viewModel.save() }
                }
                .disabled(viewModel.name.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isSaving)
            }
        }
        .task { await viewModel.load() }
        .onChange(of: viewModel.shouldDismiss) { _, shouldDismiss in
            if shouldDismiss { dismiss() }
        }
        .errorAlert(errorMessage: $viewModel.errorMessage)
        .alert("Add Day", isPresented: $viewModel.showAddDayPrompt) {
            TextField("Day name", text: $viewModel.newDayName)
            Button("Cancel", role: .cancel) {
                viewModel.newDayName = ""
            }
            Button("Add") {
                viewModel.addDay(name: viewModel.newDayName)
                viewModel.newDayName = ""
            }
        } message: {
            Text("Enter a name for this day.")
        }
        .sheet(isPresented: $viewModel.showWorkoutPicker) {
            NavigationStack {
                WorkoutPickerSheet(
                    viewModel: WorkoutPickerViewModel(
                        templateService: container.templateService,
                        onSelect: { templateId in
                            viewModel.onWorkoutSelected(templateId)
                        }
                    )
                )
            }
        }
    }

    // MARK: - Name & Notes Section

    private var nameAndNotesSection: some View {
        Section {
            VStack(spacing: 0) {
                TextField("Split name", text: $viewModel.name)
                    .focused($nameFocused)
                    .doneKeyboardToolbar(isFocused: nameFocused) { nameFocused = false }
                    .foregroundStyle(Color.textPrimary)
                    .padding(.bottom, .spacingSm)
                Divider()
                TextField("Notes", text: $viewModel.notes, axis: .vertical)
                    .focused($notesFocused)
                    .doneKeyboardToolbar(isFocused: notesFocused) { notesFocused = false }
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(3...6)
                    .padding(.top, .spacingMd)
            }
        }
        .listRowBackground(Color.bgCard)
    }

    // MARK: - Days Section

    private var daysSection: some View {
        Section {
            ForEach(Array(viewModel.days.enumerated()), id: \.element.id) { index, day in
                dayCard(day: day, index: index)
            }
            .onDelete { offsets in
                viewModel.removeDay(at: offsets)
            }
            .onMove { source, destination in
                viewModel.reorderDays(from: source, to: destination)
            }

            addDayButton
        } header: {
            Text("Days")
                .foregroundStyle(Color.textSecondary)
        }
        .listRowBackground(Color.bgCard)
    }

    // MARK: - Day Card

    private func dayCard(day: SplitFormViewModel.DayEditState, index: Int) -> some View {
        VStack(alignment: .leading, spacing: .spacingSm) {
            TextField(
                "Day name",
                text: Binding(
                    get: { viewModel.days.indices.contains(index) ? viewModel.days[index].name : "" },
                    set: { viewModel.updateDayName($0, at: index) }
                )
            )
            .focused($dayNameFocused)
            .doneKeyboardToolbar(isFocused: dayNameFocused) { dayNameFocused = false }
            .font(.body.weight(.medium))
            .foregroundStyle(Color.textPrimary)

            ForEach(day.assignedWorkouts) { workout in
                HStack(spacing: .spacingSm) {
                    VStack(alignment: .leading, spacing: .spacing2xs) {
                        Text(workout.name)
                            .font(.subheadline)
                            .foregroundStyle(Color.textPrimary)
                        Text("\(workout.exerciseCount) exercise\(workout.exerciseCount == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundStyle(Color.textSecondary)
                    }

                    Spacer()

                    Button {
                        if let workoutIndex = viewModel.days[index].assignedWorkouts.firstIndex(where: { $0.id == workout.id }) {
                            viewModel.removeWorkout(at: IndexSet(integer: workoutIndex), fromDayAt: index)
                        }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .foregroundStyle(Color.destructive)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.leading, .spacingSm)
            }

            Button {
                viewModel.presentWorkoutPicker(forDayAt: index)
            } label: {
                HStack(spacing: .spacingXs) {
                    Image(systemName: "plus.circle")
                        .font(.subheadline)
                    Text("Add Workout")
                        .font(.subheadline)
                }
                .foregroundStyle(Color.accent)
            }
            .buttonStyle(.plain)
            .padding(.leading, .spacingSm)
        }
        .padding(.vertical, .spacingXs)
    }

    // MARK: - Add Day Button

    private var addDayButton: some View {
        Button {
            viewModel.showAddDayPrompt = true
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(Color.accent)
                Text("Add Day")
                    .foregroundStyle(Color.accent)
            }
        }
    }
}
