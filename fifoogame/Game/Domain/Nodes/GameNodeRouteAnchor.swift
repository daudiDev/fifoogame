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


        /// Fraction follows the edge's canonical
        /// fromID -> toID geometry.
        case edge(
            edgeID:
                RoadEdgeID,
            fraction:
                Double
        )
    }


    let nodeID:
        GameNodeID


    /// Actual location of the node on the
    /// time/progress plane.
    let nodeCoordinate:
        MapCoordinate


    /// Road geometry underneath the node.
    let roadLocation:
        RoadLocation
}

extension GameNodeRouteAnchor {

    var roadRouteAnchor:
        RoadRouteAnchor {

        RoadRouteAnchor(
            coordinate:
                nodeCoordinate,
            roadLocation:
                roadLocation
        )
    }
}

