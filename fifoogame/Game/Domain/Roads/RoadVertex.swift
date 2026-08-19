//
//  RoadVertexKind.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/18/26.
//


import Foundation


// MARK: - Road Vertex Kind

enum RoadVertexKind:
    String,
    Codable,
    CaseIterable,
    Sendable {

    /// A true road intersection.
    ///
    /// Usually 3+ road connections.
    case intersection


    /// General connection/join point.
    ///
    /// May also represent a normal endpoint
    /// between separate road-edge segments.
    case junction


    /// Explicit entrance onto a circular
    /// road / roundabout.
    case circleEntry


    /// Explicit exit from a circular
    /// road / roundabout.
    case circleExit


    /// Terminal end of a cul-de-sac.
    ///
    /// Validator requires exactly one
    /// traversable incident road edge.
    case culDeSacEnd


    /// Reserved graph control/topology point.
    ///
    /// Visual curve-control points usually
    /// belong to RoadEdgeShape instead.
    case control
}


// MARK: - Road Vertex

struct RoadVertex:
    Identifiable,
    Codable,
    Hashable,
    Sendable {

    let id: RoadVertexID

    var coordinate: MapCoordinate

    var kind: RoadVertexKind


    init(
        id: RoadVertexID,
        coordinate: MapCoordinate,
        kind: RoadVertexKind
    ) {

        self.id = id

        self.coordinate =
            coordinate

        self.kind =
            kind
    }
}


// MARK: - Convenience

extension RoadVertex {

    var worldPoint: WorldPoint {

        MapCoordinateConverter
            .worldPoint(
                for: coordinate
            )
    }
}
