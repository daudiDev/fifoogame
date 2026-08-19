//
//  RoadGeometryValidator.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/18/26.
//

import Foundation
import CoreGraphics


struct RoadGeometryCrossingIssue:
    Equatable,
    Sendable,
    CustomStringConvertible {

    let firstEdgeID:
        RoadEdgeID

    let secondEdgeID:
        RoadEdgeID


    var description: String {

        """
        Road \(firstEdgeID.rawValue) crosses \
        \(secondEdgeID.rawValue) without a \
        shared RoadVertex.
        """
    }
}


enum RoadGeometryValidator {

    static func crossingsWithoutSharedVertex(
        in graph: RoadGraph
    ) -> [RoadGeometryCrossingIssue] {

        let verticesByID =
            Dictionary(
                uniqueKeysWithValues:
                    graph.vertices.map {
                        ($0.id, $0)
                    }
            )


        let sampled =
            graph.edges.compactMap {

                sampledGeometry(
                    edge: $0,
                    verticesByID:
                        verticesByID
                )
            }


        var issues:
            [RoadGeometryCrossingIssue] = []


        guard sampled.count > 1 else {

            return issues
        }


        for firstIndex in
            0..<(sampled.count - 1) {

            let first =
                sampled[firstIndex]


            for secondIndex in
                (firstIndex + 1)..<sampled.count {

                let second =
                    sampled[secondIndex]


                /*
                 Shared RoadVertex means this
                 intersection is legitimate.
                 */

                if sharesEndpoint(
                    first.edge,
                    second.edge
                ) {

                    continue
                }


                guard
                    first.bounds.intersects(
                        second.bounds
                    )
                else {

                    continue
                }


                if polylinesIntersect(
                    first.points,
                    second.points
                ) {

                    issues.append(

                        RoadGeometryCrossingIssue(
                            firstEdgeID:
                                first.edge.id,

                            secondEdgeID:
                                second.edge.id
                        )
                    )
                }
            }
        }


        return issues
    }
    
    static func edgeCreatesIllegalCrossing(
        _ candidate: RoadEdge,
        in graph: RoadGraph
    ) -> Bool {

        let verticesByID =
            Dictionary(
                uniqueKeysWithValues:
                    graph.vertices.map {
                        ($0.id, $0)
                    }
            )


        guard
            let candidateGeometry =
                sampledGeometry(
                    edge: candidate,
                    verticesByID:
                        verticesByID
                )
        else {

            return true
        }


        for existingEdge in graph.edges {

            /*
             A shared vertex means the roads
             legitimately meet.
             */

            if sharesEndpoint(
                candidate,
                existingEdge
            ) {

                continue
            }


            guard
                let existingGeometry =
                    sampledGeometry(
                        edge: existingEdge,
                        verticesByID:
                            verticesByID
                    )
            else {

                continue
            }


            guard
                candidateGeometry
                    .bounds
                    .intersects(
                        existingGeometry.bounds
                    )
            else {

                continue
            }


            if polylinesIntersect(
                candidateGeometry.points,
                existingGeometry.points
            ) {

                return true
            }
        }


        return false
    }
    
}


// =====================================================
// MARK: - Sampling
// =====================================================

private extension RoadGeometryValidator {

    struct SampledGeometry {

        let edge: RoadEdge

        let points: [CGPoint]

        let bounds: CGRect
    }


    static func sampledGeometry(
        edge: RoadEdge,
        verticesByID:
            [RoadVertexID: RoadVertex]
    ) -> SampledGeometry? {

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
            from.worldPoint.cgPoint

        let end =
            to.worldPoint.cgPoint


        let points:
            [CGPoint]


        switch edge.shape {

        case .straight:

            points = [
                start,
                end
            ]


        case let .polyline(
            intermediatePoints
        ):

            points =
                [start]
                +
                intermediatePoints.map(
                    \.cgPoint
                )
                +
                [end]


        case let .cubicBezier(
            control1,
            control2
        ):

            points =
                sampleCubicBezier(
                    start: start,
                    control1:
                        control1.cgPoint,
                    control2:
                        control2.cgPoint,
                    end: end,
                    steps: 16
                )
        }


        return SampledGeometry(
            edge: edge,
            points: points,
            bounds:
                boundingRect(
                    points
                )
        )
    }


    static func sampleCubicBezier(
        start: CGPoint,
        control1: CGPoint,
        control2: CGPoint,
        end: CGPoint,
        steps: Int
    ) -> [CGPoint] {

        var points:
            [CGPoint] = []


        for index in 0...steps {

            let t =
                CGFloat(index)
                /
                CGFloat(steps)


            let u =
                1 - t


            let x =
                u * u * u * start.x
                +
                3 * u * u * t
                * control1.x
                +
                3 * u * t * t
                * control2.x
                +
                t * t * t * end.x


            let y =
                u * u * u * start.y
                +
                3 * u * u * t
                * control1.y
                +
                3 * u * t * t
                * control2.y
                +
                t * t * t * end.y


            points.append(
                CGPoint(
                    x: x,
                    y: y
                )
            )
        }


        return points
    }
}

