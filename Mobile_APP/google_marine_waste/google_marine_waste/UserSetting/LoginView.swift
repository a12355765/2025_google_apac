//
//  LoginView.swift
//  google_marine_waste
//
//  Created by jong on 2025/5/12.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

import SwiftUI

struct LoginView: View {
    @Binding var username: String
    @Binding var isLoggedIn: Bool
    @Binding var userRole: String
    @Binding var userId: String
    @Environment(\.presentationMode) var presentationMode
    
    @State private var inputUsername: String = ""
    @State private var password: String = ""
    @State private var loginFailed: Bool = false
    @State private var errorMessage: String = ""
    @State private var showRegisterView: Bool = false // 控制是否顯示註冊頁面
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Login")
                .font(.largeTitle)
                .padding()
            
            TextField("UserName", text: $inputUsername)
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
            
            if loginFailed {
                Text("Login failed: \(errorMessage)")
                    .foregroundColor(.red)
                    .padding(.horizontal)
            }
            
            Button(action: {
                signIn()
            }) {
                Text("Confirm Login")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
                    .padding(.horizontal)
            }
            
            Button(action: {
                showRegisterView = true // 顯示註冊頁面
            }) {
                Text("Register New Account")
                    .font(.headline)
                    .foregroundColor(.blue)
                    .padding(.top, 10)
            }
            .sheet(isPresented: $showRegisterView) {
                RegisterView(username: $username, isLoggedIn: $isLoggedIn) // 跳轉到註冊畫面
            }
            
            Spacer()
        }
        .padding()
    }
    
    func signIn() {
        guard let url = URL(string: "\(AppConfig.baseURL)/api/login") else {
            print("Unable to create API URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "username": inputUsername,
            "password": password
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: .fragmentsAllowed)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async {
                    loginFailed = true
                    errorMessage = "Network error, please try again later"
                    print("Network error: \(error?.localizedDescription ?? "Unknown error")")
                }
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    do {
                        let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                        DispatchQueue.main.async {
                            if let role = jsonResponse?["role"] as? String,
                               let userId = jsonResponse?["user_id"] as? String {
                                username = inputUsername
                                isLoggedIn = true
                                loginFailed = false
                                presentationMode.wrappedValue.dismiss() // 關閉登入頁面
                                
                                // 儲存登入資訊
                                UserDefaults.standard.set(inputUsername, forKey: "username")
                                UserDefaults.standard.set(true, forKey: "isLoggedIn")
                                UserDefaults.standard.set(role, forKey: "userRole") // 儲存使用者角色
                                UserDefaults.standard.set(userId, forKey: "user_id") // 儲存 user_id
                                print("User logged in: \(username), Role: \(role), user_id: \(userId)")
                            }
                        }
                    } catch {
                        DispatchQueue.main.async {
                            loginFailed = true
                            errorMessage = "Response parsing error"
                            print("Response parsing error: \(error.localizedDescription)")
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        loginFailed = true
                        do {
                            let errorResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                            errorMessage = errorResponse?["message"] as? String ?? "Login failed, please check your username or password"
                        } catch {
                            errorMessage = "Unknown error, please try again later"
                        }
                        print("Login failed: \(String(data: data, encoding: .utf8) ?? "Unknown error")")
                    }
                }
            }
        }
        task.resume()
    }
}
