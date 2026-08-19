//
//  GameNodeRoadRelationship.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/19/26.
//

import Foundation


enum GameNodeRoadRelationship:
    Equatable,
    Sendable {

    /// The node exists on the time/progress plane
    /// but is not on road geometry.
    case offRoad


    /// The node lies at / sufficiently close to
    /// an actual road vertex.
    case vertex(
        vertexID:
            RoadVertexID
    )


    /// The node lies on / sufficiently close to
    /// an actual road segment.
    case edge(
        edgeID:
            RoadEdgeID
    )
}

extension GameNodeRoadRelationship {

    var isOnRoad:
        Bool {

        switch self {

        case .offRoad:

            return false


        case .vertex,
             .edge:

            return true
        }
    }
}
