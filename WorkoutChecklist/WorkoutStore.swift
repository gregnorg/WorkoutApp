import Foundation

@MainActor
final class WorkoutStore: ObservableObject {
    @Published private(set) var workouts: [Workout] = [] {
        didSet { save() }
    }
    @Published private(set) var history: [WorkoutHistoryEntry] = [] {
        didSet { saveHistory() }
    }

    private let saveURL: URL
    private let historyURL: URL
    private var isLoading = true

    init(fileManager: FileManager = .default) {
        let directory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        saveURL = directory.appendingPathComponent("workouts.json")
        historyURL = directory.appendingPathComponent("workout-history.json")
        load()
        loadHistory()
        isLoading = false
    }

    func addWorkout() -> UUID {
        let tintNames = ["orange", "blue", "purple", "green"]
        let nextIndex = nextAvailableWorkoutIndex()
        let workout = Workout(
            name: "Workout \(Self.letterLabel(for: nextIndex))",
            focus: "",
            symbol: "dumbbell.fill",
            tintName: tintNames[nextIndex % tintNames.count],
            exercises: []
        )
        workouts.append(workout)
        return workout.id
    }

    func deleteWorkouts(at offsets: IndexSet) {
        for offset in offsets.sorted(by: >) {
            workouts.remove(at: offset)
        }
    }

    func renameWorkout(_ workoutID: UUID, to name: String) {
        guard let index = index(of: workoutID) else { return }
        workouts[index].name = name
    }

    func addExercise(to workoutID: UUID, name: String, sets: Int, reps: Int, weight: Double) {
        guard let index = index(of: workoutID) else { return }
        let exercise = Exercise(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            sets: sets,
            reps: reps,
            weight: weight
        )
        workouts[index].exercises.append(exercise)
    }

    func updateExercise(
        _ exerciseID: UUID,
        in workoutID: UUID,
        name: String,
        sets: Int,
        reps: Int,
        weight: Double
    ) {
        guard let workoutIndex = index(of: workoutID),
              let exerciseIndex = workouts[workoutIndex].exercises.firstIndex(where: { $0.id == exerciseID })
        else { return }

        workouts[workoutIndex].exercises[exerciseIndex].name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        workouts[workoutIndex].exercises[exerciseIndex].sets = sets
        workouts[workoutIndex].exercises[exerciseIndex].reps = reps
        workouts[workoutIndex].exercises[exerciseIndex].weight = weight
        workouts[workoutIndex].exercises[exerciseIndex].completedSets = workouts[workoutIndex]
            .exercises[exerciseIndex]
            .completedSets
            .filter { $0 < sets }
        updateCompletionDate(forWorkoutAt: workoutIndex)
    }

    func deleteExercises(at offsets: IndexSet, from workoutID: UUID) {
        guard let index = index(of: workoutID) else { return }
        for offset in offsets.sorted(by: >) {
            workouts[index].exercises.remove(at: offset)
        }
    }

    func toggleSet(_ setIndex: Int, for exerciseID: UUID, in workoutID: UUID) {
        guard let workoutIndex = index(of: workoutID),
              let exerciseIndex = workouts[workoutIndex].exercises.firstIndex(where: { $0.id == exerciseID })
        else { return }

        guard setIndex >= 0, setIndex < workouts[workoutIndex].exercises[exerciseIndex].sets else { return }

        if workouts[workoutIndex].exercises[exerciseIndex].completedSets.contains(setIndex) {
            workouts[workoutIndex].exercises[exerciseIndex].completedSets.remove(setIndex)
        } else {
            workouts[workoutIndex].exercises[exerciseIndex].completedSets.insert(setIndex)
        }
        updateCompletionDate(forWorkoutAt: workoutIndex)
    }

    func reset(_ workoutID: UUID) {
        guard let index = index(of: workoutID) else { return }
        for exerciseIndex in workouts[index].exercises.indices {
            workouts[index].exercises[exerciseIndex].completedSets.removeAll()
        }
        workouts[index].lastCompletedAt = nil
    }

    func finishAndRecord(_ workoutID: UUID) {
        guard let index = index(of: workoutID) else { return }
        let workout = workouts[index]
        guard workout.completedSetCount > 0 else { return }
        let entry = WorkoutHistoryEntry(
            workoutID: workout.id,
            workoutName: workout.name,
            completedAt: .now,
            exercises: workout.exercises.map { exercise in
                ExerciseHistoryEntry(
                    name: exercise.name,
                    sets: exercise.sets,
                    reps: exercise.reps,
                    weight: exercise.weight,
                    completedSets: exercise.completedSets.count
                )
            }
        )
        history.insert(entry, at: 0)
        reset(workoutID)
    }

    func deleteHistory(at offsets: IndexSet) {
        for offset in offsets.sorted(by: >) {
            history.remove(at: offset)
        }
    }

    private func index(of workoutID: UUID) -> Int? {
        workouts.firstIndex(where: { $0.id == workoutID })
    }

    private func updateCompletionDate(forWorkoutAt index: Int) {
        if workouts[index].isComplete {
            workouts[index].lastCompletedAt = .now
        } else {
            workouts[index].lastCompletedAt = nil
        }
    }

    private func load() {
        guard let data = try? Data(contentsOf: saveURL),
              let decoded = try? JSONDecoder().decode([Workout].self, from: data)
        else {
            workouts = Workout.samples
            return
        }
        workouts = decoded
    }

    private func loadHistory() {
        guard let data = try? Data(contentsOf: historyURL),
              let decoded = try? JSONDecoder().decode([WorkoutHistoryEntry].self, from: data)
        else { return }
        history = decoded
            .filter { $0.completedSetCount > 0 }
            .sorted { $0.completedAt > $1.completedAt }
    }

    private func save() {
        guard !isLoading, let data = try? JSONEncoder().encode(workouts) else { return }
        try? data.write(to: saveURL, options: .atomic)
    }

    private func saveHistory() {
        guard !isLoading, let data = try? JSONEncoder().encode(history) else { return }
        try? data.write(to: historyURL, options: .atomic)
    }

    private func nextAvailableWorkoutIndex() -> Int {
        let names = Set(workouts.map(\.name))
        var index = workouts.count
        while names.contains("Workout \(Self.letterLabel(for: index))") {
            index += 1
        }
        return index
    }

    private static func letterLabel(for index: Int) -> String {
        var number = index + 1
        var label = ""
        while number > 0 {
            number -= 1
            label.insert(Character(UnicodeScalar(65 + number % 26)!), at: label.startIndex)
            number /= 26
        }
        return label
    }
}
