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
            func fetchProducts() {
                let supabase = SupabaseManager.shared.supabaseClient

                Task {
                    do {
                        // Fetching data from Supabase (make sure to match your table and fields)
                        let response = try await supabase
                            .from("product")
                            .select("*")
                            .execute()
                        
                        // Use response.data directly
                        let jsonData = response.data
                        
                        // Decode response to array of products
                        let products = try JSONDecoder().decode([Product].self, from: jsonData)
                        self.products = products
                        
                        isLoading = false
                    } catch {
                        errorMessage = error.localizedDescription
                        isLoading = false
                    }
                }
            }

            // Signed in successfully
            if let user = signInResult?.user {
                print("Signed in user: \(user.profile?.name ?? "No name")")
            }
        }
    }
}
