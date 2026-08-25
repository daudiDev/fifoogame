//
//  UserProfileViewModel.swift
//  fifoo
//
//  Created by Daudi Sagala on 5/30/25.
//

import Foundation

struct UserProfileViewModel: Identifiable {
    
    var id = UUID()
    
    private var profile: UserProfile
    
    init(_ profile: UserProfile) {
        self.profile = profile
    }
    
    var userId: String {
        get { profile.userId }
        set { profile.userId = newValue }
    }
    
    var username: String {
        get { profile.username }
        set { profile.username = newValue }
    }
    
    var firstName: String {
        get { profile.firstName }
        set { profile.firstName = newValue }
    }
    
    var lastName: String {
        get { profile.lastName }
        set { profile.lastName = newValue }
    }
    
    var phone: String {
        get { profile.phone }
        set { profile.phone = newValue }
    }
    
    var joined: String {
        get { profile.joined }
        set { profile.joined = newValue }
    }
    
    var imageUrl: String {
        get { profile.imageUrl }
        set { profile.imageUrl = newValue }
    }
    
    var goal: String {
        get { profile.goal }
        set { profile.goal = newValue }
    }
    
    var lastActive: String {
        get { profile.lastActive }
        set { profile.lastActive = newValue }
    }
    
    var inFollowersCount: Int {
        get { profile.inFollowersCount }
        set { profile.inFollowersCount = newValue }
    }
    
    var outFollowersCount: Int {
        get { profile.outFollowersCount }
        set { profile.outFollowersCount = newValue }
    }
    
    var topTipster: Bool {
        get { profile.topTipster }
        set { profile.topTipster = newValue }
    }
    
    var topRequester: Bool {
        get { profile.topRequester }
        set { profile.topRequester = newValue }
    }
    
    var topResponder: Bool {
        get { profile.topResponder }
        set { profile.topResponder = newValue }
    }
    
    var topContributor: Bool {
        get { profile.topContributor }
        set { profile.topContributor = newValue }
    }
    
    var tipsCount: Int {
        get { profile.tipsCount }
        set { profile.tipsCount = newValue }
    }
    
    var responseCount: Int {
        get { profile.responseCount }
        set { profile.responseCount = newValue }
    }
    
    var requestCount: Int {
        get { profile.requestCount }
        set { profile.requestCount = newValue }
    }
    
}
