//
//  RoadGraphValidator.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/18/26.
//

import Foundation


// MARK: - Severity

enum RoadGraphValidationSeverity:
    String,
    Sendable {

    case warning

    case error
}


// MARK: - Code

enum RoadGraphValidationCode:
    String,
    Sendable {

    case emptyGraph

    case invalidVersion

    case emptyIdentifier

    case duplicateVertexID

    case duplicateEdgeID

    case missingFromVertex

    case missingToVertex

    case selfLoop

    case invalidRoutingCost

    case invalidCoordinate

    case invalidCulDeSacDegree

    case invalidCircle

    case disconnectedGraph
}


// MARK: - Issue

struct RoadGraphValidationIssue:
    Equatable,
    Sendable {

    let severity:
        RoadGraphValidationSeverity

    let code:
        RoadGraphValidationCode

    let message:
        String
}


// MARK: - Result

struct RoadGraphValidationResult:
    Sendable {

    let issues:
        [RoadGraphValidationIssue]


    var errors:
        [RoadGraphValidationIssue] {

        issues.filter {
            $0.severity == .error
        }
    }


    var warnings:
        [RoadGraphValidationIssue] {

        issues.filter {
            $0.severity == .warning
        }
    }


    var isValid:
        Bool {

        errors.isEmpty
    }
}


// MARK: - Validator

enum RoadGraphValidator {

    static func validate(
        _ graph:
            RoadGraph
    ) -> RoadGraphValidationResult {

        var issues:
            [RoadGraphValidationIssue] = []


        // MARK: Basic Graph Rules

        if graph.vertices.isEmpty {

            issues.append(
                error(
                    .emptyGraph,
                    "RoadGraph contains no vertices."
                )
            )
        }


        if graph.version < 0 {

            issues.append(
                error(
                    .invalidVersion,
                    "RoadGraph version cannot be negative."
                )
            )
        }


        if graph.id.rawValue
            .trimmingCharacters(
                in:
                    .whitespacesAndNewlines
            )
            .isEmpty {

            issues.append(
                error(
                    .emptyIdentifier,
                    "RoadGraph has an empty ID."
                )
            )
        }


        // MARK: Build Safe Vertex Lookup

        var verticesByID:
            [RoadVertexID: RoadVertex] = [:]


        for vertex in
            graph.vertices {

            if vertex.id.rawValue
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )
                .isEmpty {

                issues.append(
                    error(
                        .emptyIdentifier,
                        "A RoadVertex has an empty ID."
                    )
                )
            }


            if verticesByID[
                vertex.id
            ] != nil {

                issues.append(
                    error(
                        .duplicateVertexID,
                        """
                        Duplicate RoadVertex ID:
                        \(vertex.id.rawValue)
                        """
                    )
                )

            } else {

                verticesByID[
                    vertex.id
                ] =
                    vertex
            }


            if !isValid(
                coordinate:
                    vertex.coordinate
            ) {

                issues.append(
                    error(
                        .invalidCoordinate,
                        """
                        RoadVertex \(vertex.id.rawValue)
                        contains an invalid coordinate.
                        """
                    )
                )
            }
        }


        // MARK: Edge Validation

        var edgeIDs =
            Set<RoadEdgeID>()


        for edge in
            graph.edges {

            if edge.id.rawValue
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )
                .isEmpty {

                issues.append(
                    error(
                        .emptyIdentifier,
                        "A RoadEdge has an empty ID."
                    )
                )
            }


            if !edgeIDs.insert(
                edge.id
            )
            .inserted {

                issues.append(
                    error(
                        .duplicateEdgeID,
                        """
                        Duplicate RoadEdge ID:
                        \(edge.id.rawValue)
                        """
                    )
                )
            }


            if verticesByID[
                edge.fromID
            ] == nil {

                issues.append(
                    error(
                        .missingFromVertex,
                        """
                        RoadEdge \(edge.id.rawValue)
                        references missing FROM vertex
                        \(edge.fromID.rawValue).
                        """
                    )
                )
            }


            if verticesByID[
                edge.toID
            ] == nil {

                issues.append(
                    error(
                        .missingToVertex,
                        """
                        RoadEdge \(edge.id.rawValue)
                        references missing TO vertex
                        \(edge.toID.rawValue).
                        """
                    )
                )
            }


