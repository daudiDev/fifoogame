//
//  RoadHitTester.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/19/26.
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

        let verticesByID =
            Dictionary(
                uniqueKeysWithValues:
                    graph.vertices.map {
                        ($0.id, $0)
                    }
            )


        // =========================================
        // Vertices get priority.
        // =========================================

        if let vertex =
            nearestInteractiveVertex(
                to: point,
                graph: graph,
                tolerance:
                    tolerance * 1.15
            )
        {

            return .vertex(
                vertex.id
            )
        }


        // =========================================
        // Resolve visual roundabout geometry.
        // =========================================

        let roundabouts =
            resolveRoundabouts(
                graph:
                    graph,
                verticesByID:
                    verticesByID
            )


        var bestEdge:
            RoadEdgeID?


        var bestDistance =
            CGFloat.greatestFiniteMagnitude


        for edge in graph.edges {

            guard
                edge.attributes
                    .isTraversable,

                edge.travelDirection
                    != .closed
            else {

                continue
            }


            guard
                let points =
                    sampledPoints(
                        for:
                            edge,
                        verticesByID:
                            verticesByID,
                        roundabouts:
                            roundabouts
                    )
            else {

                continue
            }


            let distance =
                distance(
                    from:
                        point,
                    toPolyline:
                        points
                )


            /*
             Add part of the actual road width
             to the finger tolerance.

             This means tapping near the outer
             edge of a wide highway still works.
             */

            let threshold =
                tolerance
                +
                approximateHalfRoadWidth(
                    for:
                        edge.roadClass
                )


            guard distance <=
                threshold
            else {

                continue
            }


            if distance <
                bestDistance {

                bestDistance =
                    distance


                bestEdge =
                    edge.id
            }
        }


        guard let bestEdge else {

            return nil
        }


        return .edge(
            bestEdge
        )
    }
}

// =====================================================
// MARK: - Vertex Hit Testing
// =====================================================

private extension RoadHitTester {

    func nearestInteractiveVertex(
        to point:
            CGPoint,
        graph:
            RoadGraph,
        tolerance:
            CGFloat
    ) -> RoadVertex? {

        var bestVertex:
            RoadVertex?


        var bestDistance =
            CGFloat.greatestFiniteMagnitude


        for vertex in
            graph.vertices {

            let degree =
                graph.degree(
                    of:
                        vertex.id
                )


            /*
             We don't want invisible two-edge
             geometry/junction control points to
             constantly steal road taps.

             Interactive:
             - real intersections
             - 3+ way junctions
             - roundabout entry/exit
             - cul-de-sac end
             */

            let isInteractive =
                vertex.kind ==
                    .intersection
                ||
                vertex.kind ==
                    .circleEntry
                ||
                vertex.kind ==
                    .circleExit
                ||
                vertex.kind ==
                    .culDeSacEnd
                ||
                degree >= 3


            guard isInteractive else {

                continue
            }


            let location =
                vertex
                    .worldPoint
                    .cgPoint


            let distance =
                hypot(
                    location.x
                    - point.x,

                    location.y
                    - point.y
                )


            guard distance <=
                tolerance
            else {

                continue
            }


            if distance <
                bestDistance {

                bestDistance =
                    distance


                bestVertex =
                    vertex
            }
        }


        return bestVertex
    }
}

// =====================================================
// MARK: - Road Geometry Sampling
// =====================================================

private extension RoadHitTester {

    func sampledPoints(
        for edge:
            RoadEdge,
        verticesByID:
            [RoadVertexID: RoadVertex],
        roundabouts:
            [RoadEdgeID:
                RoundaboutGeometry]
    ) -> [CGPoint]? {

        guard
            let from =
                verticesByID[
                    edge.fromID
                ],

            let to =
                verticesByID[
                    edge.toID
                ]
        else {

            return nil
        }


        let start =
            from
                .worldPoint
                .cgPoint


        let end =
            to
                .worldPoint
                .cgPoint


        // -----------------------------------------
        // Roundabout visual geometry
        // -----------------------------------------

        if
            edge.roadClass ==
                .circle,

            let roundabout =
                roundabouts[
                    edge.id
                ]
        {

            return sampleEllipseArc(
                start:
                    start,
                end:
                    end,
                geometry:
                    roundabout,
                steps:
                    18
            )
        }


        switch edge.shape {

        // -----------------------------------------
        // Straight
        // -----------------------------------------

        case .straight:

            return [
                start,
                end
            ]


        // -----------------------------------------
        // Polyline
        // -----------------------------------------

        case let .polyline(
            intermediatePoints
        ):

            return
                [start]
                +
                intermediatePoints.map(
                    \.cgPoint
                )
                +
                [end]


        // -----------------------------------------
        // Bézier
        // -----------------------------------------

        case let .cubicBezier(
            control1,
            control2
        ):

            return sampleCubic(
                start:
                    start,
                control1:
                    control1.cgPoint,
                control2:
                    control2.cgPoint,
                end:
                    end,
                steps:
                    20
            )
        }
    }


