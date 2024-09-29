import UIKit
import GoogleSignIn

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func signInButtonTapped(_ sender: UIButton) {
        // Get current presenting view controller
        guard let presentingVC = self.presentingViewController else { return }
        
        // Trigger Google Sign-In flow
        GIDSignIn.sharedInstance.signIn(withPresenting: presentingVC) { signInResult, error in
            if let error = error {
                print("Error signing in: \(error)")
                return
            }

            // Signed in successfully
            if let user = signInResult?.user {
                print("Signed in user: \(user.profile?.name ?? "No name")")
            }
        }
    }
}
