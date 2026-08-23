import SwiftUI

struct NewExerciseView: View {
    @EnvironmentObject private var store: WorkoutStore
    @Environment(\.dismiss) private var dismiss
    let workoutID: UUID
    @State private var name = ""
    @State private var sets = 3
    @State private var reps = 10
    @State private var weight = 0.0

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
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        store.addExercise(
                            to: workoutID,
                            name: name,
                            sets: sets,
                            reps: reps,
                            weight: max(0, weight)
                        )
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
