//
//  RoadHitTester.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/22/26.
//


import Foundation
import CoreGraphics


struct RoadHitTester {

    enum Hit:
        Equatable,
        Sendable {

        case vertex(
            RoadVertexID
        )

        case edge(
            RoadEdgeID
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
        // the app migrates. It intentionally uses one uniform road width;
        // the old highway/roundabout/cul-de-sac width rules are gone.
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


        // -------------------------------------------------
        // Reject taps completely outside the semantic day.
        // Horizontal streets at 00:00 and 24:00 are valid,
        // so include the road/touch threshold around them.
        // -------------------------------------------------

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
        //
        // The visual intersection is the overlap of the two
        // wide road corridors, so use the same geometry here.
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


            if graph.vertex(id: vertexID) != nil {

                return .vertex(
                    vertexID
                )
            }
        }


        // -------------------------------------------------
        // Horizontal road section.
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


            if graph.edge(id: edgeID) != nil {

                return .edge(
                    edgeID
                )
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


            if graph.edge(id: edgeID) != nil {

                return .edge(
                    edgeID
                )
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

            return .vertex(
                bestVertex.id
            )
        }


        // Edges second.
        var bestEdge: RoadEdge?
        var bestEdgeDistance =
            CGFloat.greatestFiniteMagnitude


        for edge in graph.edges {

            guard
                edge.attributes.isTraversable,
                edge.travelDirection != .closed
            else {

                continue
            }


            let sampled =
                RoadEdgeGeometry
                    .sampledPoints(
                        for:
                            edge,
                        graph:
                            graph
                    )
                    .map(\.cgPoint)


            guard sampled.count >= 2 else {
                continue
            }


            let distance =
                distance(
                    from:
                        point,
                    toPolyline:
                        sampled
                )


            guard
                distance <= threshold,
                distance < bestEdgeDistance
            else {

                continue
            }


            bestEdgeDistance = distance
            bestEdge = edge
        }


        guard let bestEdge else {
            return nil
        }


        return .edge(
            bestEdge.id
        )
    }
}


// =====================================================
// MARK: - Geometry Helpers
// =====================================================

private extension RoadHitTester {

    func distance(
        from point: CGPoint,
        toPolyline points: [CGPoint]
    ) -> CGFloat {

        guard points.count >= 2 else {
            return .greatestFiniteMagnitude
        }


        var best =
            CGFloat.greatestFiniteMagnitude


        for index in 0..<(points.count - 1) {

            best =
                min(
                    best,
                    distance(
                        from:
                            point,
                        toSegmentFrom:
                            points[index],
                        to:
                            points[index + 1]
                    )
                )
        }


        return best
    }


    func distance(
        from point: CGPoint,
        toSegmentFrom start: CGPoint,
        to end: CGPoint
    ) -> CGFloat {

        let dx =
            end.x - start.x

        let dy =
            end.y - start.y

        let lengthSquared =
            dx * dx
            + dy * dy


        guard lengthSquared > 0 else {

            return hypot(
                point.x - start.x,
                point.y - start.y
            )
        }


        let rawT =
            (
                (point.x - start.x) * dx
                + (point.y - start.y) * dy
            )
            / lengthSquared

        let t =
            min(
                max(
                    rawT,
                    0
                ),
                1
            )

        let projected =
            CGPoint(
                x:
                    start.x + dx * t,
                y:
                    start.y + dy * t
            )


        return hypot(
            point.x - projected.x,
            point.y - projected.y
        )
    }
}
