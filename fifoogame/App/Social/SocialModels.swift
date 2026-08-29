import Foundation

// MARK: - Generic social/account DTOs

nonisolated struct SocialParticipant: Codable, Equatable, Identifiable, Sendable {
    let userID: UUID
    let username: String
    let displayName: String
    let imageURL: String?
    let lastActive: Date?

    var id: UUID { userID }
}

nonisolated struct SocialConversationLastMessage: Codable, Equatable, Sendable {
    let messageID: UUID
    let body: String
    let senderID: UUID?
    let createdAt: Date?
}

nonisolated struct SocialConversationSummary: Codable, Equatable, Identifiable, Sendable {
    let conversationID: UUID
    let title: String
    let participants: [SocialParticipant]
    let lastMessage: SocialConversationLastMessage?
    let updatedAt: Date?
    let isSupport: Bool

    var id: UUID { conversationID }


}

nonisolated struct SocialConversationOpenedPayload: Codable, Equatable, Sendable {
    let conversationID: UUID
    let partnerUserID: UUID?
    let isSupport: Bool
}

nonisolated struct SocialConversationMessagesPayload: Codable, Equatable, Sendable {
    let conversationID: UUID
    let messages: [SocialMessage]
}

nonisolated struct SocialMessage: Codable, Equatable, Identifiable, Sendable {
    let messageID: UUID
    let conversationID: UUID
    let body: String
    let imageURLs: [String]
    let videoURLs: [String]
    let senderID: UUID?
    let senderName: String
    let senderImageURL: String?
    let createdAt: Date?

    var id: UUID { messageID }
}

nonisolated struct SocialFriend: Codable, Equatable, Identifiable, Sendable {
    let userID: UUID
    let username: String
    let displayName: String
    let imageURL: String?
    let lastActive: Date?
    let progressPercent: Double
    let goalTargetPercent: Double
    let mapDate: String

    var id: UUID { userID }
}

nonisolated struct SocialPost: Codable, Equatable, Identifiable, Sendable {
    let postID: UUID
    let postType: String
    let subject: String
    let mainMediaURL: String?
    let mainMediaType: String?
    let imageURLs: [String]
    let videoURLs: [String]
    let posterID: UUID?
    let posterName: String
    let posterImageURL: String?
    let createdAt: Date?
    let tags: [String]
    var replyCount: Int
    var saveCount: Int
    var isSaved: Bool

    var id: UUID { postID }

    var preferredImageURL: String? {
        imageURLs.first ?? ((mainMediaType ?? "").lowercased() == "image" ? mainMediaURL : nil)
    }
}

nonisolated struct SocialPostSavedPayload: Codable, Equatable, Sendable {
    let postID: UUID
    let isSaved: Bool
    let saveCount: Int
}

// MARK: - Request DTOs

nonisolated struct SocialConversationPartnerPayload: Codable, Equatable, Sendable {
    let partnerUserID: UUID
}

nonisolated struct SocialConversationIDPayload: Codable, Equatable, Sendable {
    let conversationID: UUID
}

nonisolated struct SocialMessageSendPayload: Codable, Equatable, Sendable {
    let conversationID: UUID
    let body: String
}

nonisolated struct SocialFriendsRequestPayload: Codable, Equatable, Sendable {
    let mapDate: String
}

nonisolated struct SocialPostsRequestPayload: Codable, Equatable, Sendable {
    let limit: Int
    let offset: Int
}

nonisolated struct SocialPostSavePayload: Codable, Equatable, Sendable {
    let postID: UUID
    let isSaved: Bool
}

nonisolated struct SocialPostReply: Codable, Equatable, Identifiable, Sendable {
    let replyID: UUID
    let postID: UUID
    let parentReplyID: UUID?
    let body: String
    let posterID: UUID?
    let posterName: String
    let posterImageURL: String?
    let createdAt: Date?

    var id: UUID { replyID }
}

nonisolated struct SocialPostRepliesPayload: Codable, Equatable, Sendable {
    let postID: UUID
    let replies: [SocialPostReply]
}

nonisolated struct SocialPostIDPayload: Codable, Equatable, Sendable {
    let postID: UUID
}

nonisolated struct SocialPostReplySendPayload: Codable, Equatable, Sendable {
    let postID: UUID
    let body: String
}
