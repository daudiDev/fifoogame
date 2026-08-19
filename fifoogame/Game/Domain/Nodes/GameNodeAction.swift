//
//  GameNodeAction.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/19/26.
//


import Foundation


enum GameNodeAction:
    Equatable,
    Sendable {

    case showLabel(
        nodeID: GameNodeID
    )

    case showUser(
        nodeID: GameNodeID,
        userID: String
    )

    case showActivity(
        nodeID: GameNodeID,
        activityID: String
    )

    case showPost(
        nodeID: GameNodeID,
        postID: String
    )

    case showMedia(
        nodeID: GameNodeID,
        mediaID: String
    )

    case openHyperlink(
        nodeID: GameNodeID,
        urlString: String
    )
}
