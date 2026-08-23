//
//  RoadPathfinder.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/22/26.
//


import Foundation


/// Pathfinding for the redesigned Fifoo Cartesian street grid.
///
/// Route rules are intentionally stricter than the physical road graph:
///
///     LEFT   allowed
///     RIGHT  allowed
///     DOWN   allowed
///     UP     never allowed
///
/// Search is direction-aware so the selected route also prefers long,
/// simple street runs over visually noisy zig-zags.
struct RoadPathfinder {

    // =====================================================
    // MARK: - Public Find Path
    // =====================================================

    func findPath(
        from start: GameNodeRouteAnchor,
        to end: GameNodeRouteAnchor,
        graph: RoadGraph,
        timePolicy: RouteTimePolicy? = .dayMap,
        routingOptions: RoadRoutingOptions = .standard
    ) -> RoadRoutePath? {

        findPath(
            from:
                start.roadRouteAnchor,
            to:
                end.roadRouteAnchor,
            graph:
                graph,
            timePolicy:
                timePolicy,
            routingOptions:
                routingOptions
        )
    }


    func findPath(
        from start: RoadRouteAnchor,
        to end: RoadRouteAnchor,
        graph: RoadGraph,
        timePolicy: RouteTimePolicy? = .dayMap,
        routingOptions: RoadRoutingOptions = .standard
    ) -> RoadRoutePath? {

        // The new route algorithm intentionally targets the deterministic
        // Cartesian graph introduced in Step 4.
        guard graph.id == GridRoadGraph.graphID else {
            return nil
        }


        // A destination earlier than the route start can never be reached
        // without upward-time travel.
        guard
            end.coordinate.time
            >=
            start.coordinate.time
        else {
            return nil
        }


        let lookup =
            GraphLookup(
                graph:
                    graph,
                routingOptions:
                    routingOptions
            )


        // A direct same-edge result is a candidate, not an automatic
        // winner. This matters for alternate-route generation when that
        // edge has intentionally been assigned a large penalty.
        var bestPath =
            directSameEdgePath(
                from:
                    start,
                to:
                    end,
                graph:
                    graph,
                lookup:
                    lookup,
                timePolicy:
                    timePolicy,
                routingOptions:
                    routingOptions
            )


        var bestCost =
            bestPath?
                .totalCost
            ??
            .greatestFiniteMagnitude


        let startCandidates =
            startCandidates(
                for:
                    start,
                graph:
                    graph,
                lookup:
                    lookup,
                timePolicy:
                    timePolicy,
                routingOptions:
                    routingOptions
            )


        let endCandidates =
            endCandidates(
                for:
                    end,
                graph:
                    graph,
                lookup:
                    lookup,
                timePolicy:
                    timePolicy,
                routingOptions:
                    routingOptions
            )


        guard
            !startCandidates.isEmpty,
            !endCandidates.isEmpty
        else {
            return bestPath
        }


        for startCandidate in startCandidates {

            for endCandidate in endCandidates {

                let middlePath: VertexPath?


                if
                    startCandidate.vertexID
                    ==
                    endCandidate.vertexID
                {

                    middlePath =
                        zeroLengthVertexPath(
                            at:
                                startCandidate.vertexID,
                            initialDirection:
                                startCandidate.boundaryDirection,
                            terminalDirection:
                                endCandidate.boundaryDirection,
                            routingOptions:
                                routingOptions
                        )

                } else {

                    middlePath =
                        shortestVertexPath(
                            from:
                                startCandidate.vertexID,
                            to:
                                endCandidate.vertexID,
                            initialDirection:
                                startCandidate.boundaryDirection,
                            terminalDirection:
                                endCandidate.boundaryDirection,
                            graph:
                                graph,
                            lookup:
                                lookup,
                            timePolicy:
                                timePolicy,
                            routingOptions:
                                routingOptions
                        )
                }


                guard let middlePath else {
                    continue
                }


                let segments =
                    startCandidate.segments
                    + middlePath.segments
                    + endCandidate.segments


                let totalCost =
                    startCandidate.cost
                    + middlePath.cost
                    + endCandidate.cost


                guard totalCost < bestCost else {
                    continue
                }


                let candidate =
                    RoadRoutePath(
                        startLocation:
                            start.roadLocation,
                        endLocation:
                            end.roadLocation,
                        vertexIDs:
                            deduplicatedAdjacent(
                                middlePath.vertexIDs
                            ),
                        segments:
                            segments,
                        totalCost:
                            totalCost
                    )


                guard
                    pathObeysGridRouteRules(
                        candidate,
                        graph:
                            graph,
                        lookup:
                            lookup,
                        routingOptions:
                            routingOptions
                    )
                else {
                    continue
                }


                if let timePolicy {

                    guard
                        RoadRouteTimeValidator
                            .isForwardInTime(
                                path:
                                    candidate,
                                graph:
                                    graph,
                                policy:
                                    timePolicy
                            )
                    else {
                        continue
                    }
                }


                bestPath =
                    candidate

                bestCost =
                    totalCost
            }
        }


        return bestPath
    }
}