    func sampleCubic(
        start:
            CGPoint,
        control1:
            CGPoint,
        control2:
            CGPoint,
        end:
            CGPoint,
        steps:
            Int
    ) -> [CGPoint] {

        var result:
            [CGPoint] = []


        for index in
            0...steps {

            let t =
                CGFloat(index)
                /
                CGFloat(steps)


            let u =
                1 - t


            let x =
                u * u * u
                * start.x
                +
                3 * u * u * t
                * control1.x
                +
                3 * u * t * t
                * control2.x
                +
                t * t * t
                * end.x


            let y =
                u * u * u
                * start.y
                +
                3 * u * u * t
                * control1.y
                +
                3 * u * t * t
                * control2.y
                +
                t * t * t
                * end.y


            result.append(

                CGPoint(
                    x:
                        x,
                    y:
                        y
                )
            )
        }


        return result
    }
}

// =====================================================
// MARK: - Roundabout Geometry
// =====================================================

private extension RoadHitTester {

    struct RoundaboutGeometry {

        let center:
            CGPoint

        let radiusX:
            CGFloat

        let radiusY:
            CGFloat
    }


    func resolveRoundabouts(
        graph:
            RoadGraph,
        verticesByID:
            [RoadVertexID: RoadVertex]
    ) -> [RoadEdgeID:
            RoundaboutGeometry] {

        let circleEdges =
            graph.edges.filter {

                $0.roadClass ==
                    .circle
            }


        guard !circleEdges.isEmpty else {

            return [:]
        }


        let edgesByID =
            Dictionary(
                uniqueKeysWithValues:
                    circleEdges.map {
                        ($0.id, $0)
                    }
            )


        var edgesByVertex:
            [RoadVertexID:
                [RoadEdgeID]] = [:]


        for edge in
            circleEdges {

            edgesByVertex[
                edge.fromID,
                default: []
            ]
            .append(
                edge.id
            )


            edgesByVertex[
                edge.toID,
                default: []
            ]
            .append(
                edge.id
            )
        }


        var unvisited =
            Set(
                circleEdges.map(
                    \.id
                )
            )


        var result:
            [RoadEdgeID:
                RoundaboutGeometry] = [:]


        while let firstEdgeID =
            unvisited.first {

            var stack =
                [firstEdgeID]


            var componentEdges =
                Set<RoadEdgeID>()


            var componentVertices =
                Set<RoadVertexID>()


            while let edgeID =
                stack.popLast() {

                guard
                    componentEdges
                        .insert(
                            edgeID
                        )
                        .inserted,

                    let edge =
                        edgesByID[
                            edgeID
                        ]
                else {

                    continue
                }


                unvisited.remove(
                    edgeID
                )


                componentVertices.insert(
                    edge.fromID
                )


                componentVertices.insert(
                    edge.toID
                )


                for vertexID in [
                    edge.fromID,
                    edge.toID
                ] {

                    for neighborEdgeID in
                        edgesByVertex[
                            vertexID,
                            default: []
                        ] {

                        if !componentEdges
                            .contains(
                                neighborEdgeID
                            )
                        {

                            stack.append(
                                neighborEdgeID
                            )
                        }
                    }
                }
            }


            let points =
                componentVertices
                    .compactMap {

                        verticesByID[$0]?
                            .worldPoint
                            .cgPoint
                    }


            guard points.count >= 3 else {

                continue
            }


            let center =
                CGPoint(
                    x:
                        points
                            .map(\.x)
                            .reduce(0, +)
                        /
                        CGFloat(
                            points.count
                        ),

                    y:
                        points
                            .map(\.y)
                            .reduce(0, +)
                        /
                        CGFloat(
                            points.count
                        )
                )


            let radiusX =
                points
                    .map {

                        abs(
                            $0.x
                            - center.x
                        )
                    }
                    .max()
                ?? 1


            let radiusY =
                points
                    .map {

                        abs(
                            $0.y
                            - center.y
                        )
                    }
                    .max()
                ?? 1


            let geometry =
                RoundaboutGeometry(
                    center:
                        center,
                    radiusX:
                        radiusX,
                    radiusY:
                        radiusY
                )


            for edgeID in
                componentEdges {

                result[
                    edgeID
                ] =
                    geometry
            }
        }


        return result
    }
}

