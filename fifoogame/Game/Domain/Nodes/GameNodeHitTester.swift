//
//  GameNodeHitTester.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/25/26.
//



import Foundation
import CoreGraphics


struct GameNodeHitTester {

    /// Mirrors the rendered live-location callout footprint. The GameMapNode
    /// coordinate is the sharp pointer tip at (0, 0); the white capsule,
    /// circular avatar, and title/time float above it.
    private enum HitMetrics {

        static let minimumX: CGFloat = -26
        static let maximumX: CGFloat = 192
        static let minimumY: CGFloat = -8
        static let maximumY: CGFloat = 78
    }

    func hitTest(
        at point: CGPoint,
        nodes: [GameMapNode],
        roadGraph: RoadGraph,
        tolerance: CGFloat
    ) -> GameNodeID? {

        var bestNode:
            GameNodeID?

        var bestX =
            -CGFloat.greatestFiniteMagnitude

        var bestDistance =
            CGFloat.greatestFiniteMagnitude

        for node in nodes {

            guard
                node.isEnabled,
                let worldPoint =
                    GameNodePlacementResolver
                        .worldPoint(
                            for: node,
                            graph: roadGraph
                        )
            else {
                continue
            }

            let location =
                worldPoint.cgPoint

            let localPoint =
                CGPoint(
                    x: point.x - location.x,
                    y: point.y - location.y
                )

            let hitRect =
                CGRect(
                    x: HitMetrics.minimumX - tolerance,
                    y: HitMetrics.minimumY - tolerance,
                    width:
                        (HitMetrics.maximumX - HitMetrics.minimumX)
                        + (tolerance * 2),
                    height:
                        (HitMetrics.maximumY - HitMetrics.minimumY)
                        + (tolerance * 2)
                )

            guard
                hitRect.contains(
                    localPoint
                )
            else {
                continue
            }

            // Rendering deliberately stacks rightward nodes above leftward
            // nodes. Hit testing mirrors that rule so the node the user sees
            // on top is also the node that receives the tap. Distance is only
            // used as a tie-breaker when semantic X coordinates are equal.
            let distance =
                hypot(
                    point.x - location.x,
                    point.y - location.y
                )

            if location.x > bestX
                || (location.x == bestX && distance < bestDistance)
            {
                bestX =
                    location.x

                bestDistance =
                    distance

                bestNode =
                    node.id
            }
        }

        return bestNode
    }
}
