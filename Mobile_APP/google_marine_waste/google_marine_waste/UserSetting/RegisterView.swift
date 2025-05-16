import SwiftUI

struct RegisterView: View {
    @Binding var username: String
    @Binding var isLoggedIn: Bool
    @Environment(\.presentationMode) var presentationMode

    @State private var inputUsername: String = ""
    @State private var password: String = ""
    @State private var role: String = "user" // Default role
    @State private var registrationFailed: Bool = false
    @State private var errorMessage: String = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("Register")
                .font(.largeTitle)
                .padding()

            TextField("Username", text: $inputUsername)
                .autocapitalization(.none)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)
                .padding(.horizontal)

            SecureField("Password", text: $password)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)
                .padding(.horizontal)

            Picker("User Type", selection: $role) {
                Text("Regular User").tag("user")
                Text("Organizer").tag("organizer")
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)

            if registrationFailed {
                Text("Registration Failed: \(errorMessage)")
                    .foregroundColor(.red)
                    .padding(.horizontal)
            }

            Button(action: {
                register()
            }) {
                Text("Confirm Registration")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .cornerRadius(10)
                    .padding(.horizontal)
            }

            Spacer()
        }
        .padding()
    }

    func register() {
        guard let url = URL(string: "\(AppConfig.baseURL)/api/register") else {
            print("Failed to create API URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "username": inputUsername,
            "password": password,
            "role": role
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: .fragmentsAllowed)

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async {
                    registrationFailed = true
                    errorMessage = "Network error, please try again later"
                    print("Network error: \(error?.localizedDescription ?? "Unknown error")")
                }
                return
            }

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                do {
                    let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                    DispatchQueue.main.async {
                        // Registration successful, update login status and return to the main screen
                        username = inputUsername
                        isLoggedIn = true
                        presentationMode.wrappedValue.dismiss() // Close the registration page
                        print("Registration successful, automatically logged in: \(username)")
                    }
                } catch {
                    DispatchQueue.main.async {
                        registrationFailed = true
                        errorMessage = "Response parsing error"
                        print("Response parsing error: \(error.localizedDescription)")
                    }
                }
            } else {
                DispatchQueue.main.async {
                    registrationFailed = true
                    do {
                        let errorResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                        errorMessage = errorResponse?["message"] as? String ?? "Registration failed, please try again later"
                    } catch {
                        errorMessage = "Unknown error, please try again later"
                    }
                    print("Registration failed: \(String(data: data, encoding: .utf8) ?? "Unknown error")")
                }
            }
        }.resume()
    }
}