// =====================================================
// MARK: - Internal Models
// =====================================================

private extension RoadPathfinder {

    struct EndpointCandidate {

        let vertexID:
            RoadVertexID

        let segments:
            [RoadRouteSegment]

        let cost:
            Double

        /// Direction travelled immediately before reaching this vertex
        /// (start candidate), or immediately after leaving this vertex
        /// (end candidate).
        let boundaryDirection:
            GridRoadDirection?
    }


    struct VertexPath {

        let vertexIDs:
            [RoadVertexID]

        let segments:
            [RoadRouteSegment]

        let cost:
            Double
    }


    struct SearchState:
        Hashable {

        let vertexID:
            RoadVertexID

        /// Direction used to enter this state.
        let incomingDirection:
            GridRoadDirection?

        /// Most recent horizontal direction, even if one or more DOWN
        /// movements happened after it. This lets us discourage routes
        /// that repeatedly change horizontal intent across later rows.
        let lastHorizontalDirection:
            GridRoadDirection?
    }


    struct PreviousStep {

        let previousState:
            SearchState

        let segment:
            RoadRouteSegment
    }


    struct QueueItem {

        let state:
            SearchState

        let costFromStart:
            Double

        let priority:
            Double
    }


    struct GraphLookup {

        let verticesByID:
            [RoadVertexID: RoadVertex]

        let edgesByID:
            [RoadEdgeID: RoadEdge]

        let minimumEffectiveMultiplier:
            Double


        init(
            graph: RoadGraph,
            routingOptions: RoadRoutingOptions
        ) {

            verticesByID =
                Dictionary(
                    uniqueKeysWithValues:
                        graph.vertices.map {
                            ($0.id, $0)
                        }
                )


            edgesByID =
                Dictionary(
                    uniqueKeysWithValues:
                        graph.edges.map {
                            ($0.id, $0)
                        }
                )


            let multipliers =
                graph.edges.compactMap { edge -> Double? in

                    guard
                        edge.attributes.isTraversable,
                        edge.travelDirection != .closed,
                        !routingOptions.isExcluded(edge.id)
                    else {
                        return nil
                    }


                    return max(
                        edge.attributes.routingCostMultiplier
                        * routingOptions.costMultiplier(for: edge.id),
                        0.000_001
                    )
                }


            minimumEffectiveMultiplier =
                multipliers.min()
                ??
                1
        }
    }
}


// =====================================================
// MARK: - Endpoint Candidates
// =====================================================

private extension RoadPathfinder {

