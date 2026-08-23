import SwiftUI

struct WorkoutListView: View {
    @EnvironmentObject private var store: WorkoutStore
    @State private var isEditing = false
    @State private var showingHistory = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                if store.workouts.isEmpty {
                    ContentUnavailableView {
                        Label("No workouts yet", systemImage: "dumbbell")
                    } description: {
                        Text("Build your first checklist and make it your own.")
                    } actions: {
                        Button("Create Workout A") {
                            withAnimation(.snappy) { _ = store.addWorkout() }
                        }
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    List {
                        Section("Your routines") {
                            ForEach(store.workouts) { workout in
                                if isEditing {
                                    WorkoutEditRow(workout: workout) { name in
                                        store.renameWorkout(workout.id, to: name)
                                    }
                                } else {
                                    NavigationLink(value: workout.id) {
                                        WorkoutRow(workout: workout)
                                    }
                                }
                            }
                            .onDelete(perform: store.deleteWorkouts)
                            .listRowBackground(AppTheme.card)
                            .listRowSeparator(.hidden)
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("GymForge")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showingHistory = true } label: {
                        Text("Workout History")
                    }
                    .accessibilityLabel("Workout history")
                }

                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button(isEditing ? "Done" : "Edit") {
                        withAnimation(.snappy) { isEditing.toggle() }
                    }
                    .disabled(store.workouts.isEmpty)

                    Button {
                        withAnimation(.snappy) { _ = store.addWorkout() }
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add next workout")
                }
            }
            .navigationDestination(for: UUID.self) { workoutID in
                WorkoutDetailView(workoutID: workoutID)
            }
            .sheet(isPresented: $showingHistory) {
                HistoryView()
            }
            .environment(\.editMode, .constant(isEditing ? .active : .inactive))
        }
    }
}

private struct WorkoutRow: View {
    let workout: Workout

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: workout.symbol)
                .font(.title3)
                .foregroundStyle(workout.tint)
                .frame(width: 44, height: 44)
                .background(workout.tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                Text(workout.name)
                    .font(.headline)
                ProgressView(value: workout.progress)
                    .tint(workout.tint)
            }

            Text("\(workout.completedCount)/\(workout.exercises.count)")
                .font(.caption.bold().monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 7)
    }
}

private struct WorkoutEditRow: View {
    let workout: Workout
    let rename: (String) -> Void

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: workout.symbol)
                .font(.title3)
                .foregroundStyle(workout.tint)
                .frame(width: 44, height: 44)
                .background(workout.tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 12))

            TextField(
                "Workout name",
                text: Binding(get: { workout.name }, set: rename)
            )
            .font(.headline)
            .textInputAutocapitalization(.words)
        }
        .padding(.vertical, 7)
    }
}

#Preview {
    WorkoutListView()
        .environmentObject(WorkoutStore())
}
