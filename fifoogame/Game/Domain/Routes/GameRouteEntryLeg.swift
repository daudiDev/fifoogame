//
//  GameRouteEntryLeg.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/19/26.
//


import Foundation


struct GameRouteEntryLeg:
    Codable,
    Equatable,
    Hashable,
    Sendable {

    /// Actual road position where this future route begins.
    ///
    /// Usually the player's current completed-route boundary.
    let startAnchor:
        RoadRouteAnchor


    /// First real gameplay stop.
    let toNodeID:
        GameNodeID


    /// Planned road path from current position
    /// to the first real gameplay stop.
    var path:
        RoadRoutePath?


    init(
        startAnchor: RoadRouteAnchor,
        toNodeID: GameNodeID,
        path: RoadRoutePath? = nil
    ) {

        self.startAnchor =
            startAnchor

        self.toNodeID =
            toNodeID

        self.path =
            path
    }
}