            if edge.fromID ==
                edge.toID {

                /*
                 Roundabouts should be real cycles
                 of multiple explicit vertices,
                 not one self-loop edge.
                 */

                issues.append(
                    error(
                        .selfLoop,
                        """
                        RoadEdge \(edge.id.rawValue)
                        connects a vertex to itself.
                        """
                    )
                )
            }


            let routingCost =
                edge
                    .attributes
                    .routingCostMultiplier


            if
                !routingCost.isFinite
                ||
                routingCost <= 0
            {

                issues.append(
                    error(
                        .invalidRoutingCost,
                        """
                        RoadEdge \(edge.id.rawValue)
                        has invalid routingCostMultiplier.
                        """
                    )
                )
            }


            if !isValid(
                shape:
                    edge.shape
            ) {

                issues.append(
                    error(
                        .invalidCoordinate,
                        """
                        RoadEdge \(edge.id.rawValue)
                        contains invalid geometry.
                        """
                    )
                )
            }
        }


        // MARK: Cul-de-sac Rules

        validateCulDeSacs(
            graph:
                graph,
            issues:
                &issues
        )


        // MARK: Circle Rules

        validateCircles(
            graph:
                graph,
            verticesByID:
                verticesByID,
            issues:
                &issues
        )


        // MARK: Connectivity

        validateConnectivity(
            graph:
                graph,
            issues:
                &issues
        )


        return RoadGraphValidationResult(
            issues:
                issues
        )
    }
}

// MARK: - Cul-de-sac Validation

private extension RoadGraphValidator {

    static func validateCulDeSacs(
        graph:
            RoadGraph,
        issues:
            inout [RoadGraphValidationIssue]
    ) {

        let culDeSacVertices =
            graph.vertices.filter {

                $0.kind ==
                    .culDeSacEnd
            }


        for vertex in
            culDeSacVertices {

            let degree =
                graph.degree(
                    of:
                        vertex.id,
                    traversableOnly:
                        true
                )


            if degree != 1 {

                issues.append(
                    error(
                        .invalidCulDeSacDegree,
                        """
                        Cul-de-sac endpoint
                        \(vertex.id.rawValue)
                        must have exactly one traversable
                        incident road edge, but has
                        \(degree).
                        """
                    )
                )
            }
        }
    }
}

// MARK: - Circle / Roundabout Validation

private extension RoadGraphValidator {

    static func validateCircles(
        graph:
            RoadGraph,
        verticesByID:
            [RoadVertexID: RoadVertex],
        issues:
            inout [RoadGraphValidationIssue]
    ) {

        let circleEdges =
            graph.edges.filter {

                $0.roadClass ==
                    .circle
                &&
                $0.attributes
                    .isTraversable
                &&
                $0.travelDirection
                    != .closed
            }


        guard
            !circleEdges.isEmpty
        else {

            return
        }


        /*
         Build an undirected circle-only
         adjacency map.

         Normal connector roads do not count
         toward circle degree.
         */

        var adjacency:
            [RoadVertexID:
                [RoadVertexID]]
            = [:]


        for edge in
            circleEdges {

            guard
                verticesByID[
                    edge.fromID
                ] != nil,
                verticesByID[
                    edge.toID
                ] != nil
            else {

                continue
            }


            adjacency[
                edge.fromID,
                default: []
            ]
            .append(
                edge.toID
            )


            adjacency[
                edge.toID,
                default: []
            ]
            .append(
                edge.fromID
            )
        }


        var unvisited =
            Set(
                adjacency.keys
            )


        while let start =
            unvisited.first {

            var stack =
                [start]


            var component =
                Set<RoadVertexID>()


            while let current =
                stack.popLast() {

                guard
                    component.insert(
                        current
                    )
                    .inserted
                else {

                    continue
                }


                unvisited.remove(
                    current
                )


                for neighbor in
                    adjacency[
                        current,
                        default: []
                    ] {

                    if !component
                        .contains(
                            neighbor
                        ) {

                        stack.append(
                            neighbor
                        )
                    }
                }
            }


            validateCircleComponent(
                component,
                adjacency:
                    adjacency,
                verticesByID:
                    verticesByID,
                issues:
                    &issues
            )
        }
    }


