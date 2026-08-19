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
    
}


@MainActor
protocol SceneInteractionDelegate:
    AnyObject {

    func sceneDidEmit(
        _ interaction:
            SceneInteraction
    )
}
