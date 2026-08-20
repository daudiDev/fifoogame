//
//  GameRouteProgressResolver.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/19/26.
//



import Foundation


enum GameRouteProgressResolver {

    static func snapshot(
        of route:
            GameRoute,
        at time:
            DayTime,
        gameNodes:
            [GameMapNode],
        graph:
            RoadGraph,
        policy:
            RouteTimePolicy = .dayMap
    ) -> GameRouteProgressSnapshot {

        let allSegments =
            route.allRoadSegments


        var completed:
            [RoadRouteSegment] = []


        var future:
            [RoadRouteSegment] = []


        var boundary:
            GameNodeRouteAnchor.RoadLocation?


        var enteredFuture =
            false


        // =============================================
        // Split road geometry
        // =============================================

        for segment in
            allSegments {

            if enteredFuture {

                future.append(
                    segment
                )

                continue
            }


            let split =
                RoadRouteTimeClipper
                    .split(
                        segment,
                        at:
                            time,
                        graph:
                            graph,
                        policy:
                            policy
                    )


            if let completedSegment =
                split.completed {

                completed.append(
                    completedSegment
                )


                boundary =
                    RoadLocationCanonicalizer
                        .canonical(
                            .edge(
                                edgeID:
                                    completedSegment.edgeID,
                                fraction:
                                    completedSegment.toFraction
                            ),
                            graph:
                                graph
                        )
            }


            if let futureSegment =
                split.future {

                future.append(
                    futureSegment
                )


                enteredFuture =
                    true


                if let splitBoundary =
                    split.boundary {

                    boundary =
                        splitBoundary
                }
            }
        }


        // =============================================
        // Gameplay Stops
        // =============================================

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


        var reachedNodeIDs:
            [GameNodeID] = []


        var futureNodeIDs:
            [GameNodeID] = []


        for nodeID in
            route.stopNodeIDs {

            guard
                let node =
                    nodeLookup[
                        nodeID
                    ],

                let coordinate =
                    GameNodePlacementResolver
                        .mapCoordinate(
                            for:
                                node,
                            graph:
                                graph
                        )
            else {

                continue
            }


            if coordinate.time <=
                time {

                reachedNodeIDs.append(
                    nodeID
                )

            } else {

                futureNodeIDs.append(
                    nodeID
                )
            }
        }


        // =============================================
        // Route can contain zero geometric segments,
        // for example two stops at same road position.
        // Use the last reached stop as boundary.
        // =============================================

        if
            boundary ==
                nil,

            let lastReachedID =
                reachedNodeIDs.last,

            let lastReachedNode =
                nodeLookup[
                    lastReachedID
                ],

            let anchor =
                GameNodeRouteAnchorResolver()
                    .resolve(
                        node:
                            lastReachedNode,
                        graph:
                            graph
                    )
        {

            boundary =
                anchor.roadLocation
        }


        return GameRouteProgressSnapshot(
            time:
                time,
            completedSegments:
                completed,
            futureSegments:
                future,
            reachedNodeIDs:
                reachedNodeIDs,
            futureNodeIDs:
                futureNodeIDs,
            boundary:
                boundary
        )
    }
}

extension GameRouteProgressResolver {

    static func newlyCompletedSegments(
        of route:
            GameRoute,
        after startTime:
            DayTime?,
        through endTime:
            DayTime,
        graph:
            RoadGraph,
        policy:
            RouteTimePolicy = .dayMap
    ) -> [RoadRouteSegment] {

        route.allRoadSegments
            .compactMap { segment in

                RoadRouteTimeClipper.portion(
                    of:
                        segment,
                    after:
                        startTime,
                    through:
                        endTime,
                    graph:
                        graph,
                    policy:
                        policy
                )
            }
    }
}


