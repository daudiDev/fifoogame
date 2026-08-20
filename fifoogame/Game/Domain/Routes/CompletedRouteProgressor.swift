//
//  CompletedRouteProgressor.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/19/26.
//

import Foundation


enum CompletedRouteProgressionFailure:
    Equatable,
    Sendable {

    case timeMovedBackward

    case routeBoundaryMismatch
}


struct CompletedRouteProgressionResult:
    Equatable,
    Sendable {

    let completedRoute:
        CompletedRoute


    let appendedSegments:
        [RoadRouteSegment]


    let newlyReachedNodeIDs:
        [GameNodeID]


    let failure:
        CompletedRouteProgressionFailure?


    var succeeded:
        Bool {

        failure ==
            nil
    }


    var didAppendRoadGeometry:
        Bool {

        !appendedSegments
            .isEmpty
    }
}

struct CompletedRouteProgressor {

    let timePolicy:
        RouteTimePolicy


    init(
        timePolicy:
            RouteTimePolicy = .dayMap
    ) {

        self.timePolicy =
            timePolicy
    }


    func advance(
        completedRoute:
            CompletedRoute,
        using activeRoute:
            GameRoute,
        routeActivatedAt:
            DayTime?,
        to newTime:
            DayTime,
        gameNodes:
            [GameMapNode],
        roadGraph:
            RoadGraph
    ) -> CompletedRouteProgressionResult {

        var updated =
            completedRoute


        let previousTime =
            completedRoute
                .throughTime


        // =============================================
        // Time cannot move backward within same day.
        // =============================================

        if
            let previousTime,

            newTime <
                previousTime
        {

            return CompletedRouteProgressionResult(
                completedRoute:
                    completedRoute,
                appendedSegments:
                    [],
                newlyReachedNodeIDs:
                    [],
                failure:
                    .timeMovedBackward
            )
        }


        // =============================================
        // No elapsed time
        // =============================================

        if
            let previousTime,

            newTime ==
                previousTime
        {

            return CompletedRouteProgressionResult(
                completedRoute:
                    completedRoute,
                appendedSegments:
                    [],
                newlyReachedNodeIDs:
                    [],
                failure:
                    nil
            )
        }


        /*
         Important:

         Even if there is currently no route,
         throughTime still advances.

         This prevents a route created later from
         retroactively claiming old road history.
         */

        guard
            !activeRoute.isEmpty,

            activeRoute.isFullyPlanned
        else {

            updated.throughTime =
                newTime


            return CompletedRouteProgressionResult(
                completedRoute:
                    updated,
                appendedSegments:
                    [],
                newlyReachedNodeIDs:
                    [],
                failure:
                    nil
            )
        }


        // =============================================
        // Effective beginning of this advancement
        // =============================================

        let effectiveStartTime =
            effectiveStart(
                previousTime:
                    previousTime,
                routeActivatedAt:
                    routeActivatedAt
            )


        /*
         The route may have been activated after
         newTime in tests/simulations.
         */

        if
            let effectiveStartTime,

            effectiveStartTime >=
                newTime
        {

            updated.throughTime =
                newTime


            return CompletedRouteProgressionResult(
                completedRoute:
                    updated,
                appendedSegments:
                    [],
                newlyReachedNodeIDs:
                    [],
                failure:
                    nil
            )
        }


        // =============================================
        // Freeze newly elapsed road geometry
        // =============================================

        let newSegments =
            GameRouteProgressResolver
                .newlyCompletedSegments(
                    of:
                        activeRoute,
                    after:
                        effectiveStartTime,
                    through:
                        newTime,
                    graph:
                        roadGraph,
                    policy:
                        timePolicy
                )


        // =============================================
        // Determine newly reached stops
        // =============================================

        let reachedNodes =
            newlyReachedNodes(
                route:
                    activeRoute,
                after:
                    effectiveStartTime,
                through:
                    newTime,
                gameNodes:
                    gameNodes,
                roadGraph:
                    roadGraph
            )


        updated.append(
            segments:
                newSegments
        )


        updated.appendReachedNodes(
            reachedNodes
        )


        // =============================================
        // Current route boundary
        // =============================================

        let snapshot =
            GameRouteProgressResolver
                .snapshot(
                    of:
                        activeRoute,
                    at:
                        newTime,
                    gameNodes:
                        gameNodes,
                    graph:
                        roadGraph,
                    policy:
                        timePolicy
                )


        if let boundary =
            snapshot.boundary {

            updated.boundary =
                boundary
        }


        updated.throughTime =
            newTime


        return CompletedRouteProgressionResult(
            completedRoute:
                updated,
            appendedSegments:
                newSegments,
            newlyReachedNodeIDs:
                reachedNodes,
            failure:
                nil
        )
    }
}

private extension CompletedRouteProgressor {

    func effectiveStart(
        previousTime:
            DayTime?,
        routeActivatedAt:
            DayTime?
    ) -> DayTime? {

        switch (
            previousTime,
            routeActivatedAt
        ) {

        case let (
            previous?,
            activated?
        ):

            return max(
                previous,
                activated
            )


        case let (
            previous?,
            nil
        ):

            return previous


        case let (
            nil,
            activated?
        ):

            return activated


        case (
            nil,
            nil
        ):

            return nil
        }
    }
}


private extension CompletedRouteProgressor {

    func newlyReachedNodes(
        route:
            GameRoute,
        after startTime:
            DayTime?,
        through endTime:
            DayTime,
        gameNodes:
            [GameMapNode],
        roadGraph:
            RoadGraph
    ) -> [GameNodeID] {

        let lookup =
            Dictionary(
                uniqueKeysWithValues:
                    gameNodes.map {

                        (
                            $0.id,
                            $0
                        )
                    }
            )


        return route
            .stopNodeIDs
            .filter { nodeID in

                guard
                    let node =
                        lookup[
                            nodeID
                        ],

                    let coordinate =
                        GameNodePlacementResolver
                            .mapCoordinate(
                                for:
                                    node,
                                graph:
                                    roadGraph
                            )
                else {

                    return false
                }


                guard
                    coordinate.time <=
                        endTime
                else {

                    return false
                }


                if let startTime {

                    /*
                     Exclusive lower bound:
                     (startTime, endTime]
                     */

                    return coordinate.time >
                        startTime
                }


                return true
            }
    }
}
