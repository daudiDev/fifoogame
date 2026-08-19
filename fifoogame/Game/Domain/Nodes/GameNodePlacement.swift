//
//  GameNodePlacement.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/19/26.
//


import Foundation


enum GameNodePlacement:
    Codable,
    Equatable,
    Sendable {

    /// Place freely anywhere in the semantic
    /// time/progress map.
    case coordinate(
        MapCoordinate
    )


    /// Attach to an existing road vertex.
    case roadVertex(
        RoadVertexID
    )
}
