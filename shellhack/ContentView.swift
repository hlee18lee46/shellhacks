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
struct User: Codable { // Conforms to both Encodable and Decodable
    let email: String
    let name: String? // Optional fields
    let industry: String?
}

// Define a product structure to match the product schema in Supabase

struct Product: Identifiable, Codable {
    let id: String // The 'id' field is explicitly provided in the response
    let item: String
    let quantity: String // The database shows quantity as varchar
    let industry: String
    let email: String
    let supply: String?
    let price: String
}



// Define async function to insert user data
func createUserData(email: String) async throws {
    let supabase = SupabaseManager.shared.supabaseClient

    do {
        // Step 1: Check if user already exists in the "user" table
        let existingUserResponse = try await supabase
            .from("user")
            .select("*")
            .eq("email", value: email)
            .execute()

        // Decode the response to check if the user exists
        if let existingUsers = try? JSONDecoder().decode([User].self, from: existingUserResponse.data),
           !existingUsers.isEmpty {
            // User already exists, skip insertion
            print("User already exists with email: \(email)")
            return
        }

        // Step 2: If user does not exist, insert new user data
        let user = User(email: email, name: nil, industry: nil) // Adjust fields as necessary
        let insertResponse = try await supabase
            .from("user")
            .insert(user)
            .execute()

        print("Insert success: \(insertResponse)")
        
    } catch {
        // Handle any errors that occur during the insertion process
        print("Error inserting user: \(error.localizedDescription)")
    }
}


struct ContentView: View {
    @State private var isSignedIn = false
    @State private var errorMessage: String? = nil

    var body: some View {
        if isSignedIn {
            HomeView() // Navigate to HomeView once signed in
        } else {
            VStack {
                Text("Connect Latine")
                    .font(.system(size: 28, weight: .bold)) // Larger, bold font
                    .padding(.bottom, 20) // Space between text and logo
                // Logo at the top
                if let image = UIImage(named: "latinnect") {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 260, height: 260)
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

// Define a Vendor structure to match the fields in your user table
struct Vendor: Identifiable, Codable {
    var id: String { email } // Use email as the unique identifier
    let email: String
    let industry: String
    let state: String
    let city: String
    let address: String
    let name: String
}

// View model for fetching vendors from the user table in Supabase
class VendorViewModel: ObservableObject {
    @Published var vendors: [Vendor] = []
    @Published var isLoading = true
    @Published var errorMessage: String? = nil

    let supabase = SupabaseManager.shared.supabaseClient

    init() {
        Task {
            await fetchVendors(industry: "All") // Fetch all vendors initially
        }
    }

    // Fetch the data from Supabase based on industry
    func fetchVendors(industry: String) async {
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
            print("Fetching vendors for industry: \(industry)")
        }

        do {
            var query = supabase
                .from("user") // This is the updated table name (user)
                .select("*")

            // Apply industry filter if necessary
            if industry != "All" {
                query = query.eq("industry", value: industry)
            }

            // Execute the query and fetch vendors
            let response = try await query.execute()

            // Print the raw response for debugging
            if let rawData = String(data: response.data, encoding: .utf8) {
                print("Raw response data: \(rawData)")
            }

            // Decode response into array of Vendor
            let vendors = try JSONDecoder().decode([Vendor].self, from: response.data)

            // Update UI state on the main thread after fetching data
            DispatchQueue.main.async {
                self.vendors = vendors
                self.isLoading = false // Set isLoading to false after data is fetched
                print("Successfully fetched vendors: \(self.vendors.count) items")
            }
        } catch {
            // Handle errors and update UI on the main thread
            DispatchQueue.main.async {
                self.errorMessage = "Error fetching vendors: \(error.localizedDescription)"
                self.isLoading = false // Set isLoading to false after error
                print("Error fetching vendors: \(error.localizedDescription)")
            }
        }
    }
}

// VendorView UI to display vendors
struct VendorView: View {
    @StateObject private var viewModel = VendorViewModel()

    @State private var selectedIndustry: String = "All" // Default to no filter
    let industries = ["All", "Food", "Construction", "Others"]

    var body: some View {
        NavigationView {
            VStack(spacing: 10) { // Adjusted spacing between elements
                // Title and View button in the same row
                HStack {
                    Text("Vendors")
                        .font(.system(size: 24, weight: .bold)) // Adjusted font size
                    Spacer()
                    Button(action: {
                        Task {
                            await viewModel.fetchVendors(industry: selectedIndustry)
                        }
                    }) {
                        Text("View")
                            .font(.system(size: 16, weight: .semibold))
                            .padding(8)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 16) // Minimized horizontal padding for a compact view
                .padding(.top, 10) // Minimal top padding

                // Filter Picker
                Picker("Select Industry", selection: $selectedIndustry) {
                    ForEach(industries, id: \.self) { industry in
                        Text(industry)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal, 16) // Adjusted horizontal padding
                .padding(.bottom, 10) // Reduced padding below picker

                // Show loading indicator or error
                if viewModel.isLoading {
                    ProgressView("Loading...") // Show loading indicator when data is being fetched
                } else if let errorMessage = viewModel.errorMessage {
                    Text("Error: \(errorMessage)")
                        .foregroundColor(.red)
                        .padding(.horizontal, 16)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 15) { // Reduced space between cards
                            ForEach(viewModel.vendors) { vendor in
                                VendorCardView(vendor: vendor)
                            }
                        }
                        .padding(.horizontal, 16) // Added padding to the sides of the cards
                    }
                }
            }
        }
    }
}

// Define the vendor card view
struct VendorCardView: View {
    let vendor: Vendor

    var body: some View {
        VStack(alignment: .leading) {
            Text(vendor.name)
                .font(.headline)
                .padding(.bottom, 2)

            HStack {
                Text("Industry: \(vendor.industry)")
                Spacer()
                Text("City: \(vendor.city), \(vendor.state)")
            }
            .font(.subheadline)
            .padding(.bottom, 2)

            HStack {
                Text("Address: \(vendor.address)")
                Spacer()
                Text("Email: \(vendor.email)")
                    .foregroundColor(.blue)
            }
            .font(.subheadline)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white).shadow(radius: 5))
        .padding(.horizontal)
    }
}



struct VendorView_Previews: PreviewProvider {
    static var previews: some View {
        VendorView()
    }
}

class MarketViewModel: ObservableObject {
    @Published var products: [Product] = []
    @Published var isLoading = true
    @Published var errorMessage: String? = nil

    let supabase = SupabaseManager.shared.supabaseClient

    init() {
        Task {
            await fetchProducts(industry: "All") // Fetch all products initially
        }
    }

    // Fetch the data from Supabase based on industry
    func fetchProducts(industry: String) async {
        // Ensure updates happen on the main thread
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
            print("Fetching products for industry: \(industry)")
        }

        do {
            var query = supabase
                .from("product")
                .select("*")

            // Apply industry filter if necessary
            if industry != "All" {
                query = query.eq("industry", value: industry)
            }

            // Execute the query and fetch products
            let response = try await query.execute()

            // Print the raw response to ensure data integrity
            if let rawData = String(data: response.data, encoding: .utf8) {
                print("Raw response data: \(rawData)")
            }

            // Decode response into array of Product
            let products = try JSONDecoder().decode([Product].self, from: response.data)

            // Update UI state on the main thread after fetching data
            DispatchQueue.main.async {
                self.products = products
                self.isLoading = false // Set isLoading to false after data is fetched
                print("Successfully fetched products: \(self.products.count) items")
            }
        } catch {
            // Handle errors and update UI on the main thread
            DispatchQueue.main.async {
                self.errorMessage = "Error fetching products: \(error.localizedDescription)"
                self.isLoading = false // Set isLoading to false after error
                print("Error fetching products: \(error.localizedDescription)")
            }
        }
    }
}

// MarketView UI to display products
struct MarketView: View {
    @StateObject private var viewModel = MarketViewModel()

