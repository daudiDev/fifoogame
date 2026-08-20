//
//  RoadPathfinder.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/19/26.
//

import Foundation


struct RoadPathfinder {

    // =====================================================
    // MARK: - Public API
    // =====================================================

    func findPath(
        from start:
            GameNodeRouteAnchor,
        to end:
            GameNodeRouteAnchor,
        graph:
            RoadGraph,
        timePolicy:
            RouteTimePolicy? = .dayMap,
        routingOptions:
            RoadRoutingOptions = .standard
    ) -> RoadRoutePath? {

        // =================================================
        // Node-time ordering
        // =================================================

        if timePolicy != nil {

            guard
                end.nodeCoordinate.time
                >=
                start.nodeCoordinate.time
            else {

                return nil
            }
        }


        // =================================================
        // Candidate paths
        // =================================================

        var candidates:
            [RoadRoutePath] = []


        // =================================================
        // Same-edge direct path
        // =================================================

        if let direct =
            directSameEdgePath(
                from:
                    start,
                to:
                    end,
                graph:
                    graph,
                timePolicy:
                    timePolicy,
                routingOptions: routingOptions
            )
        {

            candidates.append(
                direct
            )
        }


        // =================================================
        // Graph endpoints
        // =================================================

        let starts =
            startCandidates(
                for:
                    start,
                graph:
                    graph,
                timePolicy:
                    timePolicy,
                routingOptions: routingOptions
            )


        let ends =
            endCandidates(
                for:
                    end,
                graph:
                    graph,
                timePolicy:
                    timePolicy,
                routingOptions: routingOptions
            )


        // ... existing candidate search continues

        // =============================================
        // Search all valid endpoint combinations
        // =============================================

        for startCandidate in
            starts {

            for endCandidate in
                ends {

                let middlePath:
                    VertexPath?


                if
                    startCandidate.vertexID
                    ==
                    endCandidate.vertexID
                {

                    middlePath =
                        shortestVertexPath(
                            from:
                                startCandidate
                                    .vertexID,
                            to:
                                endCandidate
                                    .vertexID,
                            graph:
                                graph,
                            timePolicy:
                                timePolicy,
                            routingOptions: routingOptions
                        )

                } else {

                    middlePath =
                        shortestVertexPath(
                            from:
                                startCandidate
                                    .vertexID,
                            to:
                                endCandidate
                                    .vertexID,
                            graph:
                                graph,
                            timePolicy: timePolicy,
                            routingOptions: routingOptions
                        )
                }


                guard let middlePath else {

                    continue
                }


                let segments =
                    startCandidate.segments
                    +
                    middlePath.segments
                    +
                    endCandidate.segments


                let totalCost =
                    startCandidate.cost
                    +
                    middlePath.cost
                    +
                    endCandidate.cost


                let path =
                    RoadRoutePath(
                        startLocation:
                            start.roadLocation,
                        endLocation:
                            end.roadLocation,
                        vertexIDs:
                            middlePath.vertexIDs,
                        segments:
                            segments,
                        totalCost:
                            totalCost
                    )
                
                if let timePolicy {

                    guard
                        RoadRouteTimeValidator
                            .isForwardInTime(
                                path:
                                    path,
                                graph:
                                    graph,
                                policy:
                                    timePolicy
                            )
                    else {

                        continue
                    }
                }

                candidates.append(
                    path
                )
            }
        }


        return candidates.min {

            $0.totalCost <
                $1.totalCost
        }
    }
}

private extension RoadPathfinder {

    struct EndpointCandidate {

        let vertexID:
            RoadVertexID


        let segments:
            [RoadRouteSegment]


        let cost:
            Double
    }


    struct VertexPath {

        let vertexIDs:
            [RoadVertexID]


        let segments:
            [RoadRouteSegment]


        let cost:
            Double
    }
}

private extension RoadPathfinder {

