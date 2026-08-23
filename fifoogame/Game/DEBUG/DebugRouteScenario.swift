//
//  DebugRouteScenario 2.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/21/26.
//


#if DEBUG

struct DebugRouteScenario {

    let allNodeIDs:
        [GameNodeID]

    let routeStopNodeIDs:
        [GameNodeID]


    var nodeCount: Int {

        allNodeIDs.count
    }


    var routeStopCount: Int {

        routeStopNodeIDs.count
    }
}

#endif