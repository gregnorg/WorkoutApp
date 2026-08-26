import Charts
import SwiftUI

struct HistoryView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        IndividualWorkoutHistoryView()
                    } label: {
                        HistoryOptionLabel(
                            title: "Individual Workouts",
                            description: "Review each recorded workout and its completed sets.",
                            symbol: "list.bullet.rectangle"
                        )
                    }

                    NavigationLink {
                        LiftHistoryView()
                    } label: {
                        HistoryOptionLabel(
                            title: "Per-Lift History",
                            description: "Choose a lift to see its weight over time.",
                            symbol: "chart.xyaxis.line"
                        )
                    }
                }
            }
            .navigationTitle("Workout History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private struct HistoryOptionLabel: View {
    let title: String
    let description: String
    let symbol: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.title2)
                .foregroundStyle(AppTheme.accent)
                .frame(width: 42, height: 42)
                .background(AppTheme.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 11))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 5)
        }
    }
}

private struct IndividualWorkoutHistoryView: View {
    @EnvironmentObject private var store: WorkoutStore

    var body: some View {
        Group {
            if store.history.isEmpty {
                ContentUnavailableView {
                    Label("No workout history", systemImage: "clock.arrow.circlepath")
                } description: {
                    Text("Workouts with at least one completed set will appear here.")
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
        .navigationTitle("Individual Workouts")
        .navigationBarTitleDisplayMode(.inline)
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

private struct LiftHistoryView: View {
    @EnvironmentObject private var store: WorkoutStore

    private var lifts: [LiftHistory] {
        LiftHistory.make(from: store.history)
    }

    var body: some View {
        Group {
            if lifts.isEmpty {
                ContentUnavailableView {
                    Label("No lift history", systemImage: "chart.xyaxis.line")
                } description: {
                    Text("Complete at least one set of a lift to begin tracking it.")
                }
            } else {
                List(lifts) { lift in
                    NavigationLink {
                        LiftChartView(lift: lift)
                    } label: {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(lift.name)
                                .font(.headline)
                            Text("\(lift.records.count) \(lift.records.count == 1 ? "workout" : "workouts") • Latest: \(lift.latestWeightLabel)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 5)
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Per-Lift History")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct LiftChartView: View {
    let lift: LiftHistory

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Chart(lift.records) { record in
                    LineMark(
                        x: .value("Date", record.date),
                        y: .value("Weight", record.weight)
                    )
                    .foregroundStyle(AppTheme.accent)

                    PointMark(
                        x: .value("Date", record.date),
                        y: .value("Weight", record.weight)
                    )
                    .foregroundStyle(AppTheme.accent)
                    .symbolSize(55)
                }
                .chartYAxisLabel("Weight (lb)")
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) {
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    }
                }
                .frame(height: 280)
                .padding()
                .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 18))

                VStack(alignment: .leading, spacing: 12) {
                    Text("Recorded Lifts")
                        .font(.headline)

                    ForEach(lift.records.reversed()) { record in
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(record.date.formatted(date: .abbreviated, time: .omitted))
                                    .font(.subheadline.weight(.semibold))
                                Text("\(record.completedSets) sets × \(record.reps) reps • \(record.workoutName)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(record.weightLabel)
                                .font(.body.bold().monospacedDigit())
                        }
                        Divider()
                    }
                }
            }
            .padding()
        }
        .background(AppTheme.background)
        .navigationTitle(lift.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct LiftHistory: Identifiable {
    let id: String
    let name: String
    let records: [LiftHistoryRecord]

    var latestWeightLabel: String {
        records.last?.weightLabel ?? "—"
    }

    static func make(from history: [WorkoutHistoryEntry]) -> [LiftHistory] {
        var recordsByName: [String: [LiftHistoryRecord]] = [:]
        var displayNames: [String: String] = [:]

        for workout in history {
            for exercise in workout.exercises where exercise.completedSets > 0 {
                let name = exercise.name.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !name.isEmpty else { continue }
                let key = name.lowercased()
                if displayNames[key] == nil {
                    displayNames[key] = name
                }
                recordsByName[key, default: []].append(
                    LiftHistoryRecord(
                        id: exercise.id,
                        date: workout.completedAt,
                        workoutName: workout.workoutName,
                        reps: exercise.reps,
                        weight: exercise.weight,
                        completedSets: exercise.completedSets
                    )
                )
            }
        }

        return recordsByName.map { key, records in
            LiftHistory(
                id: key,
                name: displayNames[key] ?? key,
                records: records.sorted { $0.date < $1.date }
            )
        }
        .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}

private struct LiftHistoryRecord: Identifiable {
    let id: UUID
    let date: Date
    let workoutName: String
    let reps: Int
    let weight: Double
    let completedSets: Int

    var weightLabel: String {
        weight > 0
            ? "\(weight.formatted(.number.precision(.fractionLength(0...1)))) lb"
            : "Bodyweight"
    }
}

#Preview {
    HistoryView()
        .environmentObject(WorkoutStore())
}
