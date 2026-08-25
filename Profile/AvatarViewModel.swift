//
//  AvatarViewModel.swift
//  Fifoo
//
//  Created by Daudi Sagala on 7/8/24.
//

import Foundation

struct AvatarViewModel {
    private let avatar: Avatar
    
    init(_ avatar: Avatar) {
        self.avatar = avatar
        
    }
    
    var id = UUID()
    
    var avatarId: String {
        avatar.avatarId
    }
    
    var imageUrl: String {
        avatar.imageUrl
    }
    
    var tags: [String] {
        avatar.tags
    }
    
    var useCount: Int {
        avatar.useCount
    }
    
}