    func startCandidates(
        for anchor: RoadRouteAnchor,
        graph: RoadGraph,
        lookup: GraphLookup,
        timePolicy: RouteTimePolicy?,
        routingOptions: RoadRoutingOptions
    ) -> [EndpointCandidate] {

        switch anchor.roadLocation {

        case let .vertex(vertexID):

            guard
                GridRoadTopology
                    .intersectionID(
                        from:
                            vertexID
                    )
                != nil
            else {
                return []
            }


            return [
                EndpointCandidate(
                    vertexID:
                        vertexID,
                    segments:
                        [],
                    cost:
                        0,
                    boundaryDirection:
                        nil
                )
            ]


        case let .edge(edgeID, rawFraction):

            guard
                let edge = lookup.edgesByID[edgeID],
                edgeCanRoute(
                    edge,
                    routingOptions:
                        routingOptions
                )
            else {
                return []
            }


            let fraction =
                clampedFraction(
                    rawFraction
                )


            let fullCost =
                edgeCost(
                    edge,
                    graph:
                        graph,
                    routingOptions:
                        routingOptions
                )


            var result: [EndpointCandidate] = []


            // Move from the anchor toward edge.toID.
            if allowsForward(
                edge,
                routingOptions:
                    routingOptions
            ) {

                appendEndpointCandidate(
                    edge:
                        edge,
                    vertexID:
                        edge.toID,
                    fromFraction:
                        fraction,
                    toFraction:
                        1,
                    fullEdgeCost:
                        fullCost,
                    graph:
                        graph,
                    lookup:
                        lookup,
                    timePolicy:
                        timePolicy,
                    into:
                        &result
                )
            }


            // Move from the anchor toward edge.fromID.
            if allowsReverse(
                edge,
                routingOptions:
                    routingOptions
            ) {

                appendEndpointCandidate(
                    edge:
                        edge,
                    vertexID:
                        edge.fromID,
                    fromFraction:
                        fraction,
                    toFraction:
                        0,
                    fullEdgeCost:
                        fullCost,
                    graph:
                        graph,
                    lookup:
                        lookup,
                    timePolicy:
                        timePolicy,
                    into:
                        &result
                )
            }


            return result
        }
    }


    func endCandidates(
        for anchor: RoadRouteAnchor,
        graph: RoadGraph,
        lookup: GraphLookup,
        timePolicy: RouteTimePolicy?,
        routingOptions: RoadRoutingOptions
    ) -> [EndpointCandidate] {

        switch anchor.roadLocation {

        case let .vertex(vertexID):

            guard
                GridRoadTopology
                    .intersectionID(
                        from:
                            vertexID
                    )
                != nil
            else {
                return []
            }


            return [
                EndpointCandidate(
                    vertexID:
                        vertexID,
                    segments:
                        [],
                    cost:
                        0,
                    boundaryDirection:
                        nil
                )
            ]


        case let .edge(edgeID, rawFraction):

            guard
                let edge = lookup.edgesByID[edgeID],
                edgeCanRoute(
                    edge,
                    routingOptions:
                        routingOptions
                )
            else {
                return []
            }


            let fraction =
                clampedFraction(
                    rawFraction
                )


            let fullCost =
                edgeCost(
                    edge,
                    graph:
                        graph,
                    routingOptions:
                        routingOptions
                )


            var result: [EndpointCandidate] = []


            // Arrive at the anchor from edge.fromID.
            if allowsForward(
                edge,
                routingOptions:
                    routingOptions
            ) {

                appendEndpointCandidate(
                    edge:
                        edge,
                    vertexID:
                        edge.fromID,
                    fromFraction:
                        0,
                    toFraction:
                        fraction,
                    fullEdgeCost:
                        fullCost,
                    graph:
                        graph,
                    lookup:
                        lookup,
                    timePolicy:
                        timePolicy,
                    into:
                        &result
                )
            }


            // Arrive at the anchor from edge.toID.
            if allowsReverse(
                edge,
                routingOptions:
                    routingOptions
            ) {

                appendEndpointCandidate(
                    edge:
                        edge,
                    vertexID:
                        edge.toID,
                    fromFraction:
                        1,
                    toFraction:
                        fraction,
                    fullEdgeCost:
                        fullCost,
                    graph:
                        graph,
                    lookup:
                        lookup,
                    timePolicy:
                        timePolicy,
                    into:
                        &result
                )
            }


            return result
        }
    }


