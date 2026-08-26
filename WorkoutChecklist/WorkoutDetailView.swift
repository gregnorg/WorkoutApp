import SwiftUI

struct WorkoutDetailView: View {
    @EnvironmentObject private var store: WorkoutStore
    @Environment(\.dismiss) private var dismiss
    let workoutID: UUID
    @State private var showingNewExercise = false
    @State private var editingExercise: Exercise?
    @State private var showingResetConfirmation = false
    @State private var showingFinishConfirmation = false
    @State private var showingConfetti = false
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

                    Section {
                        Button {
                            showingFinishConfirmation = true
                        } label: {
                            Label("Finish and Record", systemImage: "checkmark.seal.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .tint(workout.tint)
                        .disabled(workout.exercises.isEmpty || showingConfetti)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .background(AppTheme.background)
                .navigationTitle(workout.name)
                .overlay {
                    if showingConfetti {
                        ConfettiView()
                            .allowsHitTesting(false)
                    }
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
                .confirmationDialog(
                    "Finish and record this workout?",
                    isPresented: $showingFinishConfirmation,
                    titleVisibility: .visible
                ) {
                    Button("Finish and Record") { celebrateAndFinish() }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("This workout will be added to Workout History, then its checkmarks will reset.")
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

    private func celebrateAndFinish() {
        showingConfetti = true
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_600_000_000)
            guard showingConfetti else { return }
            store.finishAndRecord(workoutID)
            dismiss()
        }
    }
}

private struct ConfettiView: View {
    @State private var isAnimating = false
    private let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<70, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(colors[index % colors.count])
                        .frame(width: 8, height: 13)
                        .position(x: geometry.size.width / 2, y: -15)
                        .offset(
                            x: isAnimating ? horizontalOffset(for: index, width: geometry.size.width) : 0,
                            y: isAnimating ? verticalOffset(for: index, height: geometry.size.height) : 0
                        )
                        .rotationEffect(.degrees(isAnimating ? rotation(for: index) : 0))
                        .rotation3DEffect(
                            .degrees(isAnimating ? 720 : 0),
                            axis: (x: 1, y: fraction(for: index, salt: 29), z: 0)
                        )
                        .animation(
                            .timingCurve(0.15, 0.7, 0.3, 1, duration: 1.35)
                                .delay(Double(fraction(for: index, salt: 47)) * 0.2),
                            value: isAnimating
                        )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .ignoresSafeArea()
        .onAppear {
            DispatchQueue.main.async { isAnimating = true }
        }
        .accessibilityHidden(true)
    }

    private func horizontalOffset(for index: Int, width: CGFloat) -> CGFloat {
        (fraction(for: index, salt: 11) - 0.5) * width * 1.8
    }

    private func verticalOffset(for index: Int, height: CGFloat) -> CGFloat {
        height * (0.82 + fraction(for: index, salt: 73) * 0.3)
    }

    private func rotation(for index: Int) -> Double {
        Double(360 + fraction(for: index, salt: 89) * 720)
    }

    private func fraction(for index: Int, salt: Int) -> CGFloat {
        CGFloat((index * 37 + salt * 17) % 101) / 100
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
