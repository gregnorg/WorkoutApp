import SwiftUI

struct NewWorkoutView: View {
    @EnvironmentObject private var store: WorkoutStore
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var focus = ""
    @State private var tintName = "orange"

    private let colors = ["orange", "blue", "purple", "green"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Workout details") {
                    TextField("Name, e.g. Pull Day", text: $name)
                        .textInputAutocapitalization(.words)
                    TextField("Focus (optional)", text: $focus)
                }

                Section("Color") {
                    HStack(spacing: 18) {
                        ForEach(colors, id: \.self) { colorName in
                            Button { tintName = colorName } label: {
                                Circle()
                                    .fill(color(for: colorName))
                                    .frame(width: 36, height: 36)
                                    .overlay {
                                        if tintName == colorName {
                                            Image(systemName: "checkmark")
                                                .font(.caption.bold())
                                                .foregroundStyle(.white)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(colorName.capitalized)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("New Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        _ = store.addWorkout(name: name, focus: focus, tintName: tintName)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func color(for name: String) -> Color {
        Workout(name: "", focus: "", symbol: "", tintName: name, exercises: []).tint
    }
}

