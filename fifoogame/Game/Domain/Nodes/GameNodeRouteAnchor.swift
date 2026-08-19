//
//  GameNodeRouteAnchor.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/19/26.
//

import Foundation


struct GameNodeRouteAnchor:
    Equatable,
    Sendable {

    enum RoadLocation:
        Codable,
        Equatable,
        Hashable,
        Sendable {

        case vertex(
            RoadVertexID
        )

        case edge(
            RoadEdgeID
        )
    }


    let nodeID:
        GameNodeID


    /// The node's ACTUAL location on the
    /// time/progress plane.
    let nodeCoordinate:
        MapCoordinate


    /// Road geometry underneath the node.
    let roadLocation:
        RoadLocation
}
