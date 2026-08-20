//
//  RouteSwitchCompatibility.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/19/26.
//


import Foundation


enum RouteSwitchCompatibility {

    static func canSwitch(
        completedRoute:
            CompletedRoute,
        to candidate:
            GameRoute,
        at time:
            DayTime,
        gameNodes:
            [GameMapNode],
        roadGraph:
            RoadGraph
    ) -> Bool {

        /*
         Nothing has been traveled yet.
         There is nothing to preserve geometrically.
         */

        guard let completedBoundary =
            completedRoute.boundary
        else {

            return true
        }


        let candidateSnapshot =
            GameRouteProgressResolver
                .snapshot(
                    of:
                        candidate,
                    at:
                        time,
                    gameNodes:
                        gameNodes,
                    graph:
                        roadGraph
                )


        guard let candidateBoundary =
            candidateSnapshot.boundary
        else {

            return false
        }


        return RoadLocationCanonicalizer
            .equivalent(
                completedBoundary,
                candidateBoundary,
                graph:
                    roadGraph
            )
    }
}
