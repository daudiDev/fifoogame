//
//  RoutePreviewRenderState.swift
//  Fifoo
//

import Foundation


struct RoutePreviewRenderPath:
    Equatable,
    Sendable {

    let routeID:
        RouteID


    let segments:
        [RoadRouteSegment]


    let isSelected:
        Bool
}


struct RoutePreviewRenderState:
    Equatable,
    Sendable {

    let routes:
        [RoutePreviewRenderPath]


    static let empty =
        RoutePreviewRenderState(
            routes:
                []
        )


    var isEmpty:
        Bool {

        routes.isEmpty
    }
}