    func startCandidates(
        for anchor:
            GameNodeRouteAnchor,
        graph:
            RoadGraph,
        timePolicy:
            RouteTimePolicy?,
        routingOptions:
            RoadRoutingOptions
    ) -> [EndpointCandidate] {

        switch anchor.roadLocation {

        // =============================================
        // Vertex
        // =============================================

        case let .vertex(
            vertexID
        ):

            return [
                EndpointCandidate(
                    vertexID:
                        vertexID,
                    segments:
                        [],
                    cost:
                        0
                )
            ]


        // =============================================
        // Edge
        // =============================================

        case let .edge(
            edgeID,
            fraction
        ):

            guard
                let edge =
                    graph.edge(
                        id:
                            edgeID
                    ),

                    edgeCanRoute(
                        edge,
                        routingOptions:
                            routingOptions
                    )
            else {

                return []
            }


            let fullCost =
                    edgeCost(
                        edge,
                        graph:
                            graph,
                        routingOptions:
                            routingOptions
                    )


            var result:
                [EndpointCandidate] = []


            // =========================================
            // Travel toward toID
            // =========================================
            if allowsForward(edge) {

                let segment =
                    RoadRouteSegment(
                        edgeID:
                            edge.id,
                        fromFraction:
                            fraction,
                        toFraction:
                            1
                    )


                if
                    fraction >= 1

                    ||

                    segmentIsAllowed(
                        segment,
                        graph:
                            graph,
                        timePolicy:
                            timePolicy
                    )
                {

                    result.append(
                        EndpointCandidate(
                            vertexID:
                                edge.toID,
                            segments:
                                fraction < 1
                                ? [
                                    segment
                                ]
                                : [],
                            cost:
                                fullCost
                                *
                                (
                                    1
                                    -
                                    fraction
                                )
                        )
                    )
                }
            }


            // =========================================
            // Travel toward fromID
            // =========================================

            if allowsReverse(
                edge
            ) {

                let segment =
                    RoadRouteSegment(
                        edgeID:
                            edge.id,
                        fromFraction:
                            fraction,
                        toFraction:
                            0
                    )


                if
                    fraction <= 0

                    ||

                    segmentIsAllowed(
                        segment,
                        graph:
                            graph,
                        timePolicy:
                            timePolicy
                    )
                {

                    result.append(
                        EndpointCandidate(
                            vertexID:
                                edge.fromID,
                            segments:
                                fraction > 0
                                ? [
                                    segment
                                ]
                                : [],
                            cost:
                                fullCost
                                *
                                fraction
                        )
                    )
                }
            }


            return result
        }
    }
}

private extension RoadPathfinder {

    func endCandidates(
        for anchor:
            GameNodeRouteAnchor,
        graph:
            RoadGraph,
        timePolicy:
            RouteTimePolicy?,
        routingOptions:
            RoadRoutingOptions
    ) -> [EndpointCandidate] {

        switch anchor.roadLocation {

        // =============================================
        // Vertex
        // =============================================

        case let .vertex(
            vertexID
        ):

            return [
                EndpointCandidate(
                    vertexID:
                        vertexID,
                    segments:
                        [],
                    cost:
                        0
                )
            ]


        // =============================================
        // Edge
        // =============================================

        case let .edge(
            edgeID,
            fraction
        ):

            guard
                let edge =
                    graph.edge(
                        id:
                            edgeID
                    ),

                    edgeCanRoute(
                        edge,
                        routingOptions:
                            routingOptions
                    )
            else {

                return []
            }


            let fullCost =
            edgeCost(
                edge,
                graph:
                    graph,
                routingOptions:
                    routingOptions
            )


            var result:
                [EndpointCandidate] = []


            // =========================================
            // Arrive from fromID
            // =========================================

            if allowsForward(
                edge
            ) {

                let segment =
                    RoadRouteSegment(
                        edgeID:
                            edge.id,
                        fromFraction:
                            0,
                        toFraction:
                            fraction
                    )


                if
                    fraction <= 0

                    ||

                    segmentIsAllowed(
                        segment,
                        graph:
                            graph,
                        timePolicy:
                            timePolicy
                    )
                {

                    result.append(
                        EndpointCandidate(
                            vertexID:
                                edge.fromID,
                            segments:
                                fraction > 0
                                ? [
                                    segment
                                ]
                                : [],
                            cost:
                                fullCost
                                *
                                fraction
                        )
                    )
                }
            }


            // =========================================
            // Arrive from toID
            // =========================================

            if allowsReverse(
                edge
            ) {

                let segment =
                    RoadRouteSegment(
                        edgeID:
                            edge.id,
                        fromFraction:
                            1,
                        toFraction:
                            fraction
                    )


                if
                    fraction >= 1

                    ||

                    segmentIsAllowed(
                        segment,
                        graph:
                            graph,
                        timePolicy:
                            timePolicy
                    )
                {

                    result.append(
                        EndpointCandidate(
                            vertexID:
                                edge.toID,
                            segments:
                                fraction < 1
                                ? [
                                    segment
                                ]
                                : [],
                            cost:
                                fullCost
                                *
                                (
                                    1
                                    -
                                    fraction
                                )
                        )
                    )
                }
            }


            return result
        }
    }
}

