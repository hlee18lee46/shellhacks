import SwiftUI
import GoogleSignIn

struct ContentView: View {
    @State private var isSignedIn = false
    @State private var errorMessage: String? = nil

    var body: some View {
        if isSignedIn {
            HomeView() // Navigate to HomeView once signed in
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

                // Show error message if any
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding(.bottom, 20)
                }

                // Sign in with Google button
                Button(action: {
                    signInWithGoogle()
                }) {
                    HStack {
                        Image(systemName: "person.crop.circle.fill")
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
                .disabled(isSignedIn) // Disable button after sign-in
            }
            .background(Color.white.ignoresSafeArea())
        }
    }

    func signInWithGoogle() {
        guard let presentingVC = UIApplication.shared.windows.first?.rootViewController else {
            errorMessage = "No presenting view controller"
            return
        }

        GIDSignIn.sharedInstance.signIn(
            withPresenting: presentingVC
        ) { signInResult, error in
            if let error = error {
                errorMessage = "Error signing in: \(error.localizedDescription)"
                return
            }

            if let user = signInResult?.user {
                isSignedIn = true
                print("Signed in user: \(user.profile?.name ?? "No name")")
                errorMessage = nil // Clear error on success
            }
        }
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
