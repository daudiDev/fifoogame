//
//  GameNodeHitTester.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/19/26.
//


import Foundation
import CoreGraphics


struct GameNodeHitTester {

    func hitTest(
        at point:
            CGPoint,
        nodes:
            [GameMapNode],
        roadGraph:
            RoadGraph,
        tolerance:
            CGFloat
    ) -> GameNodeID? {

        var bestNode:
            GameNodeID?


        var bestDistance =
            CGFloat.greatestFiniteMagnitude


        for node in nodes {

            guard
                node.isEnabled,

                let worldPoint =
                    GameNodePlacementResolver
                        .worldPoint(
                            for:
                                node,
                            graph:
                                roadGraph
                        )
            else {

                continue
            }


            let location =
                worldPoint.cgPoint


            let distance =
                hypot(
                    point.x
                    -
                    location.x,

                    point.y
                    -
                    location.y
                )


            let threshold =
                tolerance + 20


            guard
                distance <= threshold
            else {

                continue
            }


            if distance <
                bestDistance {

                bestDistance =
                    distance

                bestNode =
                    node.id
            }
        }


        return bestNode
    }
}
