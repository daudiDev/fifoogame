//
//  SceneInteraction.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/19/26.
//

import Foundation


enum SceneInteraction:
    Equatable,
    Sendable {

    case backgroundTapped(
        worldPoint: WorldPoint,
        mapCoordinate: MapCoordinate
    )


    /// Primary interaction for the redesigned card-based day map.
    ///
    /// A tile may contain a game node, represent a route state, or be an
    /// unrevealed/empty card. The scene resolves those presentation details
    /// and emits one semantic interaction to the app layer.
    case dayTileTapped(
        cellID: GridCellID,
        nodeID: GameNodeID?,
        routeTarget: RouteInteractionTarget?,
        isRevealed: Bool,
        worldPoint: WorldPoint,
        mapCoordinate: MapCoordinate
    )


    case roadEdgeTapped(
        edgeID: RoadEdgeID,
        worldPoint: WorldPoint,
        mapCoordinate: MapCoordinate
    )


    case roadVertexTapped(
        vertexID: RoadVertexID,
        worldPoint: WorldPoint,
        mapCoordinate: MapCoordinate
    )
    
    case gameNodeTapped(
        nodeID: GameNodeID,
        worldPoint: WorldPoint,
        mapCoordinate: MapCoordinate
    )
    
    // =================================================
    // Route
    // =================================================

    case routeTapped(
        target:
            RouteInteractionTarget,
        worldPoint:
            WorldPoint,
        mapCoordinate:
            MapCoordinate
    )
    
}




@MainActor
protocol SceneInteractionDelegate:
    AnyObject {

    func sceneDidEmit(
        _ interaction:
            SceneInteraction
    )
}
