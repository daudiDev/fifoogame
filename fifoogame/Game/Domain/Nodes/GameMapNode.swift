//
//  GameMapNode.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/19/26.
//

import Foundation


struct GameMapNode:
    Identifiable,
    Codable,
    Equatable,
    Sendable {

    let id: GameNodeID

    var placement:
        GameNodePlacement

    var content:
        GameNodeContent

    var isEnabled:
        Bool


    init(
        id: GameNodeID = GameNodeID(),
        placement: GameNodePlacement,
        content: GameNodeContent,
        isEnabled: Bool = true
    ) {

        self.id =
            id

        self.placement =
            placement

        self.content =
            content

        self.isEnabled =
            isEnabled
    }
}