    static func validateCircleComponent(
        _ component:
            Set<RoadVertexID>,
        adjacency:
            [RoadVertexID:
                [RoadVertexID]],
        verticesByID:
            [RoadVertexID: RoadVertex],
        issues:
            inout [RoadGraphValidationIssue]
    ) {

        /*
         A meaningful cycle needs at least
         three vertices.
         */

        if component.count < 3 {

            issues.append(
                error(
                    .invalidCircle,
                    """
                    A circle road component must
                    contain at least three vertices.
                    """
                )
            )
        }


        /*
         Every vertex in the circle subgraph
         should have exactly two circle neighbors.

         Connector roads entering/exiting the
         roundabout don't affect this count.
         */

        for vertexID in
            component {

            let circleDegree =
                adjacency[
                    vertexID,
                    default: []
                ]
                .count


            if circleDegree != 2 {

                issues.append(
                    error(
                        .invalidCircle,
                        """
                        Circle vertex
                        \(vertexID.rawValue)
                        has circle-degree
                        \(circleDegree);
                        expected 2.
                        """
                    )
                )
            }
        }


        let kinds =
            component.compactMap {

                verticesByID[
                    $0
                ]?
                .kind
            }


        if !kinds.contains(
            .circleEntry
        ) {

            issues.append(
                error(
                    .invalidCircle,
                    """
                    Circle road component has
                    no circleEntry vertex.
                    """
                )
            )
        }


        if !kinds.contains(
            .circleExit
        ) {

            issues.append(
                error(
                    .invalidCircle,
                    """
                    Circle road component has
                    no circleExit vertex.
                    """
                )
            )
        }
    }
}

// MARK: - Connectivity Validation

private extension RoadGraphValidator {

    static func validateConnectivity(
        graph:
            RoadGraph,
        issues:
            inout [RoadGraphValidationIssue]
    ) {

        guard
            let first =
                graph.vertices.first
        else {

            return
        }


        var visited =
            Set<RoadVertexID>()


        var stack =
            [first.id]


        while let current =
            stack.popLast() {

            guard
                visited.insert(
                    current
                )
                .inserted
            else {

                continue
            }


            let incident =
                graph.incidentEdges(
                    to:
                        current,
                    traversableOnly:
                        true
                )


            for edge in
                incident {

                let other =
                    edge.fromID == current
                    ? edge.toID
                    : edge.fromID


                if !visited
                    .contains(
                        other
                    ) {

                    stack.append(
                        other
                    )
                }
            }
        }


        if visited.count !=
            graph.vertices.count {

            issues.append(
                warning(
                    .disconnectedGraph,
                    """
                    RoadGraph contains disconnected
                    topology. Reachable vertices:
                    \(visited.count) /
                    \(graph.vertices.count).
                    """
                )
            )
        }
    }
}

// MARK: - Validation Helpers

private extension RoadGraphValidator {

    static func isValid(
        coordinate:
            MapCoordinate
    ) -> Bool {

        coordinate
            .time
            .secondsFromMidnight
            .isFinite

        &&

        coordinate
            .progress
            .percent
            .isFinite
    }


    static func isValid(
        worldPoint:
            WorldPoint
    ) -> Bool {

        worldPoint.x.isFinite
        &&
        worldPoint.y.isFinite
    }


    static func isValid(
        shape:
            RoadEdgeShape
    ) -> Bool {

        switch shape {

        case .straight:

            return true


        case let .polyline(
            intermediatePoints
        ):

            return intermediatePoints
                .allSatisfy {

                    isValid(
                        worldPoint:
                            $0
                    )
                }


        case let .cubicBezier(
            control1,
            control2
        ):

            return
                isValid(
                    worldPoint:
                        control1
                )
                &&
                isValid(
                    worldPoint:
                        control2
                )
        }
    }


    static func error(
        _ code:
            RoadGraphValidationCode,
        _ message:
            String
    ) -> RoadGraphValidationIssue {

        RoadGraphValidationIssue(
            severity:
                .error,
            code:
                code,
            message:
                message
        )
    }


    static func warning(
        _ code:
            RoadGraphValidationCode,
        _ message:
            String
    ) -> RoadGraphValidationIssue {

        RoadGraphValidationIssue(
            severity:
                .warning,
            code:
                code,
            message:
                message
        )
    }
}
