//
//  RoadRouteTimeClipper.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/19/26.
//

import Foundation


struct RoadRouteSegmentSplit:
    Equatable,
    Sendable {

    let completed:
        RoadRouteSegment?


    let future:
        RoadRouteSegment?


    let boundary:
        GameNodeRouteAnchor.RoadLocation?
}

enum RoadRouteTimeClipper {

    static func split(
        _ segment:
            RoadRouteSegment,
        at cutoff:
            DayTime,
        graph:
            RoadGraph,
        policy:
            RouteTimePolicy = .dayMap
    ) -> RoadRouteSegmentSplit {

        guard let edge =
            graph.edge(
                id:
                    segment.edgeID
            )
        else {

            return RoadRouteSegmentSplit(
                completed:
                    nil,
                future:
                    segment,
                boundary:
                    nil
            )
        }


        // =============================================
        // Segment endpoint times
        // =============================================

        guard
            let startTime =
                time(
                    atEdgeFraction:
                        segment.fromFraction,
                    edge:
                        edge,
                    graph:
                        graph,
                    policy:
                        policy
                ),

            let endTime =
                time(
                    atEdgeFraction:
                        segment.toFraction,
                    edge:
                        edge,
                    graph:
                        graph,
                    policy:
                        policy
                )
        else {

            return RoadRouteSegmentSplit(
                completed:
                    nil,
                future:
                    segment,
                boundary:
                    nil
            )
        }


        let startSeconds =
            startTime.secondsFromMidnight


        let endSeconds =
            endTime.secondsFromMidnight


        let cutoffSeconds =
            cutoff.secondsFromMidnight


        let tolerance =
            policy.backwardToleranceSeconds


        // =============================================
        // Horizontal-in-time road
        // =============================================

        if abs(
            endSeconds
            -
            startSeconds
        )
        <=
        tolerance {

            if cutoffSeconds >=
                endSeconds
                -
                tolerance {

                return RoadRouteSegmentSplit(
                    completed:
                        segment,
                    future:
                        nil,
                    boundary:
                        canonicalLocation(
                            edgeID:
                                segment.edgeID,
                            fraction:
                                segment.toFraction,
                            graph:
                                graph
                        )
                )

            } else {

                return RoadRouteSegmentSplit(
                    completed:
                        nil,
                    future:
                        segment,
                    boundary:
                        nil
                )
            }
        }


        // =============================================
        // Entirely Future
        // =============================================

        if cutoffSeconds <=
            startSeconds
            +
            tolerance {

            return RoadRouteSegmentSplit(
                completed:
                    nil,
                future:
                    segment,
                boundary:
                    canonicalLocation(
                        edgeID:
                            segment.edgeID,
                        fraction:
                            segment.fromFraction,
                        graph:
                            graph
                    )
            )
        }


        // =============================================
        // Entirely Completed
        // =============================================

        if cutoffSeconds >=
            endSeconds
            -
            tolerance {

            return RoadRouteSegmentSplit(
                completed:
                    segment,
                future:
                    nil,
                boundary:
                    canonicalLocation(
                        edgeID:
                            segment.edgeID,
                        fraction:
                            segment.toFraction,
                        graph:
                            graph
                    )
            )
        }


        // =============================================
        // Cut occurs inside this segment
        // =============================================

        let splitFraction =
            edgeFraction(
                on:
                    segment,
                at:
                    cutoff,
                edge:
                    edge,
                graph:
                    graph,
                policy:
                    policy
            )


        let completed =
            RoadRouteSegment(
                edgeID:
                    segment.edgeID,
                fromFraction:
                    segment.fromFraction,
                toFraction:
                    splitFraction
            )


        let future =
            RoadRouteSegment(
                edgeID:
                    segment.edgeID,
                fromFraction:
                    splitFraction,
                toFraction:
                    segment.toFraction
            )


        return RoadRouteSegmentSplit(
            completed:
                completed,
            future:
                future,
            boundary:
                canonicalLocation(
                    edgeID:
                        segment.edgeID,
                    fraction:
                        splitFraction,
                    graph:
                        graph
                )
        )
    }
}

private extension RoadRouteTimeClipper {

    static func time(
        atEdgeFraction fraction:
            Double,
        edge:
            RoadEdge,
        graph:
            RoadGraph,
        policy:
            RouteTimePolicy
    ) -> DayTime? {

        guard let worldPoint =
            RoadEdgeGeometry
                .point(
                    atFraction:
                        fraction,
                    on:
                        edge,
                    graph:
                        graph,
                    cubicSegments:
                        policy
                            .cubicGeometrySamples
                )
        else {

            return nil
        }


        return MapCoordinateConverter
            .mapCoordinate(
                for:
                    worldPoint
            )
            .time
    }
}

private extension RoadRouteTimeClipper {

    static func edgeFraction(
        on segment:
            RoadRouteSegment,
        at cutoff:
            DayTime,
        edge:
            RoadEdge,
        graph:
            RoadGraph,
        policy:
            RouteTimePolicy
    ) -> Double {

        var low:
            Double = 0


        var high:
            Double = 1


        /*
         local t:

         0 = segment.fromFraction
         1 = segment.toFraction
         */

        for _ in
            0..<40 {

            let middle =
                (
                    low
                    +
                    high
                )
                /
                2


            let edgeFraction =
                segment.fromFraction
                +
                (
                    segment.toFraction
                    -
                    segment.fromFraction
                )
                *
                middle


            guard let middleTime =
                time(
                    atEdgeFraction:
                        edgeFraction,
                    edge:
                        edge,
                    graph:
                        graph,
                    policy:
                        policy
                )
            else {

                break
            }


            if middleTime <=
                cutoff {

                low =
                    middle

            } else {

                high =
                    middle
            }
        }


        return segment.fromFraction
        +
        (
            segment.toFraction
            -
            segment.fromFraction
        )
        *
        low
    }
}

private extension RoadRouteTimeClipper {

    static func canonicalLocation(
        edgeID:
            RoadEdgeID,
        fraction:
            Double,
        graph:
            RoadGraph
    ) -> GameNodeRouteAnchor.RoadLocation {

        RoadLocationCanonicalizer
            .canonical(
                .edge(
                    edgeID:
                        edgeID,
                    fraction:
                        fraction
                ),
                graph:
                    graph
            )
    }
}

extension RoadRouteTimeClipper {

    static func portion(
        of segment:
            RoadRouteSegment,
        after startTime:
            DayTime?,
        through endTime:
            DayTime,
        graph:
            RoadGraph,
        policy:
            RouteTimePolicy = .dayMap
    ) -> RoadRouteSegment? {

        // =============================================
        // First clip everything after endTime.
        // =============================================

        let endSplit =
            split(
                segment,
                at:
                    endTime,
                graph:
                    graph,
                policy:
                    policy
            )


        guard let throughEnd =
            endSplit.completed
        else {

            return nil
        }


        // =============================================
        // First progression call:
        // everything through endTime is new.
        // =============================================

        guard let startTime else {

            return throughEnd
        }


        /*
         Now remove everything that was already
         completed through startTime.

         Interval semantics:

             (startTime, endTime]
         */

        let startSplit =
            split(
                throughEnd,
                at:
                    startTime,
                graph:
                    graph,
                policy:
                    policy
            )


        return startSplit.future
    }
}
