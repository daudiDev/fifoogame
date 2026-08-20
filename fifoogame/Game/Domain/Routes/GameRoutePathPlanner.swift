//
//  GameRoutePathPlanner.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/19/26.
//


import Foundation


struct GameRoutePathPlanningIssue:
    Identifiable,
    Equatable,
    Sendable {

    let legIndex:
        Int


    let fromNodeID:
        GameNodeID


    let toNodeID:
        GameNodeID


    let message:
        String


    var id:
        String {

        "\(legIndex)-\(fromNodeID.rawValue)-\(toNodeID.rawValue)"
    }
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


        for index in
            plannedRoute.legs.indices {

            let leg =
                plannedRoute.legs[
                    index
                ]


            // =========================================
            // Resolve Nodes
            // =========================================

            guard
                let fromNode =
                    nodeLookup[
                        leg.fromNodeID
                    ],

                let toNode =
                    nodeLookup[
                        leg.toNodeID
                    ]
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
                            "One or both route nodes no longer exist."
                    )
                )


                continue
            }


            // =========================================
            // Resolve Road Anchors
            // =========================================

            guard let startAnchor =
                anchorResolver.resolve(
                    node:
                        fromNode,
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
                            "\(fromNode.content.title) is not on a routable road."
                    )
                )


                continue
            }


            guard let endAnchor =
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
                            "\(toNode.content.title) is not on a routable road."
                    )
                )


                continue
            }

            //MARK : todo ? time policy
            if timePolicy != nil {

                guard
                    endAnchor
                        .nodeCoordinate
                        .time
                    >=
                    startAnchor
                        .nodeCoordinate
                        .time
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
                                "\(toNode.content.title) occurs earlier in the day than \(fromNode.content.title)."
                        )
                    )


                    continue
                }
            }

            // =========================================
            // Find Road Path
            // =========================================

            guard let path =
                pathfinder.findPath(
                    from:
                        startAnchor,
                    to:
                        endAnchor,
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
                            timePolicy == nil
                            ?
                            "No traversable road path exists between \(fromNode.content.title) and \(toNode.content.title)."
                            :
                            "No forward-in-time road path exists between \(fromNode.content.title) and \(toNode.content.title)."
                    )
                )


                continue
            }


            plannedRoute
                .legs[index]
                .path =
                    path
        }


        return GameRoutePathPlanningResult(
            route:
                plannedRoute,
            issues:
                issues
        )
    }
}
