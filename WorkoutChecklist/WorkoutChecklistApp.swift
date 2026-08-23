import SwiftUI

@main
struct WorkoutChecklistApp: App {
    @StateObject private var store = WorkoutStore()

    var body: some Scene {
        WindowGroup {
            WorkoutListView()
                .environmentObject(store)
                .tint(AppTheme.accent)
        }
    }
}

