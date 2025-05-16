//
//  ActivityListView.swift
//  google_marine_waste
//
//  Created by jong on 2025/5/5.
//

import SwiftUI

// 活動模型
struct Activity: Identifiable, Decodable {
    let id: String
    let title: String
    let description: String
    let location: String
    let datetime: String
    let menu: [String] // 活動菜單
}

// 活動列表頁面

struct ActivityListView: View {
    @Binding var username: String
    @Binding var reset: Bool // 接收重置通知
    @State private var activities: [Activity] = []
    @State private var isLoading = true
    @State private var showCreateEvent = false // 控制是否顯示建立活動頁面
    @AppStorage("userRole") private var userRole: String = "" // 儲存使用者角色
    @Binding var userId: String

    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading...")
                        .padding()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            ForEach(activities) { activity in
                                NavigationLink(destination: ActivityDetailView(activity: activity, userId: $userId, username: $username)) {
                                    ActivityBlockView(activity: activity)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Activity List")
            .toolbar {
                if userRole == "organizer" {
                    Button(action: {
                        showCreateEvent = true
                    }) {
                        Image(systemName: "plus")
                        Text("Add Activity")
                    }
                }
            }
            .onAppear(perform: fetchActivities)
            .sheet(isPresented: $showCreateEvent) {
                CreateEventView(username: $username, userId: $userId, onEventCreated: fetchActivities)
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
    }
    
    func fetchActivities() {
        guard let url = URL(string: "\(AppConfig.baseURL)/api/available_events") else { return }
        isLoading = true
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                if let data = data {
                    do {
                        struct ApiResponse: Decodable {
                            let success: Bool
                            let events: [Activity]
                        }
                        
                        let response = try JSONDecoder().decode(ApiResponse.self, from: data)
                        if response.success {
                            self.activities = response.events
                        } else {
                            print("Backend response failed")
                        }
                    } catch {
                        print("Failed to parse activity data: \(error)")
                    }
                } else if let error = error {
                    print("Failed to fetch activities: \(error)")
                }
            }
        }.resume()
    }
}

// 活動詳情頁面
struct ActivityDetailView: View {
    let activity: Activity
    @Binding var userId: String
    @Binding var username: String
    
    var body: some View {
        VStack {
            Text(activity.title)
                .font(.largeTitle)
                .padding(.top)
            
            Text(activity.datetime)
                .font(.title2)
                .padding(.top, 5)
            
            Text(activity.location)
                .font(.title3)
                .padding(.top, 5)
            
            Text(activity.description)
                .font(.body)
                .padding()
            
            Spacer()
            
            Button(action: {
                joinEvent(eventId: activity.id)
            }) {
                Text("Join Activity")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .cornerRadius(10)
            }
            .padding()
        }
        .navigationTitle("Activity Details")
    }
    
    // 報名活動
    func joinEvent(eventId: String) {
        guard let url = URL(string: "\(AppConfig.baseURL)/api/join_event") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(userId)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["event_id": eventId]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                let response = try? JSONSerialization.jsonObject(with: data, options: [])
                print("Join response: \(response ?? "Unable to parse")")
            } else if let error = error {
                print("Failed to join: \(error)")
            }
        }.resume()
    }
}

// 活動區塊視圖
struct ActivityBlockView: View {
    let activity: Activity
    
    var body: some View {
        HStack(spacing: 15) {
            // 左側示意圖
            Image("ocean_placeholder") // 請將 "ocean_placeholder" 替換為你的海洋圖片名稱
                .resizable()
                .scaledToFill()
                .frame(width: 80, height: 80) // 固定圖片大小
                .cornerRadius(10) // 圓角效果
                .clipped()
            
            // 右側活動內容
            VStack(alignment: .leading, spacing: 8) {
                Text(activity.title)
                    .font(.headline)
                    .padding(.top, 5)
                
                Text(activity.datetime)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(activity.location)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(activity.description)
                    .font(.body)
                    .lineLimit(2)
                    .padding(.top, 5)
            }
        }
        .padding()
        .frame(maxWidth: .infinity) // 寬度填滿
        .frame(height: 120) // 固定高度
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 5)
    }
}



// 建立活動頁面
struct CreateEventView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var username: String
    @Binding var userId: String
    @State private var title = ""
    @State private var description = ""
    @State private var location = ""
    @State private var selectedDate = Date()
    @State private var menu = ""
    @State private var showError = false // 是否顯示錯誤提示
    @State private var errorMessage = "" // 錯誤訊息
    var onEventCreated: () -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Activity Information")) {
                    TextField("Activity Title", text: $title)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Activity Description", text: $description)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Activity Location", text: $location)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    // 日期選擇器
                    DatePicker("Activity Date", selection: $selectedDate, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.compact)
                }
                
                Section(header: Text("Activity Menu")) {
                    TextField("Menu (comma separated)", text: $menu)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                // 錯誤訊息顯示
                if showError {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .padding(.top, 5)
                }
            }
            .navigationTitle("Create Activity")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        validateAndCreateEvent() // 驗證並建立活動
                    }
                }
            }
        }
    }
    
    // 驗證輸入並建立活動
    func validateAndCreateEvent() {
        // 驗證所有欄位是否已填寫
        if title.isEmpty {
            showError = true
            errorMessage = "Please enter the activity title."
            return
        }
        
        if description.isEmpty {
            showError = true
            errorMessage = "Please enter the activity description."
            return
        }
        
        if location.isEmpty {
            showError = true
            errorMessage = "Please enter the activity location."
            return
        }
        
        if menu.isEmpty {
            showError = true
            errorMessage = "Please enter the activity menu."
            return
        }
        
        // 如果所有欄位都已填寫，則清除錯誤訊息
        showError = false
        errorMessage = ""
        
        // 呼叫建立活動函式
        createEvent()
    }
    
    // 建立活動
    func createEvent() {
        guard let url = URL(string: "\(AppConfig.baseURL)/api/create_event") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(userId)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 將日期格式化為 ISO 8601 格式
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.timeZone = TimeZone.current
        let datetime = dateFormatter.string(from: selectedDate)
        
        let body: [String: Any] = [
            "title": title,
            "description": description,
            "location": location,
            "datetime": datetime,
            "menu": menu.split(separator: ",").map { String($0) }
        ]
        
        // 序列化 JSON
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            print("Failed to serialize JSON: \(error)")
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                let response = try? JSONSerialization.jsonObject(with: data, options: [])
                print("Create activity response: \(response ?? "Unable to parse")")
                onEventCreated()
                presentationMode.wrappedValue.dismiss()
            } else if let error = error {
                print("Failed to create activity: \(error)")
            }
        }.resume()
    }
}
