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

    func addWorkout(name: String, focus: String, tintName: String) -> UUID {
        let workout = Workout(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            focus: focus.trimmingCharacters(in: .whitespacesAndNewlines),
            symbol: "dumbbell.fill",
            tintName: tintName,
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

    func addExercise(to workoutID: UUID, name: String, details: String) {
        guard let index = index(of: workoutID) else { return }
        let exercise = Exercise(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            details: details.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        workouts[index].exercises.append(exercise)
    }

    func deleteExercises(at offsets: IndexSet, from workoutID: UUID) {
        guard let index = index(of: workoutID) else { return }
        for offset in offsets.sorted(by: >) {
            workouts[index].exercises.remove(at: offset)
        }
    }

    func toggleExercise(_ exerciseID: UUID, in workoutID: UUID) {
        guard let workoutIndex = index(of: workoutID),
              let exerciseIndex = workouts[workoutIndex].exercises.firstIndex(where: { $0.id == exerciseID })
        else { return }

        workouts[workoutIndex].exercises[exerciseIndex].isComplete.toggle()
        if workouts[workoutIndex].isComplete {
            workouts[workoutIndex].lastCompletedAt = .now
        } else {
            workouts[workoutIndex].lastCompletedAt = nil
        }
    }

    func reset(_ workoutID: UUID) {
        guard let index = index(of: workoutID) else { return }
        for exerciseIndex in workouts[index].exercises.indices {
            workouts[index].exercises[exerciseIndex].isComplete = false
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
    }

    private func save() {
        guard !isLoading, let data = try? JSONEncoder().encode(workouts) else { return }
        try? data.write(to: saveURL, options: .atomic)
    }
}
