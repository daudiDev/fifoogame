//
//  RouteHitTester.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/19/26.
//

import Foundation
import CoreGraphics


struct RouteHitTester {

    // =====================================================
    // MARK: - Hit
    // =====================================================

    private struct Candidate {

        let target:
            RouteInteractionTarget

        let distance:
            CGFloat

        let priority:
            Int
    }


    // =====================================================
    // MARK: - Public
    // =====================================================

    func hitTest(
        at point:
            CGPoint,
        state:
            RouteRenderState,
        graph:
            RoadGraph,
        tolerance:
            CGFloat
    ) -> RouteInteractionTarget? {

        var candidates:
            [Candidate] = []


        // =================================================
        // Chosen Route
        //
        // Highest route priority.
        // =================================================

        if let chosen =
            state.chosenFuture,
           let distance =
            minimumDistance(
                from:
                    point,
                to:
                    chosen.segments,
                graph:
                    graph
            ),
           distance <=
            tolerance
        {

            candidates.append(
                Candidate(
                    target:
                        .chosen(
                            routeID:
                                chosen.routeID
                        ),
                    distance:
                        distance,
                    priority:
                        0
                )
            )
        }


        // =================================================
        // Alternatives
        // =================================================

        for (
            index,
            alternative
        ) in state.alternatives.enumerated() {

            guard let distance =
                minimumDistance(
                    from:
                        point,
                    to:
                        alternative.segments,
                    graph:
                        graph
                ),
                  distance <=
                    tolerance
            else {

                continue
            }


            candidates.append(
                Candidate(
                    target:
                        .alternative(
                            routeID:
                                alternative.routeID
                        ),
                    distance:
                        distance,
                    priority:
                        10 + index
                )
            )
        }


        // =================================================
        // Completed Route
        // =================================================

        if let distance =
            minimumDistance(
                from:
                    point,
                to:
                    state.completedSegments,
                graph:
                    graph
            ),
           distance <=
            tolerance
        {

            candidates.append(
                Candidate(
                    target:
                        .completed,
                    distance:
                        distance,
                    priority:
                        100
                )
            )
        }


        // =================================================
        // Pick Closest
        // =================================================

        return candidates
            .min { lhs, rhs in

                let delta =
                    abs(
                        lhs.distance
                        -
                        rhs.distance
                    )


                /*
                 If two routes occupy effectively the
                 same line, visual priority wins.

                 Chosen > Alternative > Completed
                 */

                if delta <
                    0.5
                {

                    return lhs.priority <
                        rhs.priority
                }


                return lhs.distance <
                    rhs.distance
            }?
            .target
    }
}

private extension RouteHitTester {

    func minimumDistance(
        from point:
            CGPoint,
        to segments:
            [RoadRouteSegment],
        graph:
            RoadGraph
    ) -> CGFloat? {

        guard
            !segments.isEmpty
        else {

            return nil
        }


        var bestDistance =
            CGFloat.greatestFiniteMagnitude


        for segment in
            segments {

            let points =
                RoadEdgeGeometry
                    .sampledPoints(
                        along:
                            segment,
                        graph:
                            graph,
                        cubicSegments:
                            72
                    )


            guard
                points.count >= 2
            else {

                continue
            }


            for (
                first,
                second
            ) in zip(
                points,
                points.dropFirst()
            ) {

                let distance =
                    distance(
                        from:
                            point,
                        toSegmentFrom:
                            first.cgPoint,
                        to:
                            second.cgPoint
                    )


                bestDistance =
                    min(
                        bestDistance,
                        distance
                    )
            }
        }


        guard
            bestDistance !=
                .greatestFiniteMagnitude
        else {

            return nil
        }


        return bestDistance
    }
}

private extension RouteHitTester {

    func distance(
        from point:
            CGPoint,
        toSegmentFrom start:
            CGPoint,
        to end:
            CGPoint
    ) -> CGFloat {

        let dx =
            end.x -
            start.x


        let dy =
            end.y -
            start.y


        let lengthSquared =
            dx * dx
            +
            dy * dy


        guard
            lengthSquared >
                0.000_001
        else {

            return hypot(
                point.x -
                start.x,
                point.y -
                start.y
            )
        }


        let rawT =
            (
                (
                    point.x -
                    start.x
                )
                *
                dx

                +

                (
                    point.y -
                    start.y
                )
                *
                dy
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


        let projection =
            CGPoint(
                x:
                    start.x
                    +
                    dx * t,
                y:
                    start.y
                    +
                    dy * t
            )


        return hypot(
            point.x -
            projection.x,
            point.y -
            projection.y
        )
    }
}
