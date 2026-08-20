//
//  RoadEdgeGeometry.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/19/26.
//


import Foundation
import CoreGraphics


struct RoadEdgeProjection:
    Equatable,
    Sendable {

    let point:
        WorldPoint


    /// 0 = fromID
    /// 1 = toID
    let fraction:
        Double


    let distance:
        Double
}


enum RoadEdgeGeometry {

    // =====================================================
    // MARK: - Sampled Geometry
    // =====================================================

    static func sampledPoints(
        for edge:
            RoadEdge,
        graph:
            RoadGraph,
        cubicSegments:
            Int = 32
    ) -> [WorldPoint] {

        guard
            let fromVertex =
                graph.vertex(
                    id:
                        edge.fromID
                ),

            let toVertex =
                graph.vertex(
                    id:
                        edge.toID
                )
        else {

            return []
        }


        let start =
            fromVertex.worldPoint


        let end =
            toVertex.worldPoint


        switch edge.shape {

        // =============================================
        // Straight
        // =============================================

        case .straight:

            return [
                start,
                end
            ]


        // =============================================
        // Polyline
        // =============================================

        case let .polyline(
            intermediatePoints
        ):

            return [
                start
            ]
            +
            intermediatePoints
            +
            [
                end
            ]


        // =============================================
        // Cubic Bezier
        // =============================================

        case let .cubicBezier(
            control1,
            control2
        ):

            let count =
                max(
                    cubicSegments,
                    2
                )


            return (
                0...count
            )
            .map { index in

                let t =
                    Double(index)
                    /
                    Double(count)


                return cubicPoint(
                    start:
                        start,
                    control1:
                        control1,
                    control2:
                        control2,
                    end:
                        end,
                    t:
                        t
                )
            }
        }
    }
}

private extension RoadEdgeGeometry {

    static func cubicPoint(
        start:
            WorldPoint,
        control1:
            WorldPoint,
        control2:
            WorldPoint,
        end:
            WorldPoint,
        t:
            Double
    ) -> WorldPoint {

        let oneMinusT =
            1 - t


        let a =
            oneMinusT
            *
            oneMinusT
            *
            oneMinusT


        let b =
            3
            *
            oneMinusT
            *
            oneMinusT
            *
            t


        let c =
            3
            *
            oneMinusT
            *
            t
            *
            t


        let d =
            t
            *
            t
            *
            t


        return WorldPoint(
            x:
                a * start.x
                +
                b * control1.x
                +
                c * control2.x
                +
                d * end.x,

            y:
                a * start.y
                +
                b * control1.y
                +
                c * control2.y
                +
                d * end.y
        )
    }
}

extension RoadEdgeGeometry {

    static func length(
        of edge:
            RoadEdge,
        graph:
            RoadGraph
    ) -> Double {

        let points =
            sampledPoints(
                for:
                    edge,
                graph:
                    graph
            )


        guard
            points.count >= 2
        else {

            return 0
        }


        return zip(
            points,
            points.dropFirst()
        )
        .reduce(
            0
        ) { result, pair in

            result
            +
            distance(
                pair.0,
                pair.1
            )
        }
    }
}

private extension RoadEdgeGeometry {

    static func distance(
        _ lhs:
            WorldPoint,
        _ rhs:
            WorldPoint
    ) -> Double {

        hypot(
            lhs.x - rhs.x,
            lhs.y - rhs.y
        )
    }
}

extension RoadEdgeGeometry {

    static func projection(
        of worldPoint:
            WorldPoint,
        onto edge:
            RoadEdge,
        graph:
            RoadGraph
    ) -> RoadEdgeProjection? {

        let points =
            sampledPoints(
                for:
                    edge,
                graph:
                    graph
            )


        guard
            points.count >= 2
        else {

            return nil
        }


        // =============================================
        // Segment lengths
        // =============================================

        let segmentLengths =
            zip(
                points,
                points.dropFirst()
            )
            .map {

                distance(
                    $0.0,
                    $0.1
                )
            }


        let totalLength =
            segmentLengths.reduce(
                0,
                +
            )


        guard
            totalLength > 0
        else {

            return nil
        }


        // =============================================
        // Find closest projected point
        // =============================================

        var bestDistance =
            Double.greatestFiniteMagnitude


        var bestPoint =
            points[0]


        var bestDistanceAlongEdge:
            Double = 0


        var accumulatedLength:
            Double = 0


        for index in
            0..<segmentLengths.count {

            let a =
                points[index]


            let b =
                points[index + 1]


            let projection =
                project(
                    worldPoint,
                    ontoSegmentFrom:
                        a,
                    to:
                        b
                )


            let projectionDistance =
                distance(
                    worldPoint,
                    projection.point
                )


            if projectionDistance <
                bestDistance {

                bestDistance =
                    projectionDistance


                bestPoint =
                    projection.point


                bestDistanceAlongEdge =
                    accumulatedLength
                    +
                    projection.segmentFraction
                    *
                    segmentLengths[index]
            }


            accumulatedLength +=
                segmentLengths[index]
        }


        let fraction =
            min(
                max(
                    bestDistanceAlongEdge
                    /
                    totalLength,
                    0
                ),
                1
            )


        return RoadEdgeProjection(
            point:
                bestPoint,
            fraction:
                fraction,
            distance:
                bestDistance
        )
    }
}

