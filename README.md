##Inspiration

The inspiration for Latinnect came from our passion to support small businesses in the Latine community by giving them a platform to connect with customers and other vendors. We noticed a gap in the digital marketplace, where many small, local Latine vendors struggle to showcase their products and reach broader audiences. We wanted to create a solution that empowers these businesses and celebrates Latine culture.

##What it does

Latinnect is a digital marketplace that connects Latine vendors with customers, allowing vendors to easily list and manage their products, and customers to browse, filter, and purchase goods. Users can filter products by industry (e.g., Food, Construction, Others) and see detailed information such as item name, quantity, supply, and price. Vendors can easily upload product details directly from the app, and customers can discover Latine-owned businesses.

##How we built it

SwiftUI for the iOS front-end, creating a user-friendly and responsive interface.
Supabase as the backend database to manage user data and product listings, leveraging its easy integration with Swift for real-time updates and data storage.
Google Sign-In for user authentication, allowing vendors to log in securely and manage their listings.
Challenges we ran into

One of the main challenges was handling real-time data syncing between the front-end and the Supabase backend. Ensuring that the app fetched the correct data based on user selections and updated the UI smoothly was tricky, especially when dealing with large datasets. We also faced some technical challenges with state management in SwiftUI, where the UI would not always update properly after data was fetched.

##Accomplishments that we're proud of

We’re proud of building a fully functional marketplace app that not only empowers small Latine businesses but also celebrates their culture. The integration of filtering by industry and real-time data fetching through Supabase was a major accomplishment. We’re also proud of how seamlessly vendors can upload their product details, making the platform user-friendly for both customers and business owners.

##What we learned

We learned a lot about integrating SwiftUI with third-party services like Supabase and Google Sign-In. Understanding how to handle real-time data synchronization and UI state management in SwiftUI was a key takeaway. We also gained insight into building for scalability, ensuring that our solution can grow as the vendor base and product listings increase.

##What's next for Latinnect

Expanding the platform to support additional industries beyond Food and Construction.
Building a recommendation system to help customers discover new vendors based on their preferences.
Integrating payment solutions to allow direct purchases through the app.
Creating a web version of the platform to increase accessibility for users without iOS devices.
