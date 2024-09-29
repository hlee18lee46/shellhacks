import SwiftUI
import GoogleSignIn

@main
struct shellhackApp: App {
    // Connect the AppDelegate to the SwiftUI lifecycle
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
