import SwiftUI

@main
struct LiquidNotesApp: App {
    // Needed so UIKit can ask us which orientations are allowed at runtime.
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    @State private var store = NoteStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
        }
    }
}
