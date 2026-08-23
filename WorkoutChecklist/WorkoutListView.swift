import SwiftUI

struct WorkoutListView: View {
    @EnvironmentObject private var store: WorkoutStore

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
                        Section {
                            WeeklySummaryCard(workouts: store.workouts)
                                .listRowInsets(EdgeInsets())
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .padding(.vertical, 4)
                        }

                        Section("Your routines") {
                            ForEach(store.workouts) { workout in
                                NavigationLink(value: workout.id) {
                                    WorkoutRow(workout: workout)
                                }
                                .listRowBackground(AppTheme.card)
                                .listRowSeparator(.hidden)
                            }
                            .onDelete(perform: store.deleteWorkouts)
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("GymForge")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
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
        }
    }
}

private struct WeeklySummaryCard: View {
    let workouts: [Workout]

    private var completed: Int { workouts.filter(\.isComplete).count }

    var body: some View {
        HStack(spacing: 18) {
            ZStack {
                Circle()
                    .stroke(.white.opacity(0.22), lineWidth: 7)
                Circle()
                    .trim(from: 0, to: workouts.isEmpty ? 0 : Double(completed) / Double(workouts.count))
                    .stroke(.white, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(completed)/\(workouts.count)")
                    .font(.headline.monospacedDigit())
            }
            .frame(width: 66, height: 66)

            VStack(alignment: .leading, spacing: 5) {
                Text(completed == workouts.count ? "You crushed it" : "Ready when you are")
                    .font(.title3.bold())
                Text("Complete your routines and keep the momentum going.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.82))
            }
        }
        .foregroundStyle(.white)
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [AppTheme.accent, Color(red: 0.98, green: 0.48, blue: 0.20)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
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
                Text(workout.focus.isEmpty ? "Custom workout" : workout.focus)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
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

#Preview {
    WorkoutListView()
        .environmentObject(WorkoutStore())
}
