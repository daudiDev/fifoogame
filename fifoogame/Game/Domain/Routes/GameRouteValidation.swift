//
//  GameRouteValidationIssue.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/19/26.
//


//
//  GameRouteValidation.swift
//  Fifoo
//

import Foundation


struct GameRouteValidationIssue:
    Identifiable,
    Equatable,
    Sendable {

    enum Severity:
        Equatable,
        Sendable {

        case error
        case warning
    }


    let id:
        String


    let severity:
        Severity


    let message:
        String
}


struct GameRouteValidationResult:
    Equatable,
    Sendable {

    let issues:
        [GameRouteValidationIssue]


    var errors:
        [GameRouteValidationIssue] {

        issues.filter {

            $0.severity ==
                .error
        }
    }


    var warnings:
        [GameRouteValidationIssue] {

        issues.filter {

            $0.severity ==
                .warning
        }
    }


    var isValid:
        Bool {

        errors.isEmpty
    }
}

enum GameRouteValidator {

    static func validate(
        _ route:
            GameRoute,
        gameNodes:
            [GameMapNode],
        roadGraph:
            RoadGraph
    ) -> GameRouteValidationResult {

        var issues:
            [GameRouteValidationIssue] = []


        validateUniqueStops(
            route,
            issues:
                &issues
        )


        validateNodesExist(
            route,
            gameNodes:
                gameNodes,
            issues:
                &issues
        )


        validateRoadEligibility(
            route,
            gameNodes:
                gameNodes,
            roadGraph:
                roadGraph,
            issues:
                &issues
        )


        validateTimeOrder(
            route,
            gameNodes:
                gameNodes,
            roadGraph:
                roadGraph,
            issues:
                &issues
        )


        validateLegStructure(
            route,
            issues:
                &issues
        )


        return GameRouteValidationResult(
            issues:
                issues
        )
    }
}

private extension GameRouteValidator {

    static func validateUniqueStops(
        _ route:
            GameRoute,
        issues:
            inout [GameRouteValidationIssue]
    ) {

        let unique =
            Set(
                route.stopNodeIDs
            )


        guard
            unique.count ==
                route.stopNodeIDs.count
        else {

            issues.append(
                GameRouteValidationIssue(
                    id:
                        "route.duplicateStops",
                    severity:
                        .error,
                    message:
                        "A route cannot contain the same node more than once."
                )
            )

            return
        }
    }
}

private extension GameRouteValidator {

    static func validateNodesExist(
        _ route:
            GameRoute,
        gameNodes:
            [GameMapNode],
        issues:
            inout [GameRouteValidationIssue]
    ) {

        let availableIDs =
            Set(
                gameNodes.map(
                    \.id
                )
            )


        for nodeID in
            route.stopNodeIDs {

            guard
                availableIDs.contains(
                    nodeID
                )
            else {

                issues.append(
                    GameRouteValidationIssue(
                        id:
                            "route.nodeMissing.\(nodeID.rawValue.uuidString)",
                        severity:
                            .error,
                        message:
                            "A route stop references a node that no longer exists."
                    )
                )

                continue
            }
        }
    }
}

private extension GameRouteValidator {

    static func validateRoadEligibility(
        _ route:
            GameRoute,
        gameNodes:
            [GameMapNode],
        roadGraph:
            RoadGraph,
        issues:
            inout [GameRouteValidationIssue]
    ) {

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


        let resolver =
            GameNodeRouteAnchorResolver()


        for nodeID in
            route.stopNodeIDs {

            guard let node =
                lookup[
                    nodeID
                ]
            else {

                continue
            }


            guard
                resolver.resolve(
                    node:
                        node,
                    graph:
                        roadGraph
                )
                !=
                nil
            else {

                issues.append(
                    GameRouteValidationIssue(
                        id:
                            "route.nodeOffRoad.\(nodeID.rawValue.uuidString)",
                        severity:
                            .error,
                        message:
                            "\(node.content.title) is not positioned on a routable road."
                    )
                )

                continue
            }
        }
    }
}

private extension GameRouteValidator {

    static func validateTimeOrder(
        _ route:
            GameRoute,
        gameNodes:
            [GameMapNode],
        roadGraph:
            RoadGraph,
        issues:
            inout [GameRouteValidationIssue]
    ) {

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


        let resolver =
            GameNodeRouteAnchorResolver()


        var previousTime:
            DayTime?


        for nodeID in
            route.stopNodeIDs {

            guard
                let node =
                    lookup[
                        nodeID
                    ],

                let anchor =
                    resolver.resolve(
                        node:
                            node,
                        graph:
                            roadGraph
                    )
            else {

                continue
            }


            let time =
                anchor
                    .nodeCoordinate
                    .time


            if let previousTime {

                guard
                    time >=
                        previousTime
                else {

                    issues.append(
                        GameRouteValidationIssue(
                            id:
                                "route.backwardTime.\(nodeID.rawValue.uuidString)",
                            severity:
                                .error,
                            message:
                                "Route stops cannot move backward in time."
                        )
                    )

                    return
                }
            }


            previousTime =
                time
        }
    }
}

private extension GameRouteValidator {

    static func validateLegStructure(
        _ route:
            GameRoute,
        issues:
            inout [GameRouteValidationIssue]
    ) {

        guard
            route.legs.count ==
                route.expectedLegCount
        else {

            issues.append(
                GameRouteValidationIssue(
                    id:
                        "route.legCount",
                    severity:
                        .error,
                    message:
                        "The route leg count does not match its ordered stops."
                )
            )

            return
        }


        let expectedPairs =
            Array(
                zip(
                    route.stopNodeIDs,
                    route.stopNodeIDs
                        .dropFirst()
                )
            )


        for (
            index,
            pair
        ) in expectedPairs.enumerated() {

            let leg =
                route.legs[
                    index
                ]


            guard
                leg.fromNodeID ==
                    pair.0,

                leg.toNodeID ==
                    pair.1
            else {

                issues.append(
                    GameRouteValidationIssue(
                        id:
                            "route.legEndpoints.\(index)",
                        severity:
                            .error,
                        message:
                            "A route leg does not match the ordered route stops."
                    )
                )

                return
            }
        }
    }
}
