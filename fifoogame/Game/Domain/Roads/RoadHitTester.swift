//
//  RoadHitTester.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/24/26.
//

//  Cartesian road hit testing.
//
//  A successful hit now resolves the user's touch onto the semantic road
//  geometry. This gives callers the exact time/progress coordinate of the
//  road/intersection instead of only identifying the road element.
//

import Foundation
import CoreGraphics


struct RoadHitTester {

    enum Hit:
        Equatable,
        Sendable {

        case vertex(
            id: RoadVertexID,
            worldPoint: WorldPoint,
            mapCoordinate: MapCoordinate
        )

        case edge(
            id: RoadEdgeID,
            worldPoint: WorldPoint,
            mapCoordinate: MapCoordinate
        )
    }


    func hitTest(
        at point: CGPoint,
        graph: RoadGraph,
        tolerance: CGFloat
    ) -> Hit? {

        if graph.id == GridRoadGraph.graphID {

            return gridHitTest(
                at:
                    point,
                graph:
                    graph,
                tolerance:
                    tolerance
            )
        }


        // Compatibility fallback for injected/test graphs while the rest of
        // the app uses the deterministic Cartesian road grid.
        return genericHitTest(
            at:
                point,
            graph:
                graph,
            tolerance:
                tolerance
        )
    }
}


// =====================================================
// MARK: - Cartesian Grid Hit Testing
// =====================================================

private extension RoadHitTester {

    func gridHitTest(
        at point: CGPoint,
        graph: RoadGraph,
        tolerance: CGFloat
    ) -> Hit? {

        let pitch =
            GridMapConfiguration
                .cellPitchWorld

        guard pitch > 0 else {
            return nil
        }


        let extraTolerance =
            max(
                0,
                tolerance
            )

        let roadThreshold =
            GridMapConfiguration
                .roadHalfWidthWorld
            + extraTolerance


        // Horizontal streets at 00:00 and 24:00 are valid, so include the
        // road/touch threshold around the semantic day bounds.
        guard
            point.y
                <= GridMapGeometry.dayTopY
                    + roadThreshold,
            point.y
                >= GridMapGeometry.dayBottomY
                    - roadThreshold
        else {

            return nil
        }


        let nearestColumn =
            GridRoadTopology
                .nearestColumn(
                    toWorldX:
                        point.x
                )

        let nearestRow =
            GridRoadTopology
                .nearestRow(
                    toWorldY:
                        point.y
                )


        let nearestVerticalX =
            GridMapGeometry
                .verticalStreetCenterX(
                    column:
                        nearestColumn
                )

        let nearestHorizontalY =
            GridMapGeometry
                .horizontalStreetCenterY(
                    row:
                        nearestRow
                )


        let distanceToVertical =
            abs(
                point.x
                - nearestVerticalX
            )

        let distanceToHorizontal =
            abs(
                point.y
                - nearestHorizontalY
            )


        let isInsideVerticalRoad =
            distanceToVertical
            <= roadThreshold

        let rowIsValid =
            GridRoadTopology
                .intersectionRowRange
                .contains(
                    nearestRow
                )

        let isInsideHorizontalRoad =
            rowIsValid
            && distanceToHorizontal
                <= roadThreshold


        // -------------------------------------------------
        // Intersection first.
        // -------------------------------------------------

        if
            isInsideVerticalRoad,
            isInsideHorizontalRoad
        {

            let intersection =
                GridIntersectionID(
                    column:
                        nearestColumn,
                    row:
                        nearestRow
                )

            let vertexID =
                GridRoadTopology
                    .vertexID(
                        for:
                            intersection
                    )


            if let vertex =
                graph.vertex(
                    id:
                        vertexID
                )
            {

                return resolvedVertexHit(
                    vertex
                )
            }
        }


        // -------------------------------------------------
        // Horizontal road section.
        //
        // Resolve the user's touch onto the road centerline before turning
        // the point into semantic time/progress coordinates.
        // -------------------------------------------------

        if isInsideHorizontalRoad {

            let leftColumn =
                Int(
                    floor(
                        (
                            point.x
                            - GridMapGeometry.origin.x
                        )
                        / pitch
                    )
                )

            let edgeID =
                GridRoadTopology
                    .horizontalEdgeID(
                        row:
                            nearestRow,
                        leftColumn:
                            leftColumn
                    )


            if let edge =
                graph.edge(
                    id:
                        edgeID
                ),
               let hit = resolvedEdgeHit(
                    edge,
                    tapPoint:
                        point,
                    graph:
                        graph
               )
            {

                return hit
            }
        }


        // -------------------------------------------------
        // Vertical road section.
        // -------------------------------------------------

        if isInsideVerticalRoad {

            let topRow =
                Int(
                    floor(
                        (
                            GridMapGeometry.origin.y
                            - point.y
                        )
                        / pitch
                    )
                )


            guard
                topRow >= 0,
                topRow
                    < GridRoadTopology
                        .maximumIntersectionRow
            else {

                return nil
            }


            let edgeID =
                GridRoadTopology
                    .verticalEdgeID(
                        column:
                            nearestColumn,
                        topRow:
                            topRow
                    )


            if let edge =
                graph.edge(
                    id:
                        edgeID
                ),
               let hit = resolvedEdgeHit(
                    edge,
                    tapPoint:
                        point,
                    graph:
                        graph
               )
            {

                return hit
            }
        }


        return nil
    }
}


