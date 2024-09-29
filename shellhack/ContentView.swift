import SwiftUI
import GoogleSignIn

struct ContentView: View {
    var body: some View {
        VStack {
            // Logo at the top
            Image("latinnect")
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200) // Adjust size as necessary
                .padding(.bottom, 50)

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
        }
        .background(Color.white.ignoresSafeArea()) // Background color
    }

    func signInWithGoogle() {
        guard let presentingVC = UIApplication.shared.windows.first?.rootViewController else {
            print("No presenting view controller")
            return
        }

        GIDSignIn.sharedInstance.signIn(
            withPresenting: presentingVC
        ) { signInResult, error in
            if let error = error {
                print("Error signing in: \(error.localizedDescription)")
                return
            }

            if let user = signInResult?.user {
                print("Signed in user: \(user.profile?.name ?? "No name")")
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
