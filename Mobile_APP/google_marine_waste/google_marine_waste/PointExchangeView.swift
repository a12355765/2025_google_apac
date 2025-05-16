//
//  PointsRedemptionView.swift
//  google_marine_waste
//
//  Created by jong on 2025/5/5.
//

import SwiftUI

struct PointExchangeView: View {
    @Binding var userPoints: Int// 使用者的初始海廢點數
    
    // 示例的兌換選項（帶有彩色圖示 URL 和所需點數）
    let exchangeItems = [
        ("Coffee Voucher", 50, "https://img.icons8.com/color/100/coffee-to-go.png"), // Coffee icon
        ("Movie Ticket", 100, "https://img.icons8.com/color/100/ticket.png"),       // Movie ticket icon
        ("Gift Card", 200, "https://img.icons8.com/color/100/gift-card.png"),      // Gift card icon
        ("Restaurant Discount", 150, "https://img.icons8.com/color/100/restaurant-menu.png"), // Restaurant icon
        ("Shopping Discount", 300, "https://img.icons8.com/color/100/shopping-bag.png"), // Shopping bag icon
        ("Sports Equipment", 250, "https://img.icons8.com/color/100/sports-mode.png")   // Sports icon
    ]
    
    var body: some View {
        NavigationView {
            VStack {
                // 右上角顯示使用者的點數
                HStack {
                    Spacer()
                    Text("Points: \(userPoints)")
                        .font(.headline)
                        .padding()
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(10)
                        .padding(.trailing)
                }
                
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 20)], spacing: 20) {
                        ForEach(exchangeItems, id: \.0) { item in
                            ExchangeItemView(
                                name: item.0,
                                points: item.1,
                                imageUrl: item.2,
                                userPoints: $userPoints // 傳遞點數狀態
                            )
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Exchange") // 頁面標題
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
}

struct ExchangeItemView: View {
    let name: String
    let points: Int
    let imageUrl: String // 獎品圖片 URL
    @Binding var userPoints: Int // 綁定使用者的點數
    
    var body: some View {
        VStack(spacing: 10) {
            // 獎品圖片
            AsyncImage(url: URL(string: imageUrl)) { image in
                image
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80) // 統一圖片大小
            } placeholder: {
                // 載入中的佔位符
                ProgressView()
                    .frame(width: 80, height: 80)
            }
            
            // 獎品名稱
            Text(name)
                .font(.headline)
                .multilineTextAlignment(.center) // 居中對齊
                .lineLimit(2) // 限制名稱最多兩行
            
            // 點數需求
            Text("\(points) Points")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            // 兌換按鈕
            Button(action: {
                redeemItem()
            }) {
                Text("Redeem")
                    .font(.footnote)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(userPoints >= points ? Color.blue : Color.gray) // 點數不足時按鈕變灰
                    .cornerRadius(10)
            }
            .disabled(userPoints < points) // 點數不足時禁用按鈕
        }
        .frame(width: 160, height: 200) // 統一框框大小
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 5)
    }
    
    // 兌換功能
    private func redeemItem() {
        if userPoints >= points {
            userPoints -= points // 扣除兌換所需的點數
            print("\(name) redeemed successfully. Remaining points: \(userPoints)")
        }
    }
}
