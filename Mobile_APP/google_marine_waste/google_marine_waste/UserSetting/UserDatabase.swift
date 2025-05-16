//
//  UserDatabase.swift
//  google_marine_waste
//
//  Created by jong on 2025/5/12.
//

import SwiftUI
// 模擬的使用者資料庫
struct UserDatabase {
    static let users = [
        "user1": "p1",
        "user2": "p2",
        "admin": "a123"
    ]

    static func validate(username: String, password: String) -> Bool {
        return users[username] == password
    }
}
