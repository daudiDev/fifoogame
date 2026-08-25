//
//  UserProfileModel.swift
//  Fifoo
//
//  Created by Daudi Sagala on 5/27/24.
//

import SwiftUI

struct UserProfile: Codable {
    
    var userId: String
    var username: String
    var firstName: String
    var lastName: String
    var phone: String
    var joined: String
    var imageUrl: String 
    var goal: String
    var lastActive: String
    var inFollowersCount: Int
    var outFollowersCount: Int
    var topTipster: Bool
    var topRequester: Bool
    var topResponder: Bool
    var topContributor: Bool
    var tipsCount: Int
    var responseCount: Int
    var requestCount: Int
    
}


