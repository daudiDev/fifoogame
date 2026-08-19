//
//  RoadRoutePath.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/19/26.
//


import Foundation


struct RoadRoutePath:
    Codable,
    Equatable,
    Hashable,
    Sendable {

    // =====================================================
    // MARK: - Endpoints
    // =====================================================

    let startLocation:
        GameNodeRouteAnchor.RoadLocation


    let endLocation:
        GameNodeRouteAnchor.RoadLocation


    // =====================================================
    // MARK: - Graph Path
    // =====================================================

    /// Ordered vertices traversed by the path.
    var vertexIDs:
        [RoadVertexID]


    /// Ordered road edges traversed by the path.
    var edgeIDs:
        [RoadEdgeID]


    // =====================================================
    // MARK: - Cost
    // =====================================================

    /// Routing cost produced by the route planner.
    ///
    /// This does not have to equal physical distance.
    var totalCost:
        Double


    init(
        startLocation: GameNodeRouteAnchor.RoadLocation,
        endLocation: GameNodeRouteAnchor.RoadLocation,
        vertexIDs: [RoadVertexID],
        edgeIDs: [RoadEdgeID],
        totalCost: Double
    ) {

        self.startLocation =
            startLocation

        self.endLocation =
            endLocation

        self.vertexIDs =
            vertexIDs

        self.edgeIDs =
            edgeIDs

        self.totalCost =
            totalCost
    }
}