    func appendEndpointCandidate(
        edge: RoadEdge,
        vertexID: RoadVertexID,
        fromFraction: Double,
        toFraction: Double,
        fullEdgeCost: Double,
        graph: RoadGraph,
        lookup: GraphLookup,
        timePolicy: RouteTimePolicy?,
        into result: inout [EndpointCandidate]
    ) {

        let traversedFraction =
            abs(
                toFraction
                - fromFraction
            )


        if traversedFraction <= 0.000_001 {

            result.append(
                EndpointCandidate(
                    vertexID:
                        vertexID,
                    segments:
                        [],
                    cost:
                        0,
                    boundaryDirection:
                        nil
                )
            )

            return
        }


        let segment =
            RoadRouteSegment(
                edgeID:
                    edge.id,
                fromFraction:
                    fromFraction,
                toFraction:
                    toFraction
            )


        guard
            let direction =
                traversalDirection(
                    for:
                        segment,
                    edge:
                        edge
                ),
            routeDirectionIsAllowed(
                direction
            ),
            segmentIsAllowed(
                segment,
                graph:
                    graph,
                timePolicy:
                    timePolicy
            )
        else {
            return
        }


        result.append(
            EndpointCandidate(
                vertexID:
                    vertexID,
                segments:
                    [segment],
                cost:
                    fullEdgeCost
                    * traversedFraction,
                boundaryDirection:
                    direction
            )
        )
    }
}


// =====================================================
// MARK: - Direct Same Edge
// =====================================================

private extension RoadPathfinder {

    func directSameEdgePath(
        from start: RoadRouteAnchor,
        to end: RoadRouteAnchor,
        graph: RoadGraph,
        lookup: GraphLookup,
        timePolicy: RouteTimePolicy?,
        routingOptions: RoadRoutingOptions
    ) -> RoadRoutePath? {

        guard
            case let .edge(startEdgeID, rawStartFraction) =
                start.roadLocation,
            case let .edge(endEdgeID, rawEndFraction) =
                end.roadLocation,
            startEdgeID == endEdgeID,
            let edge = lookup.edgesByID[startEdgeID],
            edgeCanRoute(
                edge,
                routingOptions:
                    routingOptions
            )
        else {
            return nil
        }


        let startFraction =
            clampedFraction(
                rawStartFraction
            )

        let endFraction =
            clampedFraction(
                rawEndFraction
            )

        let delta =
            endFraction
            - startFraction


        if abs(delta) <= 0.000_001 {

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


        if delta > 0 {

            guard
                allowsForward(
                    edge,
                    routingOptions:
                        routingOptions
                )
            else {
                return nil
            }

        } else {

            guard
                allowsReverse(
                    edge,
                    routingOptions:
                        routingOptions
                )
            else {
                return nil
            }
        }


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
            let direction =
                traversalDirection(
                    for:
                        segment,
                    edge:
                        edge
                ),
            routeDirectionIsAllowed(
                direction
            ),
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
                [segment],
            totalCost:
                edgeCost(
                    edge,
                    graph:
                        graph,
                    routingOptions:
                        routingOptions
                )
                * abs(delta)
        )
    }
}


// =====================================================
// MARK: - Direction-Aware A*
// =====================================================

private extension RoadPathfinder {

