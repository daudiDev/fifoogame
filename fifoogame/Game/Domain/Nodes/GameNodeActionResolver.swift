//
//  GameNodeActionResolver.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/19/26.
//



import Foundation


enum GameNodeActionResolver {

    static func action(
        for node: GameMapNode
    ) -> GameNodeAction {

        switch node.content {

        // =========================================
        // Label
        // =========================================

        case .label:

            return .showLabel(
                nodeID:
                    node.id
            )


        // =========================================
        // User
        // =========================================

        case let .user(content):

            return .showUser(
                nodeID:
                    node.id,
                userID:
                    content.userID
            )


        // =========================================
        // Activity
        // =========================================

        case let .activity(content):

            return .showActivity(
                nodeID:
                    node.id,
                activityID:
                    content.activityID
            )


        // =========================================
        // Post
        // =========================================

        case let .post(content):

            return .showPost(
                nodeID:
                    node.id,
                postID:
                    content.postID
            )


        // =========================================
        // Media
        // =========================================

        case let .media(content):

            return .showMedia(
                nodeID:
                    node.id,
                mediaID:
                    content.mediaID
            )


        // =========================================
        // Hyperlink
        // =========================================

        case let .hyperlink(content):

            return .openHyperlink(
                nodeID:
                    node.id,
                urlString:
                    content.urlString
            )
        }
    }
}