private extension RoadPathfinder {

    func directSameEdgePath(
        from start:
            GameNodeRouteAnchor,
        to end:
            GameNodeRouteAnchor,
        graph:
            RoadGraph,
        timePolicy:
            RouteTimePolicy?,
        routingOptions:
            RoadRoutingOptions
    ) -> RoadRoutePath? {

        guard
            case let .edge(
                startEdgeID,
                startFraction
            ) =
                start.roadLocation,

            case let .edge(
                endEdgeID,
                endFraction
            ) =
                end.roadLocation,

            startEdgeID ==
                endEdgeID,

            let edge =
                graph.edge(
                    id:
                        startEdgeID
                ),

                edgeCanRoute(
                    edge,
                    routingOptions:
                        routingOptions
                )
        else {

            return nil
        }


        let delta =
            endFraction
            -
            startFraction


        // =============================================
        // Same position
        // =============================================

        if abs(delta) <
            0.000_001 {

            return RoadRoutePath(
                startLocation:
                    start.roadLocation,
                endLocation:
                    end.roadLocation,
                vertexIDs:
                    [],
                segments:
                    [],
                totalCost:
                    0
            )
        }


        // =============================================
        // Forward
        // =============================================

        if delta > 0 {

            guard
                allowsForward(
                    edge
                    )
            else {

                return nil
            }

        } else {

            // =========================================
            // Reverse
            // =========================================

            guard
                allowsReverse(
                    edge
                )
            else {

                return nil
            }
        }


        let cost =
        edgeCost(
            edge,
            graph:
                graph,
            routingOptions:
                routingOptions
        )
            *
            abs(
                delta
            )
        
        let segment =
            RoadRouteSegment(
                edgeID:
                    edge.id,
                fromFraction:
                    startFraction,
                toFraction:
                    endFraction
            )


        guard
            segmentIsAllowed(
                segment,
                graph:
                    graph,
                timePolicy:
                    timePolicy
            )
        else {

            return nil
        }


        return RoadRoutePath(
            startLocation:
                start.roadLocation,
            endLocation:
                end.roadLocation,
            vertexIDs:
                [],
            segments:
                [
                    RoadRouteSegment(
                        edgeID:
                            edge.id,
                        fromFraction:
                            startFraction,
                        toFraction:
                            endFraction
                    )
                ],
            totalCost:
                cost
        )
    }
}

private extension RoadPathfinder {

    func edgeCanRoute(
        _ edge:
            RoadEdge
    ) -> Bool {

        edge.attributes
            .isTraversable

        &&

        edge.travelDirection
            !=
            .closed
    }


    func allowsForward(
        _ edge:
            RoadEdge
    ) -> Bool {

        guard
            edgeCanRoute(
                edge
            )
        else {

            return false
        }


        switch edge.travelDirection {

        case .bidirectional,
             .fromTo:

            return true


        case .toFrom,
             .closed:

            return false
        }
    }


    func allowsReverse(
        _ edge:
            RoadEdge
    ) -> Bool {

        guard
            edgeCanRoute(
                edge
            )
        else {

            return false
        }


        switch edge.travelDirection {

        case .bidirectional,
             .toFrom:

            return true


        case .fromTo,
             .closed:

            return false
        }
    }
}

private extension RoadPathfinder {

    func edgeCost(
        _ edge:
            RoadEdge,
        graph:
            RoadGraph,
        routingOptions:
            RoadRoutingOptions
    ) -> Double {

        let geometricLength =
            RoadEdgeGeometry
                .length(
                    of:
                        edge,
                    graph:
                        graph
                )


        let normalRoutingCost =
            geometricLength
            *
            edge.attributes
                .routingCostMultiplier


        let alternativePenalty =
            routingOptions
                .costMultiplier(
                    for:
                        edge.id
                )


        return normalRoutingCost
        *
        alternativePenalty
    }
}