    func shortestVertexPath(
        from startVertexID: RoadVertexID,
        to destinationVertexID: RoadVertexID,
        initialDirection: GridRoadDirection?,
        terminalDirection: GridRoadDirection?,
        graph: RoadGraph,
        lookup: GraphLookup,
        timePolicy: RouteTimePolicy?,
        routingOptions: RoadRoutingOptions
    ) -> VertexPath? {

        guard
            let startIntersection =
                GridRoadTopology
                    .intersectionID(
                        from:
                            startVertexID
                    ),
            let destinationIntersection =
                GridRoadTopology
                    .intersectionID(
                        from:
                            destinationVertexID
                    ),
            destinationIntersection.row
            >=
            startIntersection.row
        else {
            return nil
        }


        let startState =
            SearchState(
                vertexID:
                    startVertexID,
                incomingDirection:
                    initialDirection,
                lastHorizontalDirection:
                    horizontalDirection(
                        initialDirection
                    )
            )


        var bestCosts: [SearchState: Double] = [
            startState: 0
        ]

        var previous: [SearchState: PreviousStep] = [:]

        var queue =
            MinHeap()


        queue.push(
            QueueItem(
                state:
                    startState,
                costFromStart:
                    0,
                priority:
                    heuristicCost(
                        from:
                            startIntersection,
                        to:
                            destinationIntersection,
                        minimumEffectiveMultiplier:
                            lookup.minimumEffectiveMultiplier
                    )
            )
        )


        var bestGoalState: SearchState?
        var bestGoalCost =
            Double.greatestFiniteMagnitude


        while let current = queue.pop() {

            let knownCost =
                bestCosts[current.state]
                ??
                .greatestFiniteMagnitude


            // Ignore stale heap entries.
            guard
                current.costFromStart
                <=
                knownCost + 0.000_001
            else {
                continue
            }


            // A* lower bound can no longer beat the best complete goal.
            if current.priority >= bestGoalCost {
                break
            }


            guard
                let currentIntersection =
                    GridRoadTopology
                        .intersectionID(
                            from:
                                current.state.vertexID
                        )
            else {
                continue
            }


            if current.state.vertexID == destinationVertexID {

                guard
                    let terminalCost =
                        terminalTransitionCost(
                            from:
                                current.state,
                            terminalDirection:
                                terminalDirection,
                            routingOptions:
                                routingOptions
                        )
                else {
                    continue
                }


                let completeCost =
                    current.costFromStart
                    + terminalCost


                if completeCost < bestGoalCost {

                    bestGoalCost =
                        completeCost

                    bestGoalState =
                        current.state
                }


                // Do not leave and later return to the destination. That
                // would violate the no-loop rule and can never improve a
                // positive-cost route.
                continue
            }


            for neighbor in
                GridRoadTopology
                    .routeNeighbors(
                        of:
                            currentIntersection
                    )
            {

                // Once we move below the destination's time row, reaching
                // it would require an illegal upward move.
                guard
                    neighbor.intersection.row
                    <=
                    destinationIntersection.row
                else {
                    continue
                }


                let nextVertexID =
                    GridRoadTopology
                        .vertexID(
                            for:
                                neighbor.intersection
                        )


                guard
                    lookup.verticesByID[nextVertexID] != nil,
                    let edge = lookup.edgesByID[neighbor.edgeID],
                    edgeCanRoute(
                        edge,
                        routingOptions:
                            routingOptions
                    ),
                    let segment =
                        segment(
                            along:
                                edge,
                            from:
                                current.state.vertexID,
                            to:
                                nextVertexID,
                            routingOptions:
                                routingOptions
                        ),
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


                // Explicitly prevent revisiting an intersection. With no
                // UP movement, this mostly protects against horizontal
                // backtracking/loops on the same time row.
                guard
                    !pathAlreadyContainsVertex(
                        nextVertexID,
                        currentState:
                            current.state,
                        previous:
                            previous
                    )
                else {
                    continue
                }


                guard
                    let transitionCost =
                        transitionCost(
                            incomingDirection:
                                current.state.incomingDirection,
                            lastHorizontalDirection:
                                current.state.lastHorizontalDirection,
                            nextDirection:
                                neighbor.direction,
                            routingOptions:
                                routingOptions
                        )
                else {
                    continue
                }


                let nextLastHorizontal =
                    horizontalDirection(
                        neighbor.direction
                    )
                    ??
                    current.state.lastHorizontalDirection


                let nextState =
                    SearchState(
                        vertexID:
                            nextVertexID,
                        incomingDirection:
                            neighbor.direction,
                        lastHorizontalDirection:
                            nextLastHorizontal
                    )


                let newCost =
                    current.costFromStart
                    + edgeCost(
                        edge,
                        graph:
                            graph,
                        routingOptions:
                            routingOptions
                    )
                    + transitionCost


                let oldCost =
                    bestCosts[nextState]
                    ??
                    .greatestFiniteMagnitude


                guard newCost + 0.000_001 < oldCost else {
                    continue
                }


                bestCosts[nextState] =
                    newCost


                previous[nextState] =
                    PreviousStep(
                        previousState:
                            current.state,
                        segment:
                            segment
                    )


                let heuristic =
                    heuristicCost(
                        from:
                            neighbor.intersection,
                        to:
                            destinationIntersection,
                        minimumEffectiveMultiplier:
                            lookup.minimumEffectiveMultiplier
                    )


                queue.push(
                    QueueItem(
                        state:
                            nextState,
                        costFromStart:
                            newCost,
                        priority:
                            newCost
                            + heuristic
                    )
                )
            }
        }


        guard let goalState = bestGoalState else {
            return nil
        }


        return reconstructVertexPath(
            startState:
                startState,
            goalState:
                goalState,
            totalCost:
                bestGoalCost,
            previous:
                previous
        )
    }


