import SwiftUI

@main
struct GymForgeApp: App {
    @StateObject private var store = WorkoutStore()

    var body: some Scene {
        WindowGroup {
            WorkoutListView()
                .environmentObject(store)
                .tint(AppTheme.accent)
        }
    }
}
