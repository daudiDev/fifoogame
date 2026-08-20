//
//  FutureRouteDraftValidation.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/19/26.
//


import Foundation


enum FutureRouteDraftValidationIssue:
    Equatable,
    Sendable {

    case tooFewStops

    case duplicateStop(
        nodeID:
            GameNodeID
    )

    case nodeNotFound(
        nodeID:
            GameNodeID
    )

    case nodeDisabled(
        nodeID:
            GameNodeID
    )

    case nodeNotRouteEligible(
        nodeID:
            GameNodeID
    )

    case stopIsInPast(
        nodeID:
            GameNodeID
    )

    case stopsOutOfTimeOrder(
        earlierNodeID:
            GameNodeID,
        laterNodeID:
            GameNodeID
    )
}

struct FutureRouteDraftValidationResult:
    Equatable,
    Sendable {

    let issues:
        [FutureRouteDraftValidationIssue]


    var isValid:
        Bool {

        issues.isEmpty
    }
}

enum FutureRouteDraftValidator {

    static func validate(
        _ draft:
            FutureRouteDraft,
        gameNodes:
            [GameMapNode],
        roadGraph:
            RoadGraph,
        currentTime:
            DayTime
    ) -> FutureRouteDraftValidationResult {

        var issues:
            [FutureRouteDraftValidationIssue] = []


        // =================================================
        // Need at least two stops
        // =================================================

        if draft.stopNodeIDs.count < 2 {

            issues.append(
                .tooFewStops
            )
        }


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


        var seen =
            Set<GameNodeID>()


        var previousNode:
            GameMapNode?


        // =================================================
        // Validate each ordered stop
        // =================================================

        for nodeID in
            draft.stopNodeIDs {

            // ---------------------------------------------
            // Duplicate
            // ---------------------------------------------

            if !seen.insert(
                nodeID
            ).inserted {

                issues.append(
                    .duplicateStop(
                        nodeID:
                            nodeID
                    )
                )

                continue
            }


            // ---------------------------------------------
            // Exists
            // ---------------------------------------------

            guard let node =
                nodeLookup[
                    nodeID
                ]
            else {

                issues.append(
                    .nodeNotFound(
                        nodeID:
                            nodeID
                    )
                )

                continue
            }


            // ---------------------------------------------
            // Enabled
            // ---------------------------------------------

            guard node.isEnabled else {

                issues.append(
                    .nodeDisabled(
                        nodeID:
                            nodeID
                    )
                )

                continue
            }


            // ---------------------------------------------
            // Actual Road Eligibility
            // ---------------------------------------------

            guard
                anchorResolver.resolve(
                    node:
                        node,
                    graph:
                        roadGraph
                )
                != nil
            else {

                issues.append(
                    .nodeNotRouteEligible(
                        nodeID:
                            nodeID
                    )
                )

                continue
            }


            // ---------------------------------------------
            // Semantic Map Coordinate
            // ---------------------------------------------

            guard let coordinate =
                GameNodePlacementResolver
                    .mapCoordinate(
                        for:
                            node,
                        graph:
                            roadGraph
                    )
            else {

                issues.append(
                    .nodeNotRouteEligible(
                        nodeID:
                            nodeID
                    )
                )

                continue
            }


            // ---------------------------------------------
            // Future route stops should not be in the past.
            // Same-time stops are allowed.
            // ---------------------------------------------

            if coordinate.time <
                currentTime {

                issues.append(
                    .stopIsInPast(
                        nodeID:
                            nodeID
                    )
                )
            }


            // ---------------------------------------------
            // Chronological ordering
            // ---------------------------------------------

            if
                let previousNode,

                let previousCoordinate =
                    GameNodePlacementResolver
                        .mapCoordinate(
                            for:
                                previousNode,
                            graph:
                                roadGraph
                        ),

                coordinate.time <
                    previousCoordinate.time
            {

                issues.append(
                    .stopsOutOfTimeOrder(
                        earlierNodeID:
                            previousNode.id,
                        laterNodeID:
                            node.id
                    )
                )
            }


            previousNode =
                node
        }


        return FutureRouteDraftValidationResult(
            issues:
                issues
        )
    }
}
