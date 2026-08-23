import SwiftUI

struct NewExerciseView: View {
    @EnvironmentObject private var store: WorkoutStore
    @Environment(\.dismiss) private var dismiss
    let workoutID: UUID
    private let exerciseID: UUID?
    @State private var name: String
    @State private var sets: Int
    @State private var reps: Int
    @State private var weight: Double

    init(workoutID: UUID, exercise: Exercise? = nil) {
        self.workoutID = workoutID
        exerciseID = exercise?.id
        _name = State(initialValue: exercise?.name ?? "")
        _sets = State(initialValue: exercise?.sets ?? 3)
        _reps = State(initialValue: exercise?.reps ?? 10)
        _weight = State(initialValue: exercise?.weight ?? 0)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Exercise") {
                    TextField("Name, e.g. Deadlift", text: $name)
                        .textInputAutocapitalization(.words)
                }

                Section {
                    Stepper("Sets: \(sets)", value: $sets, in: 1...20)
                    Stepper("Reps per set: \(reps)", value: $reps, in: 1...100)

                    HStack {
                        Text("Weight")
                        Spacer()
                        TextField("0", value: $weight, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 90)
                        Text("lb")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Training")
                } footer: {
                    Text("Use 0 lb for bodyweight exercises.")
                }
            }
            .navigationTitle(exerciseID == nil ? "Add Exercise" : "Edit Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(exerciseID == nil ? "Add" : "Save") {
                        if let exerciseID {
                            store.updateExercise(
                                exerciseID,
                                in: workoutID,
                                name: name,
                                sets: sets,
                                reps: reps,
                                weight: max(0, weight)
                            )
                        } else {
                            store.addExercise(
                                to: workoutID,
                                name: name,
                                sets: sets,
                                reps: reps,
                                weight: max(0, weight)
                            )
                        }
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
