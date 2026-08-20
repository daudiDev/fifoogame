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

    let startLocation:
        GameNodeRouteAnchor.RoadLocation


    let endLocation:
        GameNodeRouteAnchor.RoadLocation


    /// Vertices reached between route segments.
    var vertexIDs:
        [RoadVertexID]


    /// Actual ordered traversal.
    var segments:
        [RoadRouteSegment]


    var totalCost:
        Double


    // =====================================================
    // MARK: - Convenience
    // =====================================================

    var edgeIDs:
        [RoadEdgeID] {

        segments.map(
            \.edgeID
        )
    }


    var isEmpty:
        Bool {

        segments.isEmpty
    }
}