    func zeroLengthVertexPath(
        at vertexID: RoadVertexID,
        initialDirection: GridRoadDirection?,
        terminalDirection: GridRoadDirection?,
        routingOptions: RoadRoutingOptions
    ) -> VertexPath? {

        let state =
            SearchState(
                vertexID:
                    vertexID,
                incomingDirection:
                    initialDirection,
                lastHorizontalDirection:
                    horizontalDirection(
                        initialDirection
                    )
            )


        guard
            let transition =
                terminalTransitionCost(
                    from:
                        state,
                    terminalDirection:
                        terminalDirection,
                    routingOptions:
                        routingOptions
                )
        else {
            return nil
        }


        return VertexPath(
            vertexIDs:
                [vertexID],
            segments:
                [],
            cost:
                transition
        )
    }
}


// =====================================================
// MARK: - A* Reconstruction / Heuristic
// =====================================================

private extension RoadPathfinder {

    func reconstructVertexPath(
        startState: SearchState,
        goalState: SearchState,
        totalCost: Double,
        previous: [SearchState: PreviousStep]
    ) -> VertexPath? {

        var reversedStates: [SearchState] = [
            goalState
        ]

        var reversedSegments: [RoadRouteSegment] = []

        var current =
            goalState


        while current != startState {

            guard let step = previous[current] else {
                return nil
            }


            reversedSegments.append(
                step.segment
            )

            current =
                step.previousState

            reversedStates.append(
                current
            )
        }


        return VertexPath(
            vertexIDs:
                reversedStates
                    .reversed()
                    .map(\.vertexID),
            segments:
                Array(
                    reversedSegments.reversed()
                ),
            cost:
                totalCost
        )
    }


    func heuristicCost(
        from current: GridIntersectionID,
        to destination: GridIntersectionID,
        minimumEffectiveMultiplier: Double
    ) -> Double {

        guard destination.row >= current.row else {
            return .greatestFiniteMagnitude
        }


        let horizontalSteps =
            abs(
                destination.column
                - current.column
            )

        let downwardSteps =
            destination.row
            - current.row

        let remainingSteps =
            horizontalSteps
            + downwardSteps


        return Double(remainingSteps)
        * Double(
            GridMapConfiguration
                .cellPitchWorld
        )
        * minimumEffectiveMultiplier
    }


    func pathAlreadyContainsVertex(
        _ vertexID: RoadVertexID,
        currentState: SearchState,
        previous: [SearchState: PreviousStep]
    ) -> Bool {

        var cursor =
            currentState


        while true {

            if cursor.vertexID == vertexID {
                return true
            }


            guard let step = previous[cursor] else {
                return false
            }


            cursor =
                step.previousState
        }
    }
}


// =====================================================
// MARK: - Direction / Turn Policy
// =====================================================

private extension RoadPathfinder {

    func routeDirectionIsAllowed(
        _ direction: GridRoadDirection
    ) -> Bool {

        switch direction {

        case .left,
             .right,
             .down:
            return true

        case .up:
            return false
        }
    }


    func horizontalDirection(
        _ direction: GridRoadDirection?
    ) -> GridRoadDirection? {

        switch direction {

        case .left?:
            return .left

        case .right?:
            return .right

        case .up?,
             .down?,
             nil:
            return nil
        }
    }


    func areOppositeHorizontalDirections(
        _ lhs: GridRoadDirection,
        _ rhs: GridRoadDirection
    ) -> Bool {

        (lhs == .left && rhs == .right)
        ||
        (lhs == .right && rhs == .left)
    }


