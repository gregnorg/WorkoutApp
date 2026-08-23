import SwiftUI

struct WorkoutDetailView: View {
    @EnvironmentObject private var store: WorkoutStore
    let workoutID: UUID
    @State private var showingNewExercise = false
    @State private var showingResetConfirmation = false

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
                            Button { showingNewExercise = true } label: {
                                Label("Add your first exercise", systemImage: "plus.circle.fill")
                            }
                        } else {
                            ForEach(workout.exercises) { exercise in
                                ExerciseRow(exercise: exercise, tint: workout.tint) {
                                    withAnimation(.snappy) {
                                        store.toggleExercise(exercise.id, in: workoutID)
                                    }
                                }
                            }
                            .onDelete { store.deleteExercises(at: $0, from: workoutID) }
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

                        Button { showingNewExercise = true } label: {
                            Image(systemName: "plus")
                        }
                        .accessibilityLabel("Add exercise")
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
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: exercise.isComplete ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(exercise.isComplete ? tint : Color.secondary)
                    .contentTransition(.symbolEffect(.replace))

                VStack(alignment: .leading, spacing: 3) {
                    Text(exercise.name)
                        .font(.body.weight(.semibold))
                        .strikethrough(exercise.isComplete, color: .secondary)
                    if !exercise.details.isEmpty {
                        Text(exercise.details)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.vertical, 5)
        .accessibilityLabel("\(exercise.name), \(exercise.isComplete ? "complete" : "incomplete")")
        .accessibilityHint("Double tap to toggle")
    }
}

