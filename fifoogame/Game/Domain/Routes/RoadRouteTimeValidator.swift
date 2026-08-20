//
//  RoadRouteTimeValidator.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/19/26.
//


import Foundation


struct RoadRouteTimeViolation:
    Equatable,
    Sendable {

    let previousTime:
        DayTime


    let nextTime:
        DayTime


    let previousWorldPoint:
        WorldPoint


    let nextWorldPoint:
        WorldPoint
}


enum RoadRouteTimeValidator {

    // =====================================================
    // MARK: - Segment
    // =====================================================

    static func validate(
        segment:
            RoadRouteSegment,
        graph:
            RoadGraph,
        policy:
            RouteTimePolicy = .dayMap
    ) -> RoadRouteTimeViolation? {

        let points =
            RoadEdgeGeometry
                .sampledPoints(
                    along:
                        segment,
                    graph:
                        graph,
                    cubicSegments:
                        policy
                            .cubicGeometrySamples
                )


        guard
            points.count >= 2
        else {

            return nil
        }


        for (
            previousPoint,
            nextPoint
        ) in zip(
            points,
            points.dropFirst()
        ) {

            let previousCoordinate =
                MapCoordinateConverter
                    .mapCoordinate(
                        for:
                            previousPoint
                    )


            let nextCoordinate =
                MapCoordinateConverter
                    .mapCoordinate(
                        for:
                            nextPoint
                    )


            let previousSeconds =
                previousCoordinate
                    .time
                    .secondsFromMidnight


            let nextSeconds =
                nextCoordinate
                    .time
                    .secondsFromMidnight


            /*
             Valid:
                next >= previous

             Invalid:
                next < previous

             except for tiny floating-point tolerance.
             */

            guard
                nextSeconds
                +
                policy
                    .backwardToleranceSeconds
                >=
                previousSeconds
            else {

                return RoadRouteTimeViolation(
                    previousTime:
                        previousCoordinate
                            .time,
                    nextTime:
                        nextCoordinate
                            .time,
                    previousWorldPoint:
                        previousPoint,
                    nextWorldPoint:
                        nextPoint
                )
            }
        }


        return nil
    }


    static func isForwardInTime(
        segment:
            RoadRouteSegment,
        graph:
            RoadGraph,
        policy:
            RouteTimePolicy = .dayMap
    ) -> Bool {

        validate(
            segment:
                segment,
            graph:
                graph,
            policy:
                policy
        )
        ==
        nil
    }
}

extension RoadRouteTimeValidator {

    static func validate(
        path:
            RoadRoutePath,
        graph:
            RoadGraph,
        policy:
            RouteTimePolicy = .dayMap
    ) -> RoadRouteTimeViolation? {

        for segment in
            path.segments {

            if let violation =
                validate(
                    segment:
                        segment,
                    graph:
                        graph,
                    policy:
                        policy
                )
            {

                return violation
            }
        }


        return nil
    }


    static func isForwardInTime(
        path:
            RoadRoutePath,
        graph:
            RoadGraph,
        policy:
            RouteTimePolicy = .dayMap
    ) -> Bool {

        validate(
            path:
                path,
            graph:
                graph,
            policy:
                policy
        )
        ==
        nil
    }
}

extension RoadRouteTimeValidator {

    static func debugDescription(
        for segment:
            RoadRouteSegment,
        graph:
            RoadGraph,
        policy:
            RouteTimePolicy = .dayMap
    ) -> String {

        guard let violation =
            validate(
                segment:
                    segment,
                graph:
                    graph,
                policy:
                    policy
            )
        else {

            return "Time-valid segment"
        }


        return """
        Backward-time road traversal:
        \(violation.previousTime.displayClockString)
        →
        \(violation.nextTime.displayClockString)
        Edge: \(segment.edgeID.rawValue)
        """
    }
}
