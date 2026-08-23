import Foundation
import SwiftUI

struct Exercise: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var details: String
    var isComplete = false
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
            name: "Push Day",
            focus: "Chest, shoulders & triceps",
            symbol: "figure.strengthtraining.traditional",
            tintName: "orange",
            exercises: [
                Exercise(name: "Bench press", details: "4 sets × 8 reps"),
                Exercise(name: "Incline dumbbell press", details: "3 sets × 10 reps"),
                Exercise(name: "Shoulder press", details: "3 sets × 10 reps"),
                Exercise(name: "Tricep pushdown", details: "3 sets × 12 reps")
            ]
        ),
        Workout(
            name: "Leg Day",
            focus: "Quads, hamstrings & glutes",
            symbol: "figure.run",
            tintName: "blue",
            exercises: [
                Exercise(name: "Back squat", details: "4 sets × 6 reps"),
                Exercise(name: "Romanian deadlift", details: "3 sets × 8 reps"),
                Exercise(name: "Walking lunges", details: "3 sets × 10 each"),
                Exercise(name: "Calf raises", details: "3 sets × 15 reps")
            ]
        )
    ]
}

