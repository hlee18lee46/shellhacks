import SwiftUI
import GoogleSignIn
import Supabase

// SupabaseManager for managing database client (make sure this exists in your project)
class SupabaseManager {
    static let shared = SupabaseManager()

    private init() {}

    let supabaseClient = SupabaseClient(supabaseURL: URL(string: "https://qygphqztgfypivmlqtaj.supabase.co")!,
                                        supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF5Z3BocXp0Z2Z5cGl2bWxxdGFqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mjc1NjI4NTgsImV4cCI6MjA0MzEzODg1OH0.7l_g2RRthoa4KoYH__SLcvTgKD-xLUsxKIHJPrnaU1c")
}

// Define a structure to match the table schema in Supabase
struct User: Encodable {
    let email: String
}

// Define async function to insert user data
func createUserData(email: String) async throws {
    let supabase = SupabaseManager.shared.supabaseClient
    let user = User(email: email)
    
    // Inserting data into the "users" table using async/await
    let response = try await supabase
        .from("user") // Ensure your table name is correct
        .insert(user)
        .execute()

    print("Insert success: \(response)")
}


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
                print("Signed in user: \(user.profile?.email ?? "No Email")")
                errorMessage = nil // Clear error on success
                let userEmail = user.profile?.email ?? "Unknown email"
                Task {
                    do {
                        try await createUserData(email: userEmail)
                    } catch {
                        print("Error inserting user: \(error.localizedDescription)")
                    }
                }
                // Perform any CRUD operation using the email
                // Example: Insert user data

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

