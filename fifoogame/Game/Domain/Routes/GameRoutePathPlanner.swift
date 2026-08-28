//
//  GameRoutePathPlanner.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/19/26.
//


import Foundation


struct GameRoutePathPlanningIssue:
    Codable,
    Equatable,
    Sendable {

    let legIndex:
        Int

    let fromNodeID:
        GameNodeID?

    let toNodeID:
        GameNodeID

    let message:
        String
}


struct GameRoutePathPlanningResult:
    Equatable,
    Sendable {

    let route:
        GameRoute


    let issues:
        [GameRoutePathPlanningIssue]


    var succeeded:
        Bool {

        issues.isEmpty
        &&
        route.isFullyPlanned
    }
}

struct GameRoutePathPlanner {

    private let pathfinder =
        RoadPathfinder()


    let timePolicy:
        RouteTimePolicy?


    let routingOptions:
        RoadRoutingOptions


    init(
        timePolicy:
            RouteTimePolicy? = .dayMap,
        routingOptions:
            RoadRoutingOptions = .standard
    ) {

        self.timePolicy =
            timePolicy

        self.routingOptions =
            routingOptions
    }


    private let anchorResolver =
        GameNodeRouteAnchorResolver()


    func plan(
        route:
            GameRoute,
        gameNodes:
            [GameMapNode],
        roadGraph:
            RoadGraph
    ) -> GameRoutePathPlanningResult {

        var plannedRoute =
            route


        var issues:
            [GameRoutePathPlanningIssue] = []


        let nodeLookup =
            Dictionary(
                uniqueKeysWithValues:
                    gameNodes.map {

                        (
                            $0.id,
                            $0
                        )
                    }
            )


        let anchorResolver =
            GameNodeRouteAnchorResolver()


        // =====================================================
        // ENTRY LEG
        // =====================================================

        if var entryLeg =
            plannedRoute.entryLeg {

            guard
                let destinationNode =
                    nodeLookup[
                        entryLeg.toNodeID
                    ],

                let destinationAnchor =
                    anchorResolver.resolve(
                        node:
                            destinationNode,
                        graph:
                            roadGraph
                    )
            else {

                issues.append(
                    GameRoutePathPlanningIssue(
                        legIndex:
                            -1,
                        fromNodeID:
                            nil,
                        toNodeID:
                            entryLeg.toNodeID,
                        message:
                            "Unable to resolve the first path stop."
                    )
                )


                return GameRoutePathPlanningResult(
                    route:
                        plannedRoute,
                    issues:
                        issues
                )
            }


            guard let path =
                pathfinder.findPath(
                    from:
                        entryLeg.startAnchor,
                    to:
                        destinationAnchor
                            .roadRouteAnchor,
                    graph:
                        roadGraph,
                    timePolicy:
                        timePolicy,
                    routingOptions:
                        routingOptions
                )
            else {

                issues.append(
                    GameRoutePathPlanningIssue(
                        legIndex:
                            -1,
                        fromNodeID:
                            nil,
                        toNodeID:
                            entryLeg.toNodeID,
                        message:
                            "No valid forward-time road path exists from the current position to the first stop."
                    )
                )


                return GameRoutePathPlanningResult(
                    route:
                        plannedRoute,
                    issues:
                        issues
                )
            }


            entryLeg.path =
                path


            plannedRoute.entryLeg =
                entryLeg
        }


        // =====================================================
        // NORMAL NODE → NODE LEGS
        // =====================================================

        for index in
            plannedRoute.legs.indices {

            var leg =
                plannedRoute.legs[
                    index
                ]


            guard
                let fromNode =
                    nodeLookup[
                        leg.fromNodeID
                    ],

                let toNode =
                    nodeLookup[
                        leg.toNodeID
                    ],

                let fromAnchor =
                    anchorResolver.resolve(
                        node:
                            fromNode,
                        graph:
                            roadGraph
                    ),

                let toAnchor =
                    anchorResolver.resolve(
                        node:
                            toNode,
                        graph:
                            roadGraph
                    )
            else {

                issues.append(
                    GameRoutePathPlanningIssue(
                        legIndex:
                            index,
                        fromNodeID:
                            leg.fromNodeID,
                        toNodeID:
                            leg.toNodeID,
                        message:
                            "Unable to resolve path anchors."
                    )
                )

                continue
            }


            guard let path =
                pathfinder.findPath(
                    from:
                        fromAnchor,
                    to:
                        toAnchor,
                    graph:
                        roadGraph,
                    timePolicy:
                        timePolicy,
                    routingOptions:
                        routingOptions
                )
            else {

                issues.append(
                    GameRoutePathPlanningIssue(
                        legIndex:
                            index,
                        fromNodeID:
                            leg.fromNodeID,
                        toNodeID:
                            leg.toNodeID,
                        message:
                            "No valid forward-time road path exists for this leg."
                    )
                )

                continue
            }


            leg.path =
                path


            plannedRoute.legs[
                index
            ] =
                leg
        }


        return GameRoutePathPlanningResult(
            route:
                plannedRoute,
            issues:
                issues
        )
    }
}
