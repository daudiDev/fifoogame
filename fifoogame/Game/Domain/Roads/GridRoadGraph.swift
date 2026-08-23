//
//  GridRoadGraph.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/22/26.
//


import Foundation


enum GridRoadGraph {

    static let graphID =
        RoadGraphID(
            "fifoo.cartesian.grid.v1"
        )


    /// Builds the finite compatibility graph currently consumed by the
    /// existing route/node APIs.
    ///
    /// The topology itself is not finite horizontally; callers that need a
    /// neighbor outside this materialized range can use GridRoadTopology's
    /// dynamic neighbor functions directly. Step 5 will build routing around
    /// that directional topology.
    static func make(
        columnRange: ClosedRange<Int> =
            GridRoadTopology
                .defaultMaterializedColumnRange
    ) -> RoadGraph {

        var vertices: [RoadVertex] = []
        var edges: [RoadEdge] = []


        appendVertices(
            columnRange:
                columnRange,
            to:
                &vertices
        )


        appendHorizontalEdges(
            columnRange:
                columnRange,
            to:
                &edges
        )


        appendVerticalEdges(
            columnRange:
                columnRange,
            to:
                &edges
        )


        return RoadGraph(
            id:
                graphID,
            version:
                4,
            vertices:
                vertices,
            edges:
                edges
        )
    }
}


// =====================================================
// MARK: - Vertices
// =====================================================

private extension GridRoadGraph {

    static func appendVertices(
        columnRange: ClosedRange<Int>,
        to vertices: inout [RoadVertex]
    ) {

        let rowRange =
            GridRoadTopology
                .intersectionRowRange

        let rowCount =
            rowRange.count

        let columnCount =
            columnRange.count

        vertices.reserveCapacity(
            rowCount
            * columnCount
        )


        for row in rowRange {

            for column in columnRange {

                let intersection =
                    GridIntersectionID(
                        column:
                            column,
                        row:
                            row
                    )


                vertices.append(
                    RoadVertex(
                        id:
                            GridRoadTopology
                                .vertexID(
                                    for:
                                        intersection
                                ),
                        coordinate:
                            GridRoadTopology
                                .coordinate(
                                    for:
                                        intersection
                                ),
                        kind:
                            .intersection
                    )
                )
            }
        }
    }
}


// =====================================================
// MARK: - Horizontal Roads
// =====================================================

private extension GridRoadGraph {

    static func appendHorizontalEdges(
        columnRange: ClosedRange<Int>,
        to edges: inout [RoadEdge]
    ) {

        guard
            columnRange.lowerBound
            < columnRange.upperBound
        else {

            return
        }


        for row in
            GridRoadTopology
                .intersectionRowRange {

            for leftColumn in
                columnRange.lowerBound
                ..<
                columnRange.upperBound {

                let from =
                    GridIntersectionID(
                        column:
                            leftColumn,
                        row:
                            row
                    )

                let to =
                    GridIntersectionID(
                        column:
                            leftColumn + 1,
                        row:
                            row
                    )


                edges.append(
                    RoadEdge(
                        id:
                            GridRoadTopology
                                .horizontalEdgeID(
                                    row:
                                        row,
                                    leftColumn:
                                        leftColumn
                                ),
                        fromID:
                            GridRoadTopology
                                .vertexID(
                                    for:
                                        from
                                ),
                        toID:
                            GridRoadTopology
                                .vertexID(
                                    for:
                                        to
                                ),
                        roadClass:
                            .local,
                        travelDirection:
                            .bidirectional,
                        shape:
                            .straight,
                        attributes:
                            RoadAttributes(
                                displayName:
                                    nil,
                                isTraversable:
                                    true,
                                isGradeSeparated:
                                    false,
                                routingCostMultiplier:
                                    1.0,
                                tags: [
                                    "grid",
                                    "horizontal"
                                ]
                            )
                    )
                )
            }
        }
    }
}


// =====================================================
// MARK: - Vertical Roads
// =====================================================

private extension GridRoadGraph {

    static func appendVerticalEdges(
        columnRange: ClosedRange<Int>,
        to edges: inout [RoadEdge]
    ) {

        let maximumRow =
            GridRoadTopology
                .maximumIntersectionRow

        guard maximumRow > 0 else {
            return
        }


        for column in columnRange {

            for topRow in
                0..<maximumRow {

                let from =
                    GridIntersectionID(
                        column:
                            column,
                        row:
                            topRow
                    )

                let to =
                    GridIntersectionID(
                        column:
                            column,
                        row:
                            topRow + 1
                    )


                edges.append(
                    RoadEdge(
                        id:
                            GridRoadTopology
                                .verticalEdgeID(
                                    column:
                                        column,
                                    topRow:
                                        topRow
                                ),
                        fromID:
                            GridRoadTopology
                                .vertexID(
                                    for:
                                        from
                                ),
                        toID:
                            GridRoadTopology
                                .vertexID(
                                    for:
                                        to
                                ),
                        roadClass:
                            .local,
                        travelDirection:
                            .bidirectional,
                        shape:
                            .straight,
                        attributes:
                            RoadAttributes(
                                displayName:
                                    nil,
                                isTraversable:
                                    true,
                                isGradeSeparated:
                                    false,
                                routingCostMultiplier:
                                    1.0,
                                tags: [
                                    "grid",
                                    "vertical"
                                ]
                            )
                    )
                )
            }
        }
    }
}


// =====================================================
// MARK: - Debug Validation
// =====================================================

extension GridRoadGraph {

    static func debugAssertGraph(
        _ graph: RoadGraph,
        file: StaticString = #fileID,
        line: UInt = #line
    ) {

        assert(
            graph.id == graphID,
            "Expected the deterministic Cartesian GridRoadGraph.",
            file: file,
            line: line
        )

        assert(
            graph.vertices.allSatisfy {
                $0.kind == .intersection
            },
            "The redesigned road graph must contain only ordinary grid intersections.",
            file: file,
            line: line
        )

        assert(
            graph.edges.allSatisfy { edge in

                edge.roadClass == .local
                && edge.travelDirection == .bidirectional
                && edge.shape == .straight
            },
            "The redesigned road graph must contain only straight, uniform, bidirectional roads.",
            file: file,
            line: line
        )

        let forbiddenTags =
            Set([
                "roundabout",
                "circle",
                "cul-de-sac",
                "highway",
                "ramp"
            ])

        assert(
            graph.edges.allSatisfy { edge in

                forbiddenTags
                    .isDisjoint(
                        with:
                            Set(edge.attributes.tags)
                    )
            },
            "Legacy special-road topology leaked into GridRoadGraph.",
            file: file,
            line: line
        )
    }
}
