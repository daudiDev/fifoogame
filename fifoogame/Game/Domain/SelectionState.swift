//
//  SelectionState.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/19/26.
//


import Foundation


struct SelectionState:
    Equatable,
    Sendable {

    var selectedRouteID:
        RouteID?

    var selectedNodeID:
        GameNodeID?

    var selectedRoadEdgeID:
        RoadEdgeID?

    var selectedRoadVertexID:
        RoadVertexID?


    var hasSelection: Bool {

        selectedRouteID != nil
        ||
        selectedNodeID != nil
        ||
        selectedRoadEdgeID != nil
        ||
        selectedRoadVertexID != nil
    }


    mutating func selectRoadEdge(
        _ id: RoadEdgeID
    ) {

        selectedRoadEdgeID =
            id

        selectedRoadVertexID =
            nil

        selectedNodeID =
            nil

        selectedRouteID =
            nil
    }


    mutating func selectRoadVertex(
        _ id: RoadVertexID
    ) {

        selectedRoadVertexID =
            id

        selectedRoadEdgeID =
            nil

        selectedNodeID =
            nil

        selectedRouteID =
            nil
    }
    
    mutating func selectGameNode(
        _ id: GameNodeID
    ) {

        selectedNodeID =
            id

        selectedRoadEdgeID =
            nil

        selectedRoadVertexID =
            nil

        selectedRouteID =
            nil
    }


    mutating func clear() {

        selectedRouteID =
            nil

        selectedNodeID =
            nil

        selectedRoadEdgeID =
            nil

        selectedRoadVertexID =
            nil
    }
    
    
}
