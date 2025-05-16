import SwiftUI
import PhotosUI

struct UserDexEntry: Identifiable {
    let id: String // 海廢的唯一 ID
    let name: String // 海廢名稱
    let imageUrl: String // 圖鑑圖片 URL
    var unlocked: Bool // 是否已解鎖
}

struct WasteRecognitionView: View {
    @State private var selectedImage: UIImage? = nil
    @State private var isImagePickerPresented = false
    @State private var isCameraPresented = false
    @State private var recognitionResult: String? = nil
    @State private var isRecognizing = false
    @State private var errorMessage: String? = nil
    @Binding var reset: Bool // 接收重置通知
    @Binding var userId: String
    
    var body: some View {
        VStack(spacing: 20) {
            // Title
            Text("Recognition")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 40)

            // Image display area
            ZStack {
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 250)
                        .cornerRadius(12)
                        .shadow(radius: 5)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 250)
                        .cornerRadius(12)
                        .overlay(
                            Text("Please select or capture an image")
                                .foregroundColor(.gray)
                        )
                }
            }

            // Action buttons
            HStack {
                Button(action: {
                    isCameraPresented = true
                }) {
                    Label("Take Photo", systemImage: "camera")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }

                Button(action: {
                    isImagePickerPresented = true
                }) {
                    Label("Choose Image", systemImage: "photo")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .padding(.horizontal)

            Button(action: {
                startRecognition()
            }) {
                Text("Start Recognition")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(selectedImage == nil ? Color.gray : Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(selectedImage == nil) // Disable button if no image is selected
            .padding(.horizontal)

            // Recognition result or error message
            if isRecognizing {
                ProgressView("Recognizing...")
                    .padding()
            } else if let result = recognitionResult {
                ResultView(title: "Recognition Result:", message: result, color: .blue)
            } else if let error = errorMessage {
                ResultView(title: "Error:", message: error, color: .red)
            }

            Spacer()
        }
        .padding()
        .sheet(isPresented: $isImagePickerPresented) {
            ImagePicker(sourceType: .photoLibrary) { image in
                selectedImage = image
            }
        }
        .sheet(isPresented: $isCameraPresented) {
            ImagePicker(sourceType: .camera) { image in
                selectedImage = image
            }
        }
        // 添加背景
        .background(
            ZStack {
                // 漸層背景
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.2), Color.cyan.opacity(0.05)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                // 海洋裝飾圖案
                
                Image(systemName: "tortoise.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .opacity(0.3)
                    .offset(x: 150, y: 200)
            }
        )
    }

    // Recognition function connected to the backend Gemini AI
    func startRecognition() {
        guard let image = selectedImage else { return }
        isRecognizing = true
        recognitionResult = nil
        errorMessage = nil

        // Convert image to JPEG data
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            isRecognizing = false
            errorMessage = "Image processing failed. Please try again."
            return
        }

        // Create URL request
        guard let url = URL(string: "\(AppConfig.baseURL)/api/analyze_trash") else {
            isRecognizing = false
            errorMessage = "Failed to create request. Please check the API URL."
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(userId)", forHTTPHeaderField: "Authorization") // Add authorization header

        // Create multipart/form-data request
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        // Add image data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)

        // End marker
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        // Send request
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isRecognizing = false
                if let error = error {
                    errorMessage = "Recognition failed: \(error.localizedDescription)"
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                    errorMessage = "Server error. Please try again later."
                    return
                }

                guard let data = data else {
                    errorMessage = "No response from the server."
                    return
                }

                do {
                    // Assuming the backend returns the following JSON structure:
                    // {
                    //   "success": true,
                    //   "detected": "Plastic Bottle",
                    //   "unlocked_id": "001",
                    //   "unlocked_name": "Plastic Bottle",
                    //   "unlocked_image": "/static/dex/001.png"
                    // }
                    struct RecognitionResponse: Decodable {
                        let success: Bool
                        let detected: String?
                    }

                    let response = try JSONDecoder().decode(RecognitionResponse.self, from: data)

                    if response.success, let result = response.detected {
                        recognitionResult = result
                    } else {
                        errorMessage = "Recognition failed. Please try again later."
                    }
                } catch {
                    errorMessage = "Failed to parse server response: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
}

// Custom button component
struct ActionButton: View {
    let label: String
    let systemImage: String? = nil
    let color: Color
    let isDisabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            if let systemImage = systemImage {
                Label(label, systemImage: systemImage)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(color)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            } else {
                Text(label)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(color)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .disabled(isDisabled)
    }
}

// Custom result display component
struct ResultView: View {
    let title: String
    let message: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundColor(color)
            Text(message)
                .font(.body)
                .foregroundColor(color)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

// Custom image picker
struct ImagePicker: UIViewControllerRepresentable {
    var sourceType: UIImagePickerController.SourceType
    var onImagePicked: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImagePicked(image)
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
