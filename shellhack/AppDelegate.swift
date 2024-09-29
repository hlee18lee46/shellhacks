import UIKit
import GoogleSignIn
import Supabase

// Add a property to hold the Supabase client

//var supabaseClient: SupabaseClient!

class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    var sharedSupabaseClient: SupabaseClient!

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Initialize Supabase client
        let url = URL(string: "https://qygphqztgfypivmlqtaj.supabase.co")!
        let key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF5Z3BocXp0Z2Z5cGl2bWxxdGFqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mjc1NjI4NTgsImV4cCI6MjA0MzEzODg1OH0.7l_g2RRthoa4KoYH__SLcvTgKD-xLUsxKIHJPrnaU1c"
        sharedSupabaseClient = SupabaseClient(supabaseURL: url, supabaseKey: key)
        
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

