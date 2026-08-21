//
//  WorkoutLiveMessage.swift
//  Fifoo Play
//
//  Created by Daudi Sagala on 8/16/26.
//

import SwiftUI


// MARK: - Live Message Model
struct WorkoutLiveMessage:
    Identifiable,
    Codable,
    Equatable {

    let id: UUID

    let username: String

    let message: String

    let profileImageURL: URL?

    let createdAt: Date


    init(
        id: UUID = UUID(),
        username: String,
        message: String,
        profileImageURL: URL? = nil,
        createdAt: Date = .now
    ) {

        self.id =
            id

        self.username =
            username

        self.message =
            message

        self.profileImageURL =
            profileImageURL

        self.createdAt =
            createdAt
    }
}



