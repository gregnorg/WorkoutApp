import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var store: WorkoutStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if store.history.isEmpty {
                    ContentUnavailableView {
                        Label("No workout history", systemImage: "clock.arrow.circlepath")
                    } description: {
                        Text("Finished workouts will appear here.")
                    }
                } else {
                    List {
                        ForEach(store.history) { entry in
                            HistoryEntryView(entry: entry)
                        }
                        .onDelete(perform: store.deleteHistory)
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private struct HistoryEntryView: View {
    let entry: WorkoutHistoryEntry

    var body: some View {
        DisclosureGroup {
            ForEach(entry.exercises) { exercise in
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(exercise.name)
                            .font(.subheadline.weight(.semibold))
                        Text("\(exercise.sets) sets × \(exercise.reps) reps • \(exercise.weightLabel)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("\(exercise.completedSets)/\(exercise.sets)")
                        .font(.caption.bold().monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 3)
            }
        } label: {
            VStack(alignment: .leading, spacing: 5) {
                Text(entry.workoutName)
                    .font(.headline)
                Text(entry.completedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(entry.completedSetCount)/\(entry.totalSetCount) sets completed")
                    .font(.caption.bold())
            }
            .padding(.vertical, 5)
        }
    }
}

#Preview {
    HistoryView()
        .environmentObject(WorkoutStore())
}