    /// Returns nil when a transition is forbidden.
    func transitionCost(
        incomingDirection: GridRoadDirection?,
        lastHorizontalDirection: GridRoadDirection?,
        nextDirection: GridRoadDirection,
        routingOptions: RoadRoutingOptions
    ) -> Double? {

        guard routeDirectionIsAllowed(nextDirection) else {
            return nil
        }


        if
            routingOptions
                .rejectsImmediateHorizontalReversal,
            let incomingDirection,
            areOppositeHorizontalDirections(
                incomingDirection,
                nextDirection
            )
        {
            return nil
        }


        var cost =
            0.0


        if
            let incomingDirection,
            incomingDirection != nextDirection
        {
            cost +=
                routingOptions
                    .turnPenalty
        }


        if
            let nextHorizontal =
                horizontalDirection(
                    nextDirection
                ),
            let lastHorizontalDirection,
            nextHorizontal
            !=
            lastHorizontalDirection
        {
            cost +=
                routingOptions
                    .horizontalDirectionChangePenalty
        }


        return cost
    }


    func terminalTransitionCost(
        from state: SearchState,
        terminalDirection: GridRoadDirection?,
        routingOptions: RoadRoutingOptions
    ) -> Double? {

        guard let terminalDirection else {
            return 0
        }


        return transitionCost(
            incomingDirection:
                state.incomingDirection,
            lastHorizontalDirection:
                state.lastHorizontalDirection,
            nextDirection:
                terminalDirection,
            routingOptions:
                routingOptions
        )
    }


    func traversalDirection(
        for segment: RoadRouteSegment,
        edge: RoadEdge
    ) -> GridRoadDirection? {

        let delta =
            segment.toFraction
            - segment.fromFraction


        guard abs(delta) > 0.000_001 else {
            return nil
        }


        guard
            let fromIntersection =
                GridRoadTopology
                    .intersectionID(
                        from:
                            edge.fromID
                    ),
            let toIntersection =
                GridRoadTopology
                    .intersectionID(
                        from:
                            edge.toID
                    ),
            let canonicalDirection =
                GridRoadTopology
                    .direction(
                        from:
                            fromIntersection,
                        to:
                            toIntersection
                    )
        else {
            return nil
        }


        if delta > 0 {
            return canonicalDirection
        }


        return oppositeDirection(
            canonicalDirection
        )
    }


    func oppositeDirection(
        _ direction: GridRoadDirection
    ) -> GridRoadDirection {

        switch direction {

        case .left:
            return .right

        case .right:
            return .left

        case .up:
            return .down

        case .down:
            return .up
        }
    }
}


// =====================================================
// MARK: - Grid Segment Creation
// =====================================================

private extension RoadPathfinder {

    func segment(
        along edge: RoadEdge,
        from sourceVertexID: RoadVertexID,
        to destinationVertexID: RoadVertexID,
        routingOptions: RoadRoutingOptions
    ) -> RoadRouteSegment? {

        if
            edge.fromID == sourceVertexID,
            edge.toID == destinationVertexID,
            allowsForward(
                edge,
                routingOptions:
                    routingOptions
            )
        {

            return RoadRouteSegment(
                edgeID:
                    edge.id,
                fromFraction:
                    0,
                toFraction:
                    1
            )
        }


        if
            edge.toID == sourceVertexID,
            edge.fromID == destinationVertexID,
            allowsReverse(
                edge,
                routingOptions:
                    routingOptions
            )
        {

            return RoadRouteSegment(
                edgeID:
                    edge.id,
                fromFraction:
                    1,
                toFraction:
                    0
            )
        }


        return nil
    }
}


// =====================================================
// MARK: - Edge Policy / Cost
// =====================================================

private extension RoadPathfinder {

    func edgeCanRoute(
        _ edge: RoadEdge,
        routingOptions: RoadRoutingOptions
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
            edge.attributes.isTraversable
            &&
            edge.travelDirection != .closed
    }


