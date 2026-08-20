//
//  RouteRenderState.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/19/26.
//

import Foundation


struct RouteRenderPath:
    Equatable,
    Sendable {

    let routeID:
        RouteID

    let segments:
        [RoadRouteSegment]
}


struct RouteRenderState:
    Equatable,
    Sendable {

    // =====================================================
    // MARK: - Completed History
    // =====================================================

    var completedSegments:
        [RoadRouteSegment]


    // =====================================================
    // MARK: - Chosen Future
    // =====================================================

    var chosenFuture:
        RouteRenderPath?


    // =====================================================
    // MARK: - Alternatives
    // =====================================================

    var alternatives:
        [RouteRenderPath]


    // =====================================================
    // MARK: - Current Route Boundary
    // =====================================================

    var currentBoundary:
        GameNodeRouteAnchor.RoadLocation?


    static let empty =
        RouteRenderState(
            completedSegments:
                [],
            chosenFuture:
                nil,
            alternatives:
                [],
            currentBoundary:
                nil
        )
}
