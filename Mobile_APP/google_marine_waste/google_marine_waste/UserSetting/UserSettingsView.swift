//
//  UserSettingsView.swift
//  google_marine_waste
//
//  Created by jong on 2025/5/6.
//
import SwiftUI

struct UserSettingsView: View {
    @Binding var username: String
    @Binding var isLoggedIn: Bool
    @Binding var userAvatar: String? // 使用者自定義頭像URL
    @Environment(\.presentationMode) var presentationMode

    // 頭像顏色選項
    let avatarColors = ["FF0000", "0000FF", "008000", "FFFF00", "800080", "FFA500"] // 紅、藍、綠、黃、紫、橙

    var body: some View {
        VStack(spacing: 30) {
            Text("使用者設定")
                .font(.largeTitle)
                .padding()

            // 顯示使用者頭像（更大的尺寸）
            CircleAvatarView(
                avatarURL: userAvatar,
                defaultImageName: "person.circle.fill"
            )
            .frame(width: 120, height: 120) // 調整頭像大小
            .padding()

            // 提供6個顏色選擇頭像
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 20) {
                ForEach(avatarColors, id: \.self) { color in
                    Button(action: {
                        // 更新頭像為選定顏色
                        userAvatar = "https://dummyimage.com/150x150/\(color)/FFFFFF&text=Avatar"
                        print("更新頭像為顏色：\(color)")
                    }) {
                        Circle()
                            .fill(Color(hex: color))
                            .frame(width: 60, height: 60) // 調整按鈕大小
                    }
                }
            }
            .padding()

            // 登出按鈕
            Button(action: {
                UserDefaults.standard.removeObject(forKey: "username")
                UserDefaults.standard.set(false, forKey: "isLoggedIn")
                isLoggedIn = false
                print("\(isLoggedIn)")
                // 可選：清除其他相關資料
                UserDefaults.standard.synchronize()
                userAvatar = nil
                presentationMode.wrappedValue.dismiss()
                print("使用者已登出")
            }) {
                Text("登出")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red)
                    .cornerRadius(10)
                    .padding(.horizontal)
            }

            Spacer()
        }
        .padding()
    }
}

extension Color {
    /// 根據十六進位字串生成 `Color`
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var hexNumber: UInt64 = 0
        scanner.scanHexInt64(&hexNumber)
        let r = Double((hexNumber & 0xFF0000) >> 16) / 255.0
        let g = Double((hexNumber & 0x00FF00) >> 8) / 255.0
        let b = Double(hexNumber & 0x0000FF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