private extension RoadPathfinder {

    struct GraphConnection {

        let destination:
            RoadVertexID


        let segment:
            RoadRouteSegment


        let cost:
            Double
    }


    func outgoingConnections(
        from vertexID:
            RoadVertexID,
        graph:
            RoadGraph,
        timePolicy:
            RouteTimePolicy?,
        routingOptions:
            RoadRoutingOptions
    ) -> [GraphConnection] {

        var result:
            [GraphConnection] = []


        for edge in graph.edges {

            guard
                edgeCanRoute(
                    edge
                )
            else {

                continue
            }


            let cost =
            edgeCost(
                edge,
                graph:
                    graph,
                routingOptions:
                    routingOptions
            )


            // =========================================
            // fromID -> toID
            // =========================================

            if
                edge.fromID ==
                    vertexID,

                    allowsForward(
                        edge,
                        routingOptions:
                            routingOptions
                    )
            {

                let segment =
                    RoadRouteSegment(
                        edgeID:
                            edge.id,
                        fromFraction:
                            0,
                        toFraction:
                            1
                    )


                guard
                    segmentIsAllowed(
                        segment,
                        graph:
                            graph,
                        timePolicy:
                            timePolicy
                    )
                else {

                    continue
                }


                result.append(
                    GraphConnection(
                        destination:
                            edge.toID,
                        segment:
                            segment,
                        cost:
                            cost
                    )
                )
            }


            // =========================================
            // toID -> fromID
            // =========================================

            if
                edge.toID ==
                    vertexID,

                allowsReverse(
                    edge,
                    routingOptions:
                           routingOptions
                )
            {

                let segment =
                    RoadRouteSegment(
                        edgeID:
                            edge.id,
                        fromFraction:
                            1,
                        toFraction:
                            0
                    )


                guard
                    segmentIsAllowed(
                        segment,
                        graph:
                            graph,
                        timePolicy:
                            timePolicy
                    )
                else {

                    continue
                }


                result.append(
                    GraphConnection(
                        destination:
                            edge.fromID,
                        segment:
                            segment,
                        cost:
                            cost
                    )
                )
            }
        }


        return result
    }
}

private extension RoadPathfinder {

    struct QueueItem {

        let vertexID:
            RoadVertexID


        let cost:
            Double
    }


    struct MinHeap {

        private var storage:
            [QueueItem] = []


        var isEmpty:
            Bool {

            storage.isEmpty
        }


        mutating func push(
            _ item:
                QueueItem
        ) {

            storage.append(
                item
            )


            siftUp(
                from:
                    storage.count - 1
            )
        }


        mutating func pop()
            -> QueueItem? {

            guard
                !storage.isEmpty
            else {

                return nil
            }


            if storage.count ==
                1 {

                return storage.removeLast()
            }


            let result =
                storage[0]


            storage[0] =
                storage.removeLast()


            siftDown(
                from:
                    0
            )


            return result
        }


        private mutating func siftUp(
            from index:
                Int
        ) {

            var child =
                index


            while child > 0 {

                let parent =
                    (
                        child - 1
                    )
                    /
                    2


                guard
                    storage[child].cost
                    <
                    storage[parent].cost
                else {

                    break
                }


                storage.swapAt(
                    child,
                    parent
                )


                child =
                    parent
            }
        }


        private mutating func siftDown(
            from index:
                Int
        ) {

            var parent =
                index


            while true {

                let left =
                    parent * 2
                    +
                    1


                let right =
                    left + 1


                var candidate =
                    parent


                if
                    left <
                        storage.count,

                    storage[left].cost
                    <
                    storage[candidate].cost
                {

                    candidate =
                        left
                }


                if
                    right <
                        storage.count,

                    storage[right].cost
                    <
                    storage[candidate].cost
                {

                    candidate =
                        right
                }


                guard
                    candidate !=
                        parent
                else {

                    return
                }


                storage.swapAt(
                    parent,
                    candidate
                )


                parent =
                    candidate
            }
        }
    }
}

private extension RoadPathfinder {

    struct PreviousStep {

        let previousVertex:
            RoadVertexID


        let segment:
            RoadRouteSegment
    }


