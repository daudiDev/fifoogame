//
//  RouteHitTester.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/22/26.
//


import Foundation
import CoreGraphics


struct RouteHitTester {

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
        at point: CGPoint,
        state: RouteRenderState,
        graph: RoadGraph,
        tolerance: CGFloat
    ) -> RouteInteractionTarget? {

        var candidates: [Candidate] = []


        // =================================================
        // Shared Completed -> Chosen curved state boundary
        // =================================================

        let boundaryTransition:
            RoutePathBuilder.BoundaryTransitionPaths?

        if let chosen = state.chosenFuture {

            boundaryTransition =
                RoutePathBuilder
                    .makeBoundaryTransitionPaths(
                        completedSegments:
                            state.completedSegments,
                        chosenSegments:
                            chosen.segments,
                        graph:
                            graph
                    )

        } else {

            boundaryTransition = nil
        }


        // =================================================
        // 1. Chosen Route — highest route priority
        // =================================================

        if let chosen = state.chosenFuture {

            let distance =
                visualDistance(
                    from: point,
                    segments: chosen.segments,
                    pathOverride:
                        boundaryTransition?
                            .chosenPath,
                    graph: graph
                )

            if
                let distance,
                distance <=
                    tolerance
                    + RouteVisualTheme
                        .chosenHaloWidth
                        / 2
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
        }


        // =================================================
        // 2. Alternatives
        // =================================================

        for (
            index,
            alternative
        ) in state.alternatives.enumerated() {

            guard let distance =
                visualDistance(
                    from: point,
                    segments:
                        alternative.segments,
                    pathOverride:
                        nil,
                    graph:
                        graph
                ),
                distance <=
                    tolerance
                    + RouteVisualTheme
                        .alternativeWidth
                        / 2
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
        // 3. Completed Route
        // =================================================

        let completedDistance =
            visualDistance(
                from: point,
                segments:
                    state.completedSegments,
                pathOverride:
                    boundaryTransition?
                        .completedPath,
                graph:
                    graph
            )

        if
            let completedDistance,
            completedDistance <=
                tolerance
                + RouteVisualTheme
                    .completedHaloWidth
                    / 2
        {
            candidates.append(
                Candidate(
                    target:
                        .completed,
                    distance:
                        completedDistance,
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
                        - rhs.distance
                    )

                // If centerlines are effectively the same, preserve the
                // visual interaction priority: Chosen > Alternate > Completed.
                if delta < 0.5 {
                    return lhs.priority < rhs.priority
                }

                return lhs.distance < rhs.distance
            }?
            .target
    }
}


private extension RouteHitTester {

    func visualDistance(
        from point: CGPoint,
        segments: [RoadRouteSegment],
        pathOverride: CGPath?,
        graph: RoadGraph
    ) -> CGFloat? {

        if let pathOverride {

            return RoutePathBuilder
                .minimumVisualDistance(
                    from: point,
                    to: pathOverride
                )
        }

        return RoutePathBuilder
            .minimumVisualDistance(
                from: point,
                to: segments,
                graph: graph
            )
    }
}