// =====================================================
// MARK: - Intersection Detection
// =====================================================

private extension RoadGeometryValidator {

    static func sharesEndpoint(
        _ first: RoadEdge,
        _ second: RoadEdge
    ) -> Bool {

        first.fromID == second.fromID
        ||
        first.fromID == second.toID
        ||
        first.toID == second.fromID
        ||
        first.toID == second.toID
    }


    static func polylinesIntersect(
        _ first: [CGPoint],
        _ second: [CGPoint]
    ) -> Bool {

        guard
            first.count >= 2,
            second.count >= 2
        else {

            return false
        }


        for firstIndex in
            0..<(first.count - 1) {

            for secondIndex in
                0..<(second.count - 1) {

                if segmentsIntersect(
                    first[firstIndex],
                    first[firstIndex + 1],
                    second[secondIndex],
                    second[secondIndex + 1]
                ) {

                    return true
                }
            }
        }


        return false
    }


    static func segmentsIntersect(
        _ a: CGPoint,
        _ b: CGPoint,
        _ c: CGPoint,
        _ d: CGPoint
    ) -> Bool {

        let epsilon:
            CGFloat = 0.001


        let o1 =
            orientation(
                a,
                b,
                c
            )


        let o2 =
            orientation(
                a,
                b,
                d
            )


        let o3 =
            orientation(
                c,
                d,
                a
            )


        let o4 =
            orientation(
                c,
                d,
                b
            )


        let firstOpposite =
            (
                o1 > epsilon
                &&
                o2 < -epsilon
            )
            ||
            (
                o1 < -epsilon
                &&
                o2 > epsilon
            )


        let secondOpposite =
            (
                o3 > epsilon
                &&
                o4 < -epsilon
            )
            ||
            (
                o3 < -epsilon
                &&
                o4 > epsilon
            )


        if firstOpposite
            &&
            secondOpposite {

            return true
        }


        if
            abs(o1) <= epsilon
            &&
            point(
                c,
                liesOnSegmentFrom:
                    a,
                to:
                    b
            )
        {

            return true
        }


        if
            abs(o2) <= epsilon
            &&
            point(
                d,
                liesOnSegmentFrom:
                    a,
                to:
                    b
            )
        {

            return true
        }


        if
            abs(o3) <= epsilon
            &&
            point(
                a,
                liesOnSegmentFrom:
                    c,
                to:
                    d
            )
        {

            return true
        }


        if
            abs(o4) <= epsilon
            &&
            point(
                b,
                liesOnSegmentFrom:
                    c,
                to:
                    d
            )
        {

            return true
        }


        return false
    }


    static func orientation(
        _ a: CGPoint,
        _ b: CGPoint,
        _ c: CGPoint
    ) -> CGFloat {

        (
            b.x - a.x
        )
        *
        (
            c.y - a.y
        )
        -
        (
            b.y - a.y
        )
        *
        (
            c.x - a.x
        )
    }


    static func point(
        _ point: CGPoint,
        liesOnSegmentFrom start:
            CGPoint,
        to end:
            CGPoint
    ) -> Bool {

        let epsilon:
            CGFloat = 0.001


        return
            point.x
            >=
            min(
                start.x,
                end.x
            )
            - epsilon
            &&
            point.x
            <=
            max(
                start.x,
                end.x
            )
            + epsilon
            &&
            point.y
            >=
            min(
                start.y,
                end.y
            )
            - epsilon
            &&
            point.y
            <=
            max(
                start.y,
                end.y
            )
            + epsilon
    }


    static func boundingRect(
        _ points: [CGPoint]
    ) -> CGRect {

        guard let first =
            points.first
        else {

            return .zero
        }


        var minimumX =
            first.x

        var maximumX =
            first.x

        var minimumY =
            first.y

        var maximumY =
            first.y


        for point in points.dropFirst() {

            minimumX =
                min(
                    minimumX,
                    point.x
                )

            maximumX =
                max(
                    maximumX,
                    point.x
                )

            minimumY =
                min(
                    minimumY,
                    point.y
                )

            maximumY =
                max(
                    maximumY,
                    point.y
                )
        }


        /*
         Slight expansion handles perfectly
         horizontal / vertical segments.
         */

        return CGRect(
            x:
                minimumX - 0.5,

            y:
                minimumY - 0.5,

            width:
                maximumX
                - minimumX
                + 1,

            height:
                maximumY
                - minimumY
                + 1
        )
    }
}