    func shortestVertexPath(
        from start:
            RoadVertexID,
        to destination:
            RoadVertexID,
        graph:
            RoadGraph,
        timePolicy:
            RouteTimePolicy?,
        routingOptions:
            RoadRoutingOptions
    ) -> VertexPath? {

        // =============================================
        // Distance table
        // =============================================

        var distances:
            [RoadVertexID: Double] = [

                start:
                    0
            ]


        var previous:
            [RoadVertexID: PreviousStep] = [:]


        var queue =
            MinHeap()


        queue.push(
            QueueItem(
                vertexID:
                    start,
                cost:
                    0
            )
        )


        // =============================================
        // Search
        // =============================================

        while let current =
            queue.pop() {

            let knownCost =
                distances[
                    current.vertexID
                ]
                ??
                .greatestFiniteMagnitude


            /*
             Ignore stale heap entries.
             */

            guard
                current.cost <=
                    knownCost
            else {

                continue
            }


            if
                current.vertexID ==
                    destination
            {

                break
            }


            let connections =
                outgoingConnections(
                    from:
                        current.vertexID,
                    graph:
                        graph,
                    timePolicy:
                        timePolicy,
                    routingOptions: routingOptions
                )


            for connection in
                connections {

                let newCost =
                    current.cost
                    +
                    connection.cost


                let existingCost =
                    distances[
                        connection.destination
                    ]
                    ??
                    .greatestFiniteMagnitude


                guard
                    newCost <
                        existingCost
                else {

                    continue
                }


                distances[
                    connection.destination
                ] =
                    newCost


                previous[
                    connection.destination
                ] =
                    PreviousStep(
                        previousVertex:
                            current.vertexID,
                        segment:
                            connection.segment
                    )


                queue.push(
                    QueueItem(
                        vertexID:
                            connection.destination,
                        cost:
                            newCost
                    )
                )
            }
        }


        guard let totalCost =
            distances[
                destination
            ]
        else {

            return nil
        }


        // =============================================
        // Reconstruct path
        // =============================================

        var reversedVertices:
            [RoadVertexID] = [

                destination
            ]


        var reversedSegments:
            [RoadRouteSegment] = []


        var current =
            destination


        while
            current !=
                start {

            guard let step =
                previous[
                    current
                ]
            else {

                return nil
            }


            reversedSegments.append(
                step.segment
            )


            current =
                step.previousVertex


            reversedVertices.append(
                current
            )
        }


        return VertexPath(
            vertexIDs:
                Array(
                    reversedVertices.reversed()
                ),
            segments:
                Array(
                    reversedSegments.reversed()
                ),
            cost:
                totalCost
        )
    }
}

private extension RoadPathfinder {

    func segmentIsAllowed(
        _ segment:
            RoadRouteSegment,
        graph:
            RoadGraph,
        timePolicy:
            RouteTimePolicy?
    ) -> Bool {

        guard let timePolicy else {

            /*
             Pure geometric routing mode.
             */

            return true
        }


        return RoadRouteTimeValidator
            .isForwardInTime(
                segment:
                    segment,
                graph:
                    graph,
                policy:
                    timePolicy
            )
    }
}

private extension RoadPathfinder {

    func edgeCanRoute(
        _ edge:
            RoadEdge,
        routingOptions:
            RoadRoutingOptions
    ) -> Bool {

        guard
            !routingOptions
                .isExcluded(
                    edge.id
                )
        else {

            return false
        }


        return
            edge.attributes
                .isTraversable
            &&
            edge.travelDirection
                !=
                .closed
    }
}

private extension RoadPathfinder {

    func allowsForward(
        _ edge:
            RoadEdge,
        routingOptions:
            RoadRoutingOptions
    ) -> Bool {

        guard
            edgeCanRoute(
                edge,
                routingOptions:
                    routingOptions
            )
        else {

            return false
        }


        switch edge.travelDirection {

        case .bidirectional,
             .fromTo:

            return true


        case .toFrom,
             .closed:

            return false
        }
    }


    func allowsReverse(
        _ edge:
            RoadEdge,
        routingOptions:
            RoadRoutingOptions
    ) -> Bool {

        guard
            edgeCanRoute(
                edge,
                routingOptions:
                    routingOptions
            )
        else {

            return false
        }


        switch edge.travelDirection {

        case .bidirectional,
             .toFrom:

            return true


        case .fromTo,
             .closed:

            return false
        }
    }
}