    func allowsForward(
        _ edge: RoadEdge,
        routingOptions: RoadRoutingOptions
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
        _ edge: RoadEdge,
        routingOptions: RoadRoutingOptions
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


    func edgeCost(
        _ edge: RoadEdge,
        graph: RoadGraph,
        routingOptions: RoadRoutingOptions
    ) -> Double {

        RoadEdgeGeometry
            .length(
                of:
                    edge,
                graph:
                    graph
            )
        * edge.attributes.routingCostMultiplier
        * routingOptions.costMultiplier(for: edge.id)
    }


    func segmentIsAllowed(
        _ segment: RoadRouteSegment,
        graph: RoadGraph,
        timePolicy: RouteTimePolicy?
    ) -> Bool {

        guard let timePolicy else {
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


// =====================================================
// MARK: - Final Rule Validation
// =====================================================

private extension RoadPathfinder {

    func pathObeysGridRouteRules(
        _ path: RoadRoutePath,
        graph: RoadGraph,
        lookup: GraphLookup,
        routingOptions: RoadRoutingOptions
    ) -> Bool {

        var seenEdges =
            Set<RoadEdgeID>()

        var seenVertices =
            Set<RoadVertexID>()

        var previousDirection:
            GridRoadDirection?


        for vertexID in path.vertexIDs {

            guard
                seenVertices
                    .insert(
                        vertexID
                    )
                    .inserted
            else {
                return false
            }
        }


        for segment in path.segments {

            guard
                seenEdges
                    .insert(
                        segment.edgeID
                    )
                    .inserted,
                let edge = lookup.edgesByID[segment.edgeID],
                let direction =
                    traversalDirection(
                        for:
                            segment,
                        edge:
                            edge
                    ),
                routeDirectionIsAllowed(
                    direction
                )
            else {
                return false
            }


            if
                routingOptions
                    .rejectsImmediateHorizontalReversal,
                let previousDirection,
                areOppositeHorizontalDirections(
                    previousDirection,
                    direction
                )
            {
                return false
            }


            previousDirection =
                direction
        }


        return true
    }


    func deduplicatedAdjacent(
        _ values: [RoadVertexID]
    ) -> [RoadVertexID] {

        var result: [RoadVertexID] = []
        result.reserveCapacity(values.count)


        for value in values {

            if result.last != value {
                result.append(value)
            }
        }


        return result
    }


    func clampedFraction(
        _ value: Double
    ) -> Double {

        min(
            max(
                value,
                0
            ),
            1
        )
    }
}


// =====================================================
// MARK: - Min Heap
// =====================================================

private extension RoadPathfinder {

    struct MinHeap {

        private var storage: [QueueItem] = []


        mutating func push(
            _ item: QueueItem
        ) {

            storage.append(item)
            siftUp(from: storage.count - 1)
        }


        mutating func pop() -> QueueItem? {

            guard !storage.isEmpty else {
                return nil
            }


            if storage.count == 1 {
                return storage.removeLast()
            }


            let result =
                storage[0]

            storage[0] =
                storage.removeLast()

            siftDown(from: 0)

            return result
        }


        mutating func siftUp(
            from index: Int
        ) {

            var child =
                index


            while child > 0 {

                let parent =
                    (child - 1) / 2


                guard
                    isHigherPriority(
                        storage[child],
                        than:
                            storage[parent]
                    )
                else {
                    return
                }


                storage.swapAt(
                    child,
                    parent
                )

                child =
                    parent
            }
        }


        mutating func siftDown(
            from index: Int
        ) {

            var parent =
                index


            while true {

                let left =
                    parent * 2 + 1

                let right =
                    left + 1

                var candidate =
                    parent


                if
                    left < storage.count,
                    isHigherPriority(
                        storage[left],
                        than:
                            storage[candidate]
                    )
                {
                    candidate = left
                }


                if
                    right < storage.count,
                    isHigherPriority(
                        storage[right],
                        than:
                            storage[candidate]
                    )
                {
                    candidate = right
                }


                guard candidate != parent else {
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


        func isHigherPriority(
            _ lhs: QueueItem,
            than rhs: QueueItem
        ) -> Bool {

            if abs(lhs.priority - rhs.priority) > 0.000_001 {
                return lhs.priority < rhs.priority
            }


            return lhs.costFromStart < rhs.costFromStart
        }
    }
}
