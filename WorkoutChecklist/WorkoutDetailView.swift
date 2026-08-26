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
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            guard showingConfetti else { return }
            store.finishAndRecord(workoutID)
            dismiss()
        }
    }
}

private struct ConfettiView: View {
    private let startTime = Date()
    private let colors: [Color] = [
        .yellow, .pink, .cyan, .green, .orange, .purple, .white, .yellow, .mint, .white
    ]

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
            let elapsed = timeline.date.timeIntervalSince(startTime)

            Canvas(opaque: false, rendersAsynchronously: true) { context, size in
                for index in 0..<150 {
                    drawParticle(index, elapsed: elapsed, size: size, context: context)
                }
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    private func drawParticle(
        _ index: Int,
        elapsed: TimeInterval,
        size: CGSize,
        context: GraphicsContext
    ) {
        let delay = fraction(index, salt: 47) * 0.16
        let age = elapsed - delay
        let lifetime = 1.85 + fraction(index, salt: 61) * 0.55
        guard age >= 0, age <= lifetime else { return }

        let width = Double(size.width)
        let height = Double(size.height)
        let launchX = width / 2 + (fraction(index, salt: 13) - 0.5) * width * 0.16
        let horizontalVelocity = (fraction(index, salt: 11) - 0.5) * width * 1.35
        let verticalVelocity = -height * (1.18 + fraction(index, salt: 73) * 0.62)
        let gravity = height * (1.15 + fraction(index, salt: 31) * 0.25)
        let flutter = sin(age * (7 + fraction(index, salt: 19) * 9) + Double(index)) * 7

        let x = launchX + horizontalVelocity * age + flutter
        let y = height + 12 + verticalVelocity * age + 0.5 * gravity * age * age
        let fadeStart = lifetime * 0.62
        let opacity = age < fadeStart ? 1 : max(0, (lifetime - age) / (lifetime - fadeStart))
        let direction = index.isMultiple(of: 2) ? 1.0 : -1.0
        let rotation = age * (5 + fraction(index, salt: 89) * 12) * direction
        let particleWidth = 4 + fraction(index, salt: 5) * 6
        let particleHeight = 6 + fraction(index, salt: 7) * 9

        var particleContext = context
        particleContext.opacity = opacity
        particleContext.translateBy(x: x, y: y)
        particleContext.rotate(by: .radians(rotation))

        let rectangle = CGRect(
            x: -particleWidth / 2,
            y: -particleHeight / 2,
            width: particleWidth,
            height: particleHeight
        )
        let path = Path(roundedRect: rectangle, cornerRadius: 1)
        particleContext.stroke(path, with: .color(.black.opacity(0.2)), lineWidth: 0.6)
        particleContext.fill(path, with: .color(colors[index % colors.count]))
    }

    private func fraction(_ index: Int, salt: Int) -> Double {
        Double((index * 37 + salt * 17) % 101) / 100
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
