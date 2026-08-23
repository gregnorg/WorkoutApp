import SwiftUI

struct WorkoutDetailView: View {
    @EnvironmentObject private var store: WorkoutStore
    let workoutID: UUID
    @State private var showingNewExercise = false
    @State private var showingResetConfirmation = false
    @State private var isEditing = false

    private var workout: Workout? {
        store.workouts.first(where: { $0.id == workoutID })
    }

    var body: some View {
        Group {
            if let workout {
                List {
                    Section {
                        progressHeader(workout)
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .padding(.vertical, 6)
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
                                ExerciseRow(exercise: exercise, tint: workout.tint, isEditing: isEditing) { setIndex in
                                    withAnimation(.snappy) {
                                        store.toggleSet(setIndex, for: exercise.id, in: workoutID)
                                    }
                                }
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
                .environment(\.editMode, .constant(isEditing ? .active : .inactive))
            } else {
                ContentUnavailableView("Workout not found", systemImage: "exclamationmark.triangle")
            }
        }
    }

    private func progressHeader(_ workout: Workout) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(workout.isComplete ? "Workout complete!" : "Today's progress")
                        .font(.title2.bold())
                    Text(workout.focus.isEmpty ? "One exercise at a time." : workout.focus)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(Int(workout.progress * 100))%")
                    .font(.title2.bold().monospacedDigit())
                    .foregroundStyle(workout.tint)
            }
            ProgressView(value: workout.progress)
                .tint(workout.tint)
                .scaleEffect(x: 1, y: 1.8)
        }
        .padding(20)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

private struct ExerciseRow: View {
    let exercise: Exercise
    let tint: Color
    let isEditing: Bool
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
        }
        .padding(.vertical, 5)
    }
}
