import SwiftUI
import Supabase
import GoogleSignIn
import CryptoKit

struct ContentView: View {
    @State private var isSignedIn = false // State to track sign-in status
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            if isSignedIn {
                // Navigate to the home page after sign-in
                HomeView()
            } else {
                VStack {
                    // Logo at the top
                    if let image = UIImage(named: "latinnect") {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200, height: 200)
                            .padding(.bottom, 50)
                    } else {
                        Text("Image not found")
                    }
                    
                    // Sign in with Google button
                    Button(action: {
                        signInWithGoogle()
                    }) {
                        HStack {
                            Image(systemName: "person.crop.circle.fill") // Google profile-like icon
                                .font(.title)
                            Text("Sign in with Google")
                                .font(.headline)
                        }
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .padding()
                        .foregroundColor(.white)
                        .background(Color.blue)
                        .cornerRadius(10)
                        .padding(.horizontal, 20)
                    }
                    if let errorMessage = errorMessage {
                        Text("Error: \(errorMessage)")
                            .foregroundColor(.red)
                            .padding(.top, 10)
                    }
                }
                .background(Color.white.ignoresSafeArea()) // Background color
            }
        }
    }

    func signInWithGoogle() {
        guard let presentingVC = UIApplication.shared.windows.first?.rootViewController else {
            print("No presenting view controller")
            return
        }

        // Generate a nonce
        let nonce = generateNonce()
        let hashedNonce = hashNonce(nonce)

        GIDSignIn.sharedInstance.signIn(withPresenting: presentingVC) { signInResult, error in
            if let error = error {
                print("Error signing in with Google: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.errorMessage = "Google Sign-In failed: \(error.localizedDescription)"
                }
                return
            }

            guard let user = signInResult?.user, let idToken = user.idToken?.tokenString else {
                print("No user or ID token found in sign-in result.")
                DispatchQueue.main.async {
                    self.errorMessage = "No user or ID token found."
                }
                return
            }

            let accessToken = user.accessToken.tokenString

            // Authenticate with Supabase using the ID token and the generated nonce
            Task {
                do {
                    let credentials = OpenIDConnectCredentials(
                        provider: .google,
                        idToken: idToken,
                        accessToken: accessToken,
                        nonce: nonce // Pass the un-hashed nonce here to Supabase
                    )

                    
                    var sharedSupabaseClient: SupabaseClient!
                    let url = URL(string: "https://qygphqztgfypivmlqtaj.supabase.co")!
                    let key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF5Z3BocXp0Z2Z5cGl2bWxxdGFqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mjc1NjI4NTgsImV4cCI6MjA0MzEzODg1OH0.7l_g2RRthoa4KoYH__SLcvTgKD-xLUsxKIHJPrnaU1c"
                    sharedSupabaseClient = SupabaseClient(supabaseURL: url, supabaseKey: key)
                    
                    // Sign in to Supabase
                    try await sharedSupabaseClient.auth.signInWithIdToken(credentials: credentials)
                    print("Successfully signed in with Supabase!")

                    DispatchQueue.main.async {
                        self.isSignedIn = true // Update state on the main thread
                    }
                } catch {
                    print("Error signing in with Supabase: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        self.errorMessage = "Error signing in with Supabase: \(error.localizedDescription)"
                    }
                }
            }
        }
    }
    
    // Function to generate a cryptographically secure nonce
    func generateNonce(length: Int = 32) -> String {
        let characters = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._"
        return String((0..<length).map { _ in characters.randomElement()! })
    }
    func hashNonce(_ nonce: String) -> String {
        let inputData = Data(nonce.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap { String(format: "%02x", $0) }.joined()
        return hashString
    }
}

struct HomeView: View {
    var body: some View {
        TabView {
            VendorView()
                .tabItem {
                    Image(systemName: "building.2.crop.circle")
                    Text("Vendor")
                }

            MarketView()
                .tabItem {
                    Image(systemName: "cart")
                    Text("Market")
                }

            TaskView()
                .tabItem {
                    Image(systemName: "checkmark.circle")
                    Text("Task")
                }

            ProfileView()
                .tabItem {
                    Image(systemName: "person.circle")
                    Text("Profile")
                }
        }
    }
}

struct VendorView: View {
    var body: some View {
        Text("Vendor Page")
            .font(.largeTitle)
    }
}

struct MarketView: View {
    var body: some View {
        Text("Market Page")
            .font(.largeTitle)
    }
}

struct TaskView: View {
    var body: some View {
        Text("Task Page")
            .font(.largeTitle)
    }
}

struct ProfileView: View {
    var body: some View {
        Text("Profile Page")
            .font(.largeTitle)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
