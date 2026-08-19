//
//  RoadEdge.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/18/26.
//

import Foundation


// MARK: - Road Class

enum RoadClass:
    String,
    Codable,
    CaseIterable,
    Sendable {

    case local

    case arterial

    case highway

    case circle

    case connector

    case culDeSac
}


// MARK: - Travel Direction

enum RoadTravelDirection:
    String,
    Codable,
    CaseIterable,
    Sendable {

    /// from <-> to
    case bidirectional


    /// from -> to
    case fromTo


    /// from <- to
    case toFrom


    /// Visually exists, but cannot currently
    /// be traversed.
    case closed
}


// MARK: - Road Geometry

enum RoadEdgeShape:
    Codable,
    Hashable,
    Sendable {

    /// Direct line from vertex A to vertex B.
    case straight


    /// Additional WORLD points between the
    /// endpoint vertices.
    ///
    /// Endpoints themselves are not repeated.
    case polyline(
        intermediatePoints: [WorldPoint]
    )


    /// Cubic Bézier controls.
    ///
    /// Endpoint positions are still obtained
    /// from the two RoadVertex values.
    case cubicBezier(
        control1: WorldPoint,
        control2: WorldPoint
    )
}


// MARK: - Attributes

struct RoadAttributes:
    Codable,
    Hashable,
    Sendable {

    var displayName: String?

    var isTraversable: Bool

    /// Useful when two roads visually cross
    /// without forming an intersection.
    var isGradeSeparated: Bool

    /// Used later by RoutePlanner.
    ///
    /// 1.0 = ordinary cost
    /// >1  = less desirable
    /// <1  = preferred
    var routingCostMultiplier:
        Double

    var tags: [String]


    init(
        displayName: String? = nil,
        isTraversable: Bool = true,
        isGradeSeparated: Bool = false,
        routingCostMultiplier:
            Double = 1.0,
        tags: [String] = []
    ) {

        self.displayName =
            displayName

        self.isTraversable =
            isTraversable

        self.isGradeSeparated =
            isGradeSeparated

        self.routingCostMultiplier =
            routingCostMultiplier

        self.tags =
            tags
    }
}


// MARK: - Road Edge

struct RoadEdge:
    Identifiable,
    Codable,
    Hashable,
    Sendable {

    let id: RoadEdgeID

    let fromID: RoadVertexID

    let toID: RoadVertexID

    var roadClass: RoadClass

    var travelDirection:
        RoadTravelDirection

    var shape:
        RoadEdgeShape

    var attributes:
        RoadAttributes


    init(
        id: RoadEdgeID,
        fromID: RoadVertexID,
        toID: RoadVertexID,
        roadClass: RoadClass,
        travelDirection:
            RoadTravelDirection = .bidirectional,
        shape:
            RoadEdgeShape = .straight,
        attributes:
            RoadAttributes = RoadAttributes()
    ) {

        self.id =
            id

        self.fromID =
            fromID

        self.toID =
            toID

        self.roadClass =
            roadClass

        self.travelDirection =
            travelDirection

        self.shape =
            shape

        self.attributes =
            attributes
    }
}