// =====================================================
// MARK: - Compatibility Fallback
// =====================================================

private extension RoadHitTester {

    func genericHitTest(
        at point: CGPoint,
        graph: RoadGraph,
        tolerance: CGFloat
    ) -> Hit? {

        let threshold =
            GridMapConfiguration
                .roadHalfWidthWorld
            + max(
                0,
                tolerance
            )


        // Vertices first.
        var bestVertex: RoadVertex?
        var bestVertexDistance =
            CGFloat.greatestFiniteMagnitude


        for vertex in graph.vertices {

            let location =
                vertex.worldPoint.cgPoint

            let distance =
                hypot(
                    location.x - point.x,
                    location.y - point.y
                )


            guard
                distance <= threshold,
                distance < bestVertexDistance
            else {

                continue
            }


            bestVertexDistance = distance
            bestVertex = vertex
        }


        if let bestVertex {

            return resolvedVertexHit(
                bestVertex
            )
        }


        // Edges second. Keep the closest projected point rather than the raw
        // touch point so callers receive a coordinate on the road itself.
        let tapWorldPoint =
            WorldPoint(
                x:
                    Double(point.x),
                y:
                    Double(point.y)
            )

        var bestEdge: RoadEdge?
        var bestProjection: RoadEdgeProjection?


        for edge in graph.edges {

            guard
                edge.attributes.isTraversable,
                edge.travelDirection != .closed,
                let projection =
                    RoadEdgeGeometry
                        .projection(
                            of:
                                tapWorldPoint,
                            onto:
                                edge,
                            graph:
                                graph
                        ),
                projection.distance
                    <= Double(threshold)
            else {

                continue
            }


            if
                bestProjection == nil
                || projection.distance
                    < bestProjection!.distance
            {

                bestEdge = edge
                bestProjection = projection
            }
        }


        guard
            let bestEdge,
            let bestProjection
        else {

            return nil
        }


        return resolvedEdgeHit(
            edgeID:
                bestEdge.id,
            projectedWorldPoint:
                bestProjection.point
        )
    }
}


// =====================================================
// MARK: - Resolved Hit Helpers
// =====================================================

private extension RoadHitTester {

    func resolvedVertexHit(
        _ vertex: RoadVertex
    ) -> Hit {

        let worldPoint =
            vertex.worldPoint

        return .vertex(
            id:
                vertex.id,
            worldPoint:
                worldPoint,
            mapCoordinate:
                MapCoordinateConverter
                    .mapCoordinate(
                        for:
                            worldPoint
                    )
        )
    }


    func resolvedEdgeHit(
        _ edge: RoadEdge,
        tapPoint: CGPoint,
        graph: RoadGraph
    ) -> Hit? {

        let tapWorldPoint =
            WorldPoint(
                x:
                    Double(tapPoint.x),
                y:
                    Double(tapPoint.y)
            )


        guard let projection =
            RoadEdgeGeometry
                .projection(
                    of:
                        tapWorldPoint,
                    onto:
                        edge,
                    graph:
                        graph
                )
        else {

            return nil
        }


        return resolvedEdgeHit(
            edgeID:
                edge.id,
            projectedWorldPoint:
                projection.point
        )
    }


    func resolvedEdgeHit(
        edgeID: RoadEdgeID,
        projectedWorldPoint: WorldPoint
    ) -> Hit {

        .edge(
            id:
                edgeID,
            worldPoint:
                projectedWorldPoint,
            mapCoordinate:
                MapCoordinateConverter
                    .mapCoordinate(
                        for:
                            projectedWorldPoint
                    )
        )
    }
}