private extension RoadEdgeGeometry {

    struct SegmentProjection {

        let point:
            WorldPoint

        let segmentFraction:
            Double
    }


    static func project(
        _ point:
            WorldPoint,
        ontoSegmentFrom a:
            WorldPoint,
        to b:
            WorldPoint
    ) -> SegmentProjection {

        let dx =
            b.x - a.x


        let dy =
            b.y - a.y


        let lengthSquared =
            dx * dx
            +
            dy * dy


        guard
            lengthSquared > 0
        else {

            return SegmentProjection(
                point:
                    a,
                segmentFraction:
                    0
            )
        }


        let rawT =
            (
                (point.x - a.x) * dx
                +
                (point.y - a.y) * dy
            )
            /
            lengthSquared


        let t =
            min(
                max(
                    rawT,
                    0
                ),
                1
            )


        return SegmentProjection(
            point:
                WorldPoint(
                    x:
                        a.x
                        +
                        dx * t,
                    y:
                        a.y
                        +
                        dy * t
                ),
            segmentFraction:
                t
        )
    }
}

extension RoadEdgeGeometry {

    static func point(
        atFraction fraction:
            Double,
        on edge:
            RoadEdge,
        graph:
            RoadGraph,
        cubicSegments:
            Int = 64
    ) -> WorldPoint? {

        let points =
            sampledPoints(
                for:
                    edge,
                graph:
                    graph,
                cubicSegments:
                    cubicSegments
            )


        guard
            points.count >= 2
        else {

            return points.first
        }


        let clampedFraction =
            min(
                max(
                    fraction,
                    0
                ),
                1
            )


        // =============================================
        // Segment lengths
        // =============================================

        let segmentLengths =
            zip(
                points,
                points.dropFirst()
            )
            .map {

                distance(
                    $0.0,
                    $0.1
                )
            }


        let totalLength =
            segmentLengths.reduce(
                0,
                +
            )


        guard
            totalLength > 0
        else {

            return points.first
        }


        let targetDistance =
            totalLength
            *
            clampedFraction


        var accumulated:
            Double = 0


        for index in
            segmentLengths.indices {

            let segmentLength =
                segmentLengths[
                    index
                ]


            let nextAccumulated =
                accumulated
                +
                segmentLength


            if
                targetDistance <=
                    nextAccumulated

                ||

                index ==
                    segmentLengths.count - 1
            {

                guard
                    segmentLength > 0
                else {

                    return points[index]
                }


                let localFraction =
                    (
                        targetDistance
                        -
                        accumulated
                    )
                    /
                    segmentLength


                return interpolate(
                    from:
                        points[index],
                    to:
                        points[index + 1],
                    fraction:
                        localFraction
                )
            }


            accumulated =
                nextAccumulated
        }


        return points.last
    }
}

private extension RoadEdgeGeometry {

    static func interpolate(
        from start:
            WorldPoint,
        to end:
            WorldPoint,
        fraction:
            Double
    ) -> WorldPoint {

        WorldPoint(
            x:
                start.x
                +
                (
                    end.x
                    -
                    start.x
                )
                *
                fraction,

            y:
                start.y
                +
                (
                    end.y
                    -
                    start.y
                )
                *
                fraction
        )
    }
}

extension RoadEdgeGeometry {

    static func sampledPoints(
        along segment:
            RoadRouteSegment,
        graph:
            RoadGraph,
        cubicSegments:
            Int = 64
    ) -> [WorldPoint] {

        guard let edge =
            graph.edge(
                id:
                    segment.edgeID
            )
        else {

            return []
        }


        let fromFraction =
            min(
                max(
                    segment.fromFraction,
                    0
                ),
                1
            )


        let toFraction =
            min(
                max(
                    segment.toFraction,
                    0
                ),
                1
            )


        // =============================================
        // Same point
        // =============================================

        guard
            abs(
                toFraction
                -
                fromFraction
            )
            >
            0.000_001
        else {

            if let point =
                point(
                    atFraction:
                        fromFraction,
                    on:
                        edge,
                    graph:
                        graph,
                    cubicSegments:
                        cubicSegments
                )
            {

                return [
                    point
                ]
            }


            return []
        }


        /*
         Use enough samples that partial traversal of a
         curved edge is inspected throughout its shape.
         */

        let fullSampleCount =
            max(
                cubicSegments,
                8
            )


        let traversedFraction =
            abs(
                toFraction
                -
                fromFraction
            )


        let count =
            max(
                Int(
                    ceil(
                        Double(
                            fullSampleCount
                        )
                        *
                        traversedFraction
                    )
                ),
                2
            )


        return (
            0...count
        )
        .compactMap { index in

            let t =
                Double(index)
                /
                Double(count)


            let edgeFraction =
                fromFraction
                +
                (
                    toFraction
                    -
                    fromFraction
                )
                *
                t


            return point(
                atFraction:
                    edgeFraction,
                on:
                    edge,
                graph:
                    graph,
                cubicSegments:
                    cubicSegments
            )
        }
    }
}
