//
//  MarineWasteAelasView.swift
//  google_marine_waste
//
//  Created by jong on 2025/5/12.
//

import SwiftUI

// 模擬海廢項目資料結構
struct MarineWasteItem: Identifiable {
    let id: Int
    let name: String
    let imageName: String
    let description: String
    let rarity: String
    let isUnlocked: Bool
}

// 海廢圖鑑頁面
struct MarineWasteAtlasView: View {
    // 模擬資料
    let items = [
        MarineWasteItem(id: 1, name: "Plastic Fork", imageName: "1", description: "A lightweight plastic fork often found in waste.", rarity: "Common", isUnlocked: true),
        MarineWasteItem(id: 2, name: "Plastic Bag", imageName: "2", description: "A striped plastic bag that is commonly discarded.", rarity: "Common", isUnlocked: true),
        MarineWasteItem(id: 3, name: "PET Bottle", imageName: "3", description: "A recyclable PET bottle often improperly disposed.", rarity: "Common", isUnlocked: true),
        MarineWasteItem(id: 4, name: "Aluminum Cans", imageName: "4", description: "A collection of aluminum cans ready for recycling.", rarity: "Ordinary", isUnlocked: true),
        MarineWasteItem(id: 5, name: "Plastic Straws", imageName: "5", description: "Colorful plastic straws commonly found in waste.", rarity: "Common", isUnlocked: true),
        MarineWasteItem(id: 6, name: "Glass Jar", imageName: "6", description: "A glass jar often found along the beach.", rarity: "Rare", isUnlocked: false),
        MarineWasteItem(id: 7, name: "Flip Flops", imageName: "7", description: "A pair of flip flops washed ashore.", rarity: "Rare", isUnlocked: false),
        MarineWasteItem(id: 8, name: "Cigarette Butt", imageName: "8", description: "A common litter found on beaches.", rarity: "Common", isUnlocked: false),
        MarineWasteItem(id: 9, name: "Cotton Buds", imageName: "9", description: "Cotton buds often discarded improperly.", rarity: "Common", isUnlocked: false),
        MarineWasteItem(id: 10, name: "Buoy", imageName: "10", description: "A buoy used for marking areas at sea.", rarity: "Epic", isUnlocked: false),
        MarineWasteItem(id: 11, name: "Fishing Float", imageName: "11", description: "A fishing float used by anglers.", rarity: "Rare", isUnlocked: false),
        MarineWasteItem(id: 12, name: "Fishing Net", imageName: "12", description: "A piece of fishing net left behind.", rarity: "Epic", isUnlocked: false),
        MarineWasteItem(id: 13, name: "Styrofoam Ball", imageName: "13", description: "A styrofoam ball found on the shore.", rarity: "Common", isUnlocked: false),
        MarineWasteItem(id: 14, name: "Styrofoam Cup", imageName: "14", description: "A disposable cup found among the debris.", rarity: "Common", isUnlocked: false),
        MarineWasteItem(id: 15, name: "Plastic Cup", imageName: "15", description: "A plastic cup left on the beach.", rarity: "Common", isUnlocked: false),
        MarineWasteItem(id: 16, name: "Plastic Spoon", imageName: "16", description: "A plastic spoon often found in waste.", rarity: "Common", isUnlocked: false),
        MarineWasteItem(id: 17, name: "Cigarette Pack", imageName: "17", description: "An empty cigarette pack found.", rarity: "Ordinary", isUnlocked: false),
        MarineWasteItem(id: 18, name: "Broken Glass", imageName: "18", description: "Pieces of broken glass scattered.", rarity: "Rare", isUnlocked: false),
        MarineWasteItem(id: 19, name: "Plastic Bag", imageName: "19", description: "Another type of plastic bag found.", rarity: "Common", isUnlocked: false)
    ]
    
    @State private var selectedItem: MarineWasteItem? = nil // 用於顯示詳細頁面

    var body: some View {
        NavigationView {
            VStack {
                // 解鎖數量顯示
                Text("Number of unlocked: \(items.filter { $0.isUnlocked }.count)")
                    .font(.headline)
                    .padding()

                // 圖鑑網格
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 20) {
                        ForEach(items) { item in
                            Button(action: {
                                if item.isUnlocked {
                                    selectedItem = item
                                }
                            }) {
                                VStack {
                                    ZStack {
                                        // 背景顏色根據稀有度設定
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(backgroundColor(for: item))
                                            .frame(height: 120)

                                        // 圖片
                                        Image(item.isUnlocked ? item.imageName : "unknow")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(height: 80)
                                            .opacity(item.isUnlocked ? 1.0 : 0.3) // 未解鎖項目半透明
                                    }

                                    // 名稱
                                    Text(item.isUnlocked ? item.name : "?")
                                        .font(.caption)
                                        .foregroundColor(.primary)
                                }
                            }
                            .disabled(!item.isUnlocked) // 未解鎖項目無法點擊
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Marine Waste Atlas")
            .sheet(item: $selectedItem) { item in
                MarineWasteDetailView(item: item)
            }
        }
    }
    
    // 根據稀有度返回背景顏色
    func backgroundColor(for item: MarineWasteItem) -> Color {
        if !item.isUnlocked {
            return Color.gray.opacity(0.3)
        }
        
        switch item.rarity {
        case "Common":
            return Color.green.opacity(0.3)
        case "Ordinary":
            return Color.blue.opacity(0.3)
        case "Rare":
            return Color.purple.opacity(0.3)
        case "Epic":
            return Color.orange.opacity(0.3)
        default:
            return Color.gray.opacity(0.3)
        }
    }
}

// 詳細內容頁面
struct MarineWasteDetailView: View {
    let item: MarineWasteItem

    var body: some View {
        VStack(spacing: 20) {
            Image(item.isUnlocked ? item.imageName : "unknow")
                .resizable()
                .scaledToFit()
                .frame(height: 200)

            Text("NO.\(item.id)")
                .font(.title)

            Text(item.isUnlocked ? item.name : "???")
                .font(.largeTitle) // 字體加大
                .fontWeight(.bold) // 加粗
                .padding(.bottom, 10)

            Text(item.isUnlocked ? item.description : "This item is still locked.")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Text("Rarity: \(item.isUnlocked ? item.rarity : "Unknown")")
                .font(.subheadline)
                .foregroundColor(rarityColor(for: item.rarity)) // 使用對應顏色

            Spacer()
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(20)
        .padding()
    }
    // 根據稀有度返回文字顏色
        func rarityColor(for rarity: String) -> Color {
            switch rarity {
            case "Common":
                return Color.green
            case "Ordinary":
                return Color.blue
            case "Rare":
                return Color.purple
            case "Epic":
                return Color.orange
            default:
                return Color.gray
            }
        }
}