    @State private var selectedIndustry: String = "All" // Default to no filter
    let industries = ["All", "Food", "Construction", "Others"]

    var body: some View {
        NavigationView {
            VStack(spacing: 10) { // Adjusted spacing between elements
                // Title and View button in the same row
                HStack {
                    Text("Market")
                        .font(.system(size: 24, weight: .bold)) // Adjusted font size
                    Spacer()
                    Button(action: {
                        Task {
                            await viewModel.fetchProducts(industry: selectedIndustry)
                        }
                    }) {
                        Text("View")
                            .font(.system(size: 16, weight: .semibold))
                            .padding(8)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 16) // Minimized horizontal padding for a compact view
                .padding(.top, 10) // Minimal top padding

                // Filter Picker
                Picker("Select Industry", selection: $selectedIndustry) {
                    ForEach(industries, id: \.self) { industry in
                        Text(industry)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal, 16) // Adjusted horizontal padding
                .padding(.bottom, 10) // Reduced padding below picker

                // Show loading indicator or error
                if viewModel.isLoading {
                    ProgressView("Loading...") // Show loading indicator when data is being fetched
                } else if let errorMessage = viewModel.errorMessage {
                    Text("Error: \(errorMessage)")
                        .foregroundColor(.red)
                        .padding(.horizontal, 16)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 15) { // Reduced space between cards
                            ForEach(viewModel.products) { product in
                                ProductCardView(product: product)
                            }
                        }
                        .padding(.horizontal, 16) // Added padding to the sides of the cards
                    }
                }
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
        VStack(spacing: 10) { // Reduced spacing between elements
            // Title with reduced font size and padding
            Text("Sell Your Product")
                .font(.system(size: 24, weight: .bold)) // Smaller font size
                .padding(.top, 16) // Adjusted top padding

            // TextFields with reduced padding, height and rounded border
            Group {
                TextField("Item", text: $item)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(height: 35) // Adjusted height
                    .padding(.horizontal, 16)

                TextField("Quantity", text: $quantity)
                    .keyboardType(.numberPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(height: 35) // Adjusted height
                    .padding(.horizontal, 16)

                TextField("Industry", text: $industry)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(height: 35) // Adjusted height
                    .padding(.horizontal, 16)

                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(height: 35) // Adjusted height
                    .padding(.horizontal, 16)

                TextField("Supply", text: $supply)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(height: 35) // Adjusted height
                    .padding(.horizontal, 16)

                TextField("Price", text: $price) // TextField for price input
                    .keyboardType(.decimalPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(height: 35) // Adjusted height
                    .padding(.horizontal, 16)
            }
            .padding(.top, 8) // Adjusted spacing between the title and the fields

            // Sell button with adjusted padding and smaller size
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
                    .padding(.horizontal, 16)
            }
            .padding(.bottom, 20) // Extra padding at the bottom to avoid nav bar overlap

            // Status message for success or error
            if let statusMessage = statusMessage {
                Text(statusMessage)
                    .foregroundColor(statusMessage.contains("Error") ? .red : .green)
                    .padding(.top, 8)
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom) // Avoids keyboard overlap
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
                Text("Modify")
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