            SellView()
                .tabItem {
                    Image(systemName: "checkmark.circle")
                    Text("Sell")
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

// Define the product structure
struct Product: Identifiable, Codable {
    var id: UUID { UUID() } // You can replace this with your own unique ID field
    let item: String
    let quantity: String // As the database shows quantity as varchar
    let industry: String
    let email: String
    let supply: String
    let price: String
}



// Create a view to display the market items
class MarketViewModel: ObservableObject {
    @Published var products: [Product] = []
    @Published var isLoading = true
    @Published var errorMessage: String? = nil

    let supabase = SupabaseManager.shared.supabaseClient

    init() {
        Task {
            await fetchProducts()
        }
    }

    // Fetch the data from Supabase
    func fetchProducts() async {
        do {
            // Fetch data from Supabase
            let response = try await supabase
                .from("product")
                .select("*")
                .execute()

            let jsonData = response.data

            // Decode response into array of Product
            let products = try JSONDecoder().decode([Product].self, from: jsonData)
            self.products = products

            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
}

struct MarketView: View {
    @StateObject private var viewModel = MarketViewModel()

    var body: some View {
        NavigationView {
            if viewModel.isLoading {
                ProgressView("Loading...")
            } else if let errorMessage = viewModel.errorMessage {
                Text("Error: \(errorMessage)")
                    .foregroundColor(.red)
            } else {
                ScrollView {
                    LazyVStack(spacing: 20) {
                        ForEach(viewModel.products) { product in
                            ProductCardView(product: product)
                        }
                    }
                    .padding()
                }
                .navigationTitle("Mercado")
            }
        }
    }
}


// Define the product card view
struct ProductCardView: View {
    let product: Product

    var body: some View {
        VStack(alignment: .leading) {
            Text(product.item)
                .font(.headline)
                .padding(.bottom, 2)

            HStack {
                Text("Quantity: \(product.quantity)")
                Spacer()
                Text("Industry: \(product.industry)")
            }
            .font(.subheadline)
            .padding(.bottom, 2)

            HStack {
                Text("Email: \(product.email)")
                    .foregroundColor(.blue)
                Spacer()
                Text("Supply: \(product.supply)")
            }
            .font(.subheadline)
            .padding(.bottom, 2)

            // New line to display price
            HStack {
                Text("Price: \(product.price)")
                    .font(.subheadline)
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white).shadow(radius: 5))
        .padding(.horizontal)
    }
}

struct MarketView_Previews: PreviewProvider {
    static var previews: some View {
        MarketView()
    }
}

struct SellView: View {
    @State private var item: String = ""
    @State private var quantity: String = ""
    @State private var industry: String = ""
    @State private var email: String = ""
    @State private var supply: String = ""
    @State private var price: String = "" // New state for price
    
    @State private var statusMessage: String? = nil

    var body: some View {
        VStack(spacing: 20) {
            Text("Sell Your Product")
                .font(.title)
                .bold()
                .padding()

            TextField("Item", text: $item)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            TextField("Quantity", text: $quantity)
                .keyboardType(.numberPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            TextField("Industry", text: $industry)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            TextField("Email", text: $email)
                .keyboardType(.emailAddress)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            TextField("Supply", text: $supply)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            TextField("Price", text: $price) // New TextField for price input
                .keyboardType(.decimalPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            Button(action: {
                Task {
                    await uploadItem()
                }
            }) {
                Text("Sell Item")
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .padding(.bottom, 50) // Add extra padding to avoid overlap with nav bar
            }
            


            if let statusMessage = statusMessage {
                Text(statusMessage)
                    .foregroundColor(statusMessage.contains("Error") ? .red : .green)
                    .padding()
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom) // Avoids keyboard overlap
        .padding(.top, 50)
    }

    // Function to upload the item to Supabase
    func uploadItem() async {
        guard !item.isEmpty, !quantity.isEmpty, !industry.isEmpty, !email.isEmpty, !supply.isEmpty, !price.isEmpty else {
            statusMessage = "All fields are required."
            return
        }

        let supabase = SupabaseManager.shared.supabaseClient

        do {
            let response = try await supabase
                .from("product") // Your Supabase table
                .insert([
                    "item": item,
                    "quantity": quantity,
                    "industry": industry,
                    "email": email,
                    "supply": supply,
                    "price": price // Insert the new price field
                ])
                .execute()

            if response.status == 201 || response.status == 204 {
                statusMessage = "Item uploaded successfully!"
                clearForm()
            } else {
                statusMessage = "Failed to upload item."
            }
        } catch {
            statusMessage = "Error: \(error.localizedDescription)"
        }
    }

    // Clear the form after successful submission
    func clearForm() {
        item = ""
        quantity = ""
        industry = ""
        email = ""
        supply = ""
        price = "" // Clear the price field as well
    }
}



struct ProfileView: View {
    @State private var email: String = ""
    @State private var name: String = ""
    @State private var industry: String = ""
    @State private var state: String = ""
    @State private var city: String = ""
    @State private var address: String = ""
    
    // Placeholder for success/error messages
    @State private var statusMessage: String = ""

    var body: some View {
        VStack(spacing: 20) {
            TextField("Email", text: $email)
                .disabled(true) // Assuming email is immutable

            TextField("Name", text: $name)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            TextField("Industry", text: $industry)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            TextField("State", text: $state)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            TextField("City", text: $city)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            TextField("Address", text: $address)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            Button(action: updateProfile) {
                Text("Submit")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            
            // Display status message
            Text(statusMessage)
                .foregroundColor(statusMessage.contains("Error") ? .red : .green)
                .padding()
        }
        .padding()
        .onAppear(perform: fetchProfile)
    }
    
    // Fetch the user's profile from Supabase
    func fetchProfile() {
        let supabase = SupabaseManager.shared.supabaseClient
        let userEmail = "phocle4@gmail.com" // Replace with the actual user email

        Task {
            do {
                // Attempt to fetch user profile by email
                let response = try await supabase
                    .from("user")
                    .select("*")
                    .eq("email", value: userEmail)
                    .limit(1) // Limit the result to one row if multiple exist
                    .execute()
                
                // Ensure the response is correctly parsed
                if let json = try? JSONSerialization.jsonObject(with: response.data, options: []),
                   let dataArray = json as? [[String: Any]],
                   let data = dataArray.first {
                    // Populate fields with fetched data
                    email = data["email"] as? String ?? ""
                    name = data["name"] as? String ?? ""
                    industry = data["industry"] as? String ?? ""
                    state = data["state"] as? String ?? ""
                    city = data["city"] as? String ?? ""
                    address = data["address"] as? String ?? ""
                } else {
                    statusMessage = "No profile found for this user"
                }
            } catch {
                print("Error fetching profile: \(error)")
                statusMessage = "Error fetching profile"
            }
        }
    }
    
    // Update the user's profile in Supabase
    func updateProfile() {
        let supabase = SupabaseManager.shared.supabaseClient
        let userEmail = "example@example.com" // Replace with the actual user email

        Task {
            do {
                // Perform the update query
                let response: PostgrestResponse<Void> = try await supabase
                    .from("user")
                    .update([
                        "industry": industry,
                        "state": state,
                        "city": city,
                        "address": address,
                        "name": name

                    ])
                    .eq("email", value: userEmail) // Ensure the email field is used to find the user
                    .execute()

                // Check for successful status codes (200 or 204)
                if response.status == 200 || response.status == 204 {
                    statusMessage = "Profile updated successfully!"
                    print("Update success, response status: \(response.status)")
                } else {
                    print("Unexpected response status: \(response.status), response: \(response)")
                    statusMessage = "Unexpected response: \(response.status)"
                }
            } catch {
                // Handle the duplicate key error (pkey violation)
                if let error = error as? PostgrestError, error.code == "23505" {
                    print("Error: Duplicate key violation: \(error.message)")
                    statusMessage = "Duplicate key violation: Cannot modify primary key (email)."
                } else {
                    // Handle general error
                    print("Error updating profile: \(error.localizedDescription)")
                    statusMessage = "Error updating profile"
                }
            }
        }
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
