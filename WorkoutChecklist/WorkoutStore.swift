import Foundation

@MainActor
final class WorkoutStore: ObservableObject {
    @Published private(set) var workouts: [Workout] = [] {
        didSet { save() }
    }

    private let saveURL: URL
    private var isLoading = true

    init(fileManager: FileManager = .default) {
        let directory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        saveURL = directory.appendingPathComponent("workouts.json")
        load()
        isLoading = false
    }

    func addWorkout() -> UUID {
        let tintNames = ["orange", "blue", "purple", "green"]
        let workout = Workout(
            name: "Workout \(Self.letterLabel(for: workouts.count))",
            focus: "",
            symbol: "dumbbell.fill",
            tintName: tintNames[workouts.count % tintNames.count],
            exercises: []
        )
        workouts.append(workout)
        return workout.id
    }

    func deleteWorkouts(at offsets: IndexSet) {
        for offset in offsets.sorted(by: >) {
            workouts.remove(at: offset)
        }
        normalizeWorkoutNames()
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
        if workouts[workoutIndex].isComplete {
            workouts[workoutIndex].lastCompletedAt = .now
        } else {
            workouts[workoutIndex].lastCompletedAt = nil
        }
    }

    func reset(_ workoutID: UUID) {
        guard let index = index(of: workoutID) else { return }
        for exerciseIndex in workouts[index].exercises.indices {
            workouts[index].exercises[exerciseIndex].completedSets.removeAll()
        }
        workouts[index].lastCompletedAt = nil
    }

    private func index(of workoutID: UUID) -> Int? {
        workouts.firstIndex(where: { $0.id == workoutID })
    }

    private func load() {
        guard let data = try? Data(contentsOf: saveURL),
              let decoded = try? JSONDecoder().decode([Workout].self, from: data)
        else {
            workouts = Workout.samples
            return
        }
        workouts = decoded
        normalizeWorkoutNames()
    }

    private func save() {
        guard !isLoading, let data = try? JSONEncoder().encode(workouts) else { return }
        try? data.write(to: saveURL, options: .atomic)
    }

    private func normalizeWorkoutNames() {
        for index in workouts.indices {
            workouts[index].name = "Workout \(Self.letterLabel(for: index))"
        }
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
