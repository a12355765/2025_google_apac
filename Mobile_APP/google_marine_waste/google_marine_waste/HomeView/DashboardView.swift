//
//  DashboardView.swift
//  google_marine_waste
//
//  Created by jong on 2025/5/6.
//

// 主畫面
import Firebase
import SwiftUI

// 定義 API 基礎 URL
struct AppConfig {
    static let baseURL = "http://172.20.10.2:5000" // 替換為您的後端 IP 位址
}

@main
struct OceanCleanApp: App {
    init() {
        FirebaseApp.configure()
    }
    
    @State private var username: String = "Username"
    @State private var isLoggedIn: Bool = false
    @State private var userRole: String = "user"
    @State private var userId: String = "user_id"
    @State private var userPoints: Int = 2400 // 模擬使用者點數
    
    @State var userAvatar: String? = nil // 使用者自定義頭像URL，默認為nil
    
    var body: some Scene {
        WindowGroup {
            MainTabView(username: $username, isLoggedIn: $isLoggedIn, userAvatar: $userAvatar, userRole: $userRole, userId: $userId,userPoints: $userPoints)
                .onAppear {
                    // 檢查登入狀態
                    if let savedUsername = UserDefaults.standard.string(forKey: "username"),
                       UserDefaults.standard.bool(forKey: "isLoggedIn") {
                        username = savedUsername
                        isLoggedIn = true
                        
                    }
                    if let savedUserId = UserDefaults.standard.string(forKey: "user_id") {
                        userId = savedUserId
                        print("Loaded userId: \(userId)")
                    } else {
                        print("userId not found")
                    }
                }
        }
    }
}

// 主畫面
struct DashboardView: View {
    @State private var navigateToSettings = false // 控制是否顯示使用者設定頁面
    @State private var navigateToRedemption = false // 控制是否導航到兌換專區
    @Binding var username: String
    @State private var navigateToMarineWasteAtlas = false // 控制是否導航到海廢圖鑑
    @State private var navigateToWasteRecognition = false // 控制是否導航到海廢圖鑑
    @State private var navigateToLogin = false // 控制是否導航到登入頁面
    @Binding var isLoggedIn: Bool
    @State private var navigateToActivityList = false // 控制是否導航到活動列表
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @Binding var userAvatar: String?
    @Binding var reset: Bool // 接收重置通知
    @Binding var userRole: String
    @Binding var userId: String
    @Binding var userPoints: Int

    // 新增狀態：使用者的已報名活動
    @State private var userActivities: [String] = [] // 儲存活動名稱
    @State private var isLoadingActivities = false // 控制活動資料加載狀態

