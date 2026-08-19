//
//  GameNodeRoadRelationshipResolver.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/19/26.
//


import Foundation
import CoreGraphics

struct GameNodeRoadRelationshipResolver {

    var additionalRoadTolerance:
        CGFloat = 0

    private let roadHitTester =
        RoadHitTester()


    // =====================================================
    // MARK: - Resolve
    // =====================================================

    func resolve(
        node:
            GameMapNode,
        graph:
            RoadGraph
    ) -> GameNodeRoadRelationship {

        guard let worldPoint =
            GameNodePlacementResolver
                .worldPoint(
                    for:
                        node,
                    graph:
                        graph
                )
        else {

            return .offRoad
        }


        return resolve(
            worldPoint:
                worldPoint,
            graph:
                graph
        )
    }


    func resolve(
        worldPoint:
            WorldPoint,
        graph:
            RoadGraph
    ) -> GameNodeRoadRelationship {

        let point =
            worldPoint.cgPoint


        /*
         IMPORTANT:

         We pass zero additional hit tolerance.

         RoadHitTester itself already accounts for
         actual road/intersection geometry and road
         half-width.

         This means we are asking:

         "Does this point actually lie on the road?"

         NOT:

         "What road is closest to this point?"
         */
        
        let hit =
            roadHitTester.hitTest(
                at:
                    point,
                graph:
                    graph,
                tolerance:
                    additionalRoadTolerance
            )


        switch hit {

        case let .vertex(
            vertexID
        ):

            return .vertex(
                vertexID:
                    vertexID
            )


        case let .edge(
            edgeID
        ):

            return .edge(
                edgeID:
                    edgeID
            )


        case nil:

            return .offRoad
        }
    }
}
