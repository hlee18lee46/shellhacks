import UIKit
import GoogleSignIn

class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Initialize Google Sign-In configuration
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: "1032321385299-ch0b9ster23tp9v7md35q6ie0grnblc7.apps.googleusercontent.com")
        return true
    }

    // Handle URL opened by Google Sign-In
    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
}
