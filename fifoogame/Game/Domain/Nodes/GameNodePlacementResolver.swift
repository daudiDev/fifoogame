//
//  GameNodePlacementResolver.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/19/26.
//

import Foundation


enum GameNodePlacementResolver {

    static func mapCoordinate(
        for node:
            GameMapNode,
        graph:
            RoadGraph
    ) -> MapCoordinate? {

        mapCoordinate(
            for:
                node.placement,
            graph:
                graph
        )
    }


    static func mapCoordinate(
        for placement:
            GameNodePlacement,
        graph:
            RoadGraph
    ) -> MapCoordinate? {

        switch placement {

        case let .coordinate(
            coordinate
        ):

            return coordinate


        case let .roadVertex(
            vertexID
        ):

            return graph
                .vertex(
                    id:
                        vertexID
                )?
                .coordinate
        }
    }


    static func worldPoint(
        for node:
            GameMapNode,
        graph:
            RoadGraph
    ) -> WorldPoint? {

        guard let coordinate =
            mapCoordinate(
                for:
                    node,
                graph:
                    graph
            )
        else {

            return nil
        }


        return MapCoordinateConverter
            .worldPoint(
                for:
                    coordinate
            )
    }
}
