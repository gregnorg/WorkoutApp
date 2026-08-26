import SwiftUI

struct WorkoutDetailView: View {
    @EnvironmentObject private var store: WorkoutStore
    @Environment(\.dismiss) private var dismiss
    let workoutID: UUID
    @State private var showingNewExercise = false
    @State private var editingExercise: Exercise?
    @State private var showingResetConfirmation = false
    @State private var isEditing = false

    private var workout: Workout? {
        store.workouts.first(where: { $0.id == workoutID })
    }

    var body: some View {
        Group {
            if let workout {
                List {
                    if isEditing {
                        Section("Workout Name") {
                            TextField(
                                "Workout name",
                                text: Binding(
                                    get: { workout.name },
                                    set: { store.renameWorkout(workoutID, to: $0) }
                                )
                            )
                            .textInputAutocapitalization(.words)
                        }
                    }

                    Section("Exercises") {
                        if workout.exercises.isEmpty {
                            ContentUnavailableView {
                                Label("No exercises", systemImage: "dumbbell")
                            } description: {
                                Text(isEditing ? "Add the first exercise to this workout." : "Tap Edit to build this workout.")
                            }
                        } else {
                            ForEach(workout.exercises) { exercise in
                                ExerciseRow(
                                    exercise: exercise,
                                    tint: workout.tint,
                                    isEditing: isEditing,
                                    editExercise: { editingExercise = exercise },
                                    toggleSet: { setIndex in
                                        withAnimation(.snappy) {
                                            store.toggleSet(setIndex, for: exercise.id, in: workoutID)
                                        }
                                    }
                                )
                            }
                            .onDelete { store.deleteExercises(at: $0, from: workoutID) }
                            .deleteDisabled(!isEditing)
                        }

                        if isEditing {
                            Button { showingNewExercise = true } label: {
                                Label("Add Exercise", systemImage: "plus.circle.fill")
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .background(AppTheme.background)
                .navigationTitle(workout.name)
                .safeAreaInset(edge: .bottom) {
                    Button {
                        store.finishAndRecord(workoutID)
                        dismiss()
                    } label: {
                        Label("Finish and Record", systemImage: "checkmark.seal.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .tint(workout.tint)
                    .disabled(workout.exercises.isEmpty)
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                    .background(.bar)
                }
                .toolbar {
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        Button { showingResetConfirmation = true } label: {
                            Image(systemName: "arrow.counterclockwise")
                        }
                        .disabled(workout.completedCount == 0)
                        .accessibilityLabel("Reset workout")

                        Button(isEditing ? "Done" : "Edit") {
                            withAnimation(.snappy) { isEditing.toggle() }
                        }
                    }
                }
                .confirmationDialog("Reset this workout?", isPresented: $showingResetConfirmation) {
                    Button("Reset all exercises", role: .destructive) { store.reset(workoutID) }
                } message: {
                    Text("Every exercise will be marked incomplete.")
                }
                .sheet(isPresented: $showingNewExercise) {
                    NewExerciseView(workoutID: workoutID)
                }
                .sheet(item: $editingExercise) { exercise in
                    NewExerciseView(workoutID: workoutID, exercise: exercise)
                }
                .environment(\.editMode, .constant(isEditing ? .active : .inactive))
            } else {
                ContentUnavailableView("Workout not found", systemImage: "exclamationmark.triangle")
            }
        }
    }
}

private struct ExerciseRow: View {
    let exercise: Exercise
    let tint: Color
    let isEditing: Bool
    let editExercise: () -> Void
    let toggleSet: (Int) -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.body.weight(.semibold))
                    .strikethrough(exercise.isComplete, color: .secondary)
                    .lineLimit(2)
                Text(exercise.weightLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 120, alignment: .leading)
            .layoutPriority(1)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(0..<exercise.sets, id: \.self) { setIndex in
                        let isSetComplete = exercise.completedSets.contains(setIndex)
                        VStack(spacing: 4) {
                            Text("\(exercise.reps)")
                                .font(.caption.bold().monospacedDigit())
                                .foregroundStyle(.secondary)

                            Button {
                                guard !isEditing else { return }
                                toggleSet(setIndex)
                            } label: {
                                Image(systemName: isSetComplete ? "checkmark.circle.fill" : "circle")
                                    .font(.title2)
                                    .foregroundStyle(isSetComplete ? tint : Color.secondary)
                                    .contentTransition(.symbolEffect(.replace))
                            }
                            .buttonStyle(.plain)
                            .disabled(isEditing)
                            .accessibilityLabel("Set \(setIndex + 1), \(exercise.reps) reps, \(isSetComplete ? "complete" : "incomplete")")
                            .accessibilityHint("Double tap to toggle this set")
                        }
                    }
                }
            }

            if isEditing {
                Button(action: editExercise) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.title2)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Edit \(exercise.name)")
            }
        }
        .padding(.vertical, 5)
    }
}