// =====================================================
// MARK: - Roundabout Arc Sampling
// =====================================================

private extension RoadHitTester {

    func sampleEllipseArc(
        start:
            CGPoint,
        end:
            CGPoint,
        geometry:
            RoundaboutGeometry,
        steps:
            Int
    ) -> [CGPoint] {

        let radiusX =
            max(
                geometry.radiusX,
                0.001
            )


        let radiusY =
            max(
                geometry.radiusY,
                0.001
            )


        let startAngle =
            atan2(
                Double(
                    (
                        start.y
                        -
                        geometry.center.y
                    )
                    /
                    radiusY
                ),
                Double(
                    (
                        start.x
                        -
                        geometry.center.x
                    )
                    /
                    radiusX
                )
            )


        let endAngle =
            atan2(
                Double(
                    (
                        end.y
                        -
                        geometry.center.y
                    )
                    /
                    radiusY
                ),
                Double(
                    (
                        end.x
                        -
                        geometry.center.x
                    )
                    /
                    radiusX
                )
            )


        var delta =
            endAngle
            -
            startAngle


        while delta >
            Double.pi {

            delta -=
                2
                *
                Double.pi
        }


        while delta <
            -Double.pi {

            delta +=
                2
                *
                Double.pi
        }


        var points:
            [CGPoint] = []


        for index in
            0...steps {

            let fraction =
                Double(index)
                /
                Double(steps)


            let angle =
                startAngle
                +
                delta
                *
                fraction


            points.append(

                CGPoint(
                    x:
                        geometry.center.x
                        +
                        radiusX
                        *
                        CGFloat(
                            cos(angle)
                        ),

                    y:
                        geometry.center.y
                        +
                        radiusY
                        *
                        CGFloat(
                            sin(angle)
                        )
                )
            )
        }


        return points
    }
}

// =====================================================
// MARK: - Distance
// =====================================================

private extension RoadHitTester {

    func distance(
        from point:
            CGPoint,
        toPolyline points:
            [CGPoint]
    ) -> CGFloat {

        guard points.count >= 2 else {

            return .greatestFiniteMagnitude
        }


        var best =
            CGFloat.greatestFiniteMagnitude


        for index in
            0..<(points.count - 1) {

            let distance =
                distanceToSegment(
                    point:
                        point,
                    start:
                        points[index],
                    end:
                        points[index + 1]
                )


            best =
                min(
                    best,
                    distance
                )
        }


        return best
    }


    func distanceToSegment(
        point:
            CGPoint,
        start:
            CGPoint,
        end:
            CGPoint
    ) -> CGFloat {

        let dx =
            end.x
            -
            start.x


        let dy =
            end.y
            -
            start.y


        let lengthSquared =
            dx * dx
            +
            dy * dy


        guard lengthSquared >
            0.0001
        else {

            return hypot(
                point.x
                -
                start.x,

                point.y
                -
                start.y
            )
        }


        let rawT =
            (
                (
                    point.x
                    -
                    start.x
                )
                *
                dx
                +
                (
                    point.y
                    -
                    start.y
                )
                *
                dy
            )
            /
            lengthSquared


        let t =
            min(
                1,
                max(
                    0,
                    rawT
                )
            )


        let closest =
            CGPoint(
                x:
                    start.x
                    +
                    t * dx,

                y:
                    start.y
                    +
                    t * dy
            )


        return hypot(
            point.x
            -
            closest.x,

            point.y
            -
            closest.y
        )
    }


    func approximateHalfRoadWidth(
        for roadClass:
            RoadClass
    ) -> CGFloat {

        /*
         Matches approximately the narrowed
         3D.1 road surfaces.
         */

        switch roadClass {

        case .local:
            return 6.5

        case .connector:
            return 7

        case .culDeSac:
            return 6.5

        case .arterial:
            return 10

        case .circle:
            return 10

        case .highway:
            return 14
        }
    }
}


