//
//  GameNodeAction.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/24/26.
//



import Foundation


enum GameNodeAction:
    Equatable,
    Sendable {

    case showPlay(
        nodeID: GameNodeID
    )

    case showUser(
        nodeID: GameNodeID,
        userID: String
    )

    case showActivityMeal(
        nodeID: GameNodeID,
        activityID: String
    )

    case showActivityWorkout(
        nodeID: GameNodeID,
        activityID: String
    )

    case showActivityTask(
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
