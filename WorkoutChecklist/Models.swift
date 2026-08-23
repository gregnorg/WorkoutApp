import Foundation
import SwiftUI

struct Exercise: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var sets: Int
    var reps: Int
    var weight: Double
    var completedSets: Set<Int>

    var weightLabel: String {
        weight > 0
            ? "\(weight.formatted(.number.precision(.fractionLength(0...1)))) lb"
            : "Bodyweight"
    }

    var isComplete: Bool {
        sets > 0 && completedSets.count == sets
    }

    init(
        id: UUID = UUID(),
        name: String,
        sets: Int,
        reps: Int,
        weight: Double,
        completedSets: Set<Int> = []
    ) {
        self.id = id
        self.name = name
        self.sets = sets
        self.reps = reps
        self.weight = weight
        self.completedSets = completedSets
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, sets, reps, weight, completedSets, isComplete, details
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decode(String.self, forKey: .name)
        let legacyDetails = try container.decodeIfPresent(String.self, forKey: .details) ?? ""
        let legacyNumbers = legacyDetails
            .split(whereSeparator: { !$0.isNumber })
            .compactMap { Int($0) }
        sets = try container.decodeIfPresent(Int.self, forKey: .sets) ?? legacyNumbers.first ?? 3
        reps = try container.decodeIfPresent(Int.self, forKey: .reps) ?? legacyNumbers.dropFirst().first ?? 10
        weight = try container.decodeIfPresent(Double.self, forKey: .weight) ?? 0

        if let decodedSets = try container.decodeIfPresent(Set<Int>.self, forKey: .completedSets) {
            let setCount = sets
            completedSets = decodedSets.filter { $0 >= 0 && $0 < setCount }
        } else if try container.decodeIfPresent(Bool.self, forKey: .isComplete) == true {
            completedSets = Set(0..<sets)
        } else {
            completedSets = []
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(sets, forKey: .sets)
        try container.encode(reps, forKey: .reps)
        try container.encode(weight, forKey: .weight)
        try container.encode(completedSets, forKey: .completedSets)
    }
}

struct Workout: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var focus: String
    var symbol: String
    var tintName: String
    var exercises: [Exercise]
    var lastCompletedAt: Date?

    var completedCount: Int {
        exercises.filter(\.isComplete).count
    }

    var progress: Double {
        guard !exercises.isEmpty else { return 0 }
        return Double(completedCount) / Double(exercises.count)
    }

    var isComplete: Bool {
        !exercises.isEmpty && exercises.allSatisfy(\.isComplete)
    }

    var tint: Color {
        switch tintName {
        case "orange": return Color(red: 1.0, green: 0.43, blue: 0.18)
        case "blue": return Color(red: 0.22, green: 0.56, blue: 0.98)
        case "purple": return Color(red: 0.60, green: 0.38, blue: 0.96)
        case "green": return Color(red: 0.20, green: 0.72, blue: 0.50)
        default: return AppTheme.accent
        }
    }
}

enum AppTheme {
    static let accent = Color(red: 0.95, green: 0.30, blue: 0.20)
    static let background = Color(uiColor: .systemGroupedBackground)
    static let card = Color(uiColor: .secondarySystemGroupedBackground)
}

extension Workout {
    static let samples: [Workout] = [
        Workout(
            name: "Workout A",
            focus: "Chest, shoulders & triceps",
            symbol: "figure.strengthtraining.traditional",
            tintName: "orange",
            exercises: [
                Exercise(name: "Bench press", sets: 4, reps: 8, weight: 135),
                Exercise(name: "Incline dumbbell press", sets: 3, reps: 10, weight: 40),
                Exercise(name: "Shoulder press", sets: 3, reps: 10, weight: 30),
                Exercise(name: "Tricep pushdown", sets: 3, reps: 12, weight: 50)
            ]
        ),
        Workout(
            name: "Workout B",
            focus: "Quads, hamstrings & glutes",
            symbol: "figure.run",
            tintName: "blue",
            exercises: [
                Exercise(name: "Back squat", sets: 4, reps: 6, weight: 185),
                Exercise(name: "Romanian deadlift", sets: 3, reps: 8, weight: 135),
                Exercise(name: "Walking lunges", sets: 3, reps: 10, weight: 25),
                Exercise(name: "Calf raises", sets: 3, reps: 15, weight: 45)
            ]
        )
    ]
}
