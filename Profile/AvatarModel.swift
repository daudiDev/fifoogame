//
//  Avatar.swift
//  Fifoo
//
//  Created by Daudi Sagala on 7/8/24.
//

import Foundation

struct AvatarsArray {
    let avatars: [Avatar]
}

struct Avatar: Codable {
    let avatarId: String
    let imageUrl: String
    let tags: [String]
    let useCount: Int
}




