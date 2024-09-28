import SwiftUI
import PhotosUI

struct ContentView: View {
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImageData: Data? = nil
    @State private var ingredients: String = "Analyzing..."
    
    var body: some View {
        VStack {
            if let selectedImageData = selectedImageData,
               let uiImage = UIImage(data: selectedImageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
            } else {
                Rectangle()
                    .fill(Color.gray)
                    .frame(height: 200)
            }
            
            PhotosPicker(
                selection: $selectedItem,
                matching: .images,
                photoLibrary: .shared()) {
                    Text("Select Image")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .onChange(of: selectedItem) { newItem in
                    Task {
                        if let data = try? await newItem?.loadTransferable(type: Data.self) {
                            selectedImageData = data
                        }
                    }
                }
            
            Button("Analyze Image") {
                if let imageData = selectedImageData {
                    analyzeImage(base64Image: imageData.base64EncodedString())
                }
            }
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(10)
            
            Text(ingredients)
                .padding()
        }
    }
    
    func analyzeImage(base64Image: String) {
        // OpenAI API URL
        let apiUrl = "https://api.openai.com/v1/chat/completions"
        let apiKey = "your-openai-api-key"
        
        // Prepare the payload for OpenAI API
        let prompt = "Can you return a list of ingredients in the fridge as a JSON object?"
        let payload: [String: Any] = [
            "model": "gpt-4-vision-preview",
            "messages": [
                ["role": "user", "content": prompt],
                ["type": "image", "image_url": "data:image/jpeg;base64,\(base64Image)"]
            ],
            "max_tokens": 300
        ]
        
        guard let url = URL(string: apiUrl) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: payload, options: [])
            request.httpBody = jsonData
        } catch {
            print("Error encoding JSON")
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("Error in network request")
                return
            }
            
            if let responseData = try? JSONDecoder().decode(OpenAIResponse.self, from: data) {
                DispatchQueue.main.async {
                    self.ingredients = responseData.choices.first?.message.content ?? "No ingredients found"
                }
            }
        }
        task.resume()
    }
}

// Define OpenAI API Response Model
struct OpenAIResponse: Codable {
    struct Choice: Codable {
        struct Message: Codable {
            let content: String
        }
        let message: Message
    }
    let choices: [Choice]
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