    var body: some View {
        NavigationView {
            VStack {
                // 上方區域：頭像與點數
                HStack {
                    // 左上角：使用者頭像按鈕
                    Button(action: {
                        if isLoggedIn {
                            navigateToSettings = true
                        } else {
                            navigateToLogin = true
                        }
                    }) {
                        CircleAvatarView(
                            avatarURL: userAvatar,
                            defaultImageName: "person.circle.fill"
                        )
                    }
                    .background(
                        NavigationLink(
                            destination: destinationView(),
                            isActive: $navigateToSettings,
                            label: { EmptyView() }
                        )
                    )
                    .background(
                        NavigationLink(
                            destination: LoginView(username: $username, isLoggedIn: $isLoggedIn, userRole: $userRole, userId: $userId),
                            isActive: $navigateToLogin,
                            label: { EmptyView() }
                        )
                    )
                    Spacer()
                    
                    // 右上角：點數顯示按鈕
                    NavigationLink(
                        destination: PointExchangeView(userPoints: $userPoints),
                        isActive: $navigateToRedemption
                    ) {
                        Button(action: {
                            navigateToRedemption = true
                        }) {
                            HStack {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                Text("\(userPoints) Points")
                                    .font(.headline)
                                    .foregroundColor(.black)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                // 中間區域：區塊顯示資訊
                ScrollView {
                    VStack(spacing: 20) {
                        // 區塊 1：海廢統計數據
                        InfoBlock(
                            title: "🌊 Marine Waste Statistics",
                            content: "Over 8 million tons of plastic waste enter the ocean every year, causing severe damage to ecosystems."
                        )
                        
                        // 區塊 2：快速入口按鈕
                        VStack(alignment: .leading, spacing: 10) {
                            Text("🚀 Quick Access")
                                .font(.headline)
                                .padding(.bottom, 5)
                            
                            HStack(spacing: 20) {
                                QuickActionButton(
                                    icon: "camera.viewfinder",
                                    color: .blue,
                                    title: "Waste Recognition",
                                    action: {
                                        navigateToWasteRecognition = true
                                    }
                                )
                                
                                QuickActionButton(
                                    icon: "calendar",
                                    color: .green,
                                    title: "Activity List",
                                    action: {
                                        navigateToActivityList = true
                                    }
                                )
                                
                                QuickActionButton(
                                    icon: "gift.fill",
                                    color: .orange,
                                    title: "Redemption Zone",
                                    action: {
                                        navigateToRedemption = true
                                    }
                                )
                                QuickActionButton(
                                    icon: "book.fill",
                                    color: .purple,
                                    title: "Marine Waste Atlas",
                                    action: {
                                        navigateToMarineWasteAtlas = true
                                    }
                                )
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                        
                        // 區塊 3：環保小知識
                        InfoBlock(
                            title: "🌟 Today's Tip",
                            content: "Plastic straws take 200 years to fully decompose. Switch to eco-friendly straws to protect the ocean!"
                        )
                        
                        // 區塊 4：海廢行事曆
                        VStack(alignment: .leading, spacing: 10) {
                            Text("📅 Marine Waste Calendar")
                                .font(.headline)
                                .padding(.bottom, 5)
                            
                            if isLoadingActivities {
                                ProgressView("Loading activities...")
                                    .padding()
                            } else if userActivities.isEmpty {
                                // 如果沒有活動，顯示加號按鈕
                                Button(action: {
                                    navigateToActivityList = true
                                }) {
                                    HStack {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.title)
                                            .foregroundColor(.blue)
                                        Text("No activities yet. Join one now!")
                                            .font(.subheadline)
                                            .foregroundColor(.blue)
                                    }
                                }
                            } else {
                                // 顯示已報名的活動列表
                                ForEach(userActivities, id: \.self) { activity in
                                    Text("• \(activity)")
                                        .font(.subheadline)
                                        .foregroundColor(.black)
                                }
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                    }
                    .padding()
                }
                
                Spacer()
            }
            .navigationBarHidden(true) // 隱藏預設的導航列
            .background(
                NavigationLink(
                    destination: MarineWasteAtlasView(),
                    isActive: $navigateToMarineWasteAtlas,
                    label: { EmptyView() }
                )
            )
            .background(
                NavigationLink(
                    destination: ActivityListView(username: $username, reset: $reset, userId: $userId),
                    isActive: $navigateToActivityList,
                    label: { EmptyView() }
                )
            )
            .background(
                NavigationLink(
                    destination: WasteRecognitionView(reset: $reset, userId: $userId),
                    isActive: $navigateToWasteRecognition,
                    label: { EmptyView() }
                )
            )
            .onAppear {
                loadUserActivities()
            }
            .onChange(of: reset) { _ in
                // 重置狀態
                resetDashboardState()
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
    
    // 其他函式與組件保持不變

    
    // 從後端加載使用者活動
    private func loadUserActivities() {
        isLoadingActivities = true
        guard let url = URL(string: "\(AppConfig.baseURL)/api/user_activities?user_id=\(userId)") else {
            print("Invalid URL")
            isLoadingActivities = false
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                isLoadingActivities = false
                if let error = error {
                    print("Error fetching activities: \(error.localizedDescription)")
                    return
                }
                
                guard let data = data else {
                    print("No data received")
                    return
                }
                
                do {
                    // 假設後端返回的活動名稱陣列
                    userActivities = try JSONDecoder().decode([String].self, from: data)
                } catch {
                    print("Error decoding activities: \(error.localizedDescription)")
                }
            }
        }.resume()
    }
    
    private func resetDashboardState() {
        navigateToSettings = false
        navigateToRedemption = false
        navigateToMarineWasteAtlas = false
        navigateToLogin = false
        navigateToActivityList = false
        navigateToWasteRecognition = false
    }
    
    @ViewBuilder
    private func destinationView() -> some View {
        if isLoggedIn {
            UserSettingsView(username: $username, isLoggedIn: $isLoggedIn, userAvatar: $userAvatar)
        } else {
            LoginView(username: $username, isLoggedIn: $isLoggedIn, userRole: $userRole, userId: $userId)
        }
    }
}

// 快速入口按鈕的組件
struct QuickActionButton: View {
    let icon: String
    let color: Color
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack {
                Image(systemName: icon)
                    .font(.largeTitle)
                    .foregroundColor(.white)
                    .padding()
                    .background(color)
                    .clipShape(Circle())
                Text(title)
                    .font(.caption)
                    .foregroundColor(color)
            }
        }
    }
}

struct CircleAvatarView: View {
    var avatarURL: String?
    var defaultImageName: String

    var body: some View {
        if let avatarURL = avatarURL, let url = URL(string: avatarURL) {
            AsyncImage(url: url) { image in
                image
                    .resizable()
                    .scaledToFit()
                    .clipShape(Circle())
                    .frame(width: 40, height: 40)
            } placeholder: {
                Image(systemName: defaultImageName)
                    .resizable()
                    .scaledToFit()
                    .clipShape(Circle())
                    .frame(width: 40, height: 40)
            }
        } else {
            Image(systemName: defaultImageName)
                .resizable()
                .scaledToFit()
                .clipShape(Circle())
                .frame(width: 40, height: 40)
        }
    }
}

// 預覽
/*
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
*/
