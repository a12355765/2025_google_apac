//
//  InfoBlock.swift
//  google_marine_waste
//
//  Created by jong on 2025/5/6.
//
import SwiftUI
// 區塊樣式的組件
struct InfoBlock: View {
    let title: String
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
            Text(content)
                .font(.body)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(10)
    }
}
