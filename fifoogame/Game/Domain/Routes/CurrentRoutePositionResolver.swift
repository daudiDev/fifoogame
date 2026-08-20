//
//  CurrentRoutePositionResolver.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/19/26.
//

import Foundation


enum CurrentRoutePositionResolver {

    static func resolve(
        completedRoute:
            CompletedRoute,
        currentTime:
            DayTime,
        graph:
            RoadGraph
    ) -> RoadRouteAnchor? {

        guard let boundary =
            completedRoute.boundary
        else {

            return nil
        }


        guard let geometricCoordinate =
            mapCoordinate(
                for:
                    boundary,
                graph:
                    graph
            )
        else {

            return nil
        }


        /*
         Progress comes from the actual road boundary.

         Time comes from GameStore/current game time,
         not from resampling geometry.
        */

        let coordinate =
            MapCoordinate(
                time:
                    currentTime,
                progress:
                    geometricCoordinate.progress
            )


        return RoadRouteAnchor(
            coordinate:
                coordinate,
            roadLocation:
                boundary
        )
    }
}


private extension CurrentRoutePositionResolver {

    static func mapCoordinate(
        for location:
            GameNodeRouteAnchor.RoadLocation,
        graph:
            RoadGraph
    ) -> MapCoordinate? {

        switch location {

        case let .vertex(
            vertexID
        ):

            guard let vertex =
                graph.vertex(
                    id:
                        vertexID
                )
            else {

                return nil
            }


            return vertex.coordinate


        case let .edge(
            edgeID,
            fraction
        ):

            guard
                let edge =
                    graph.edge(
                        id:
                            edgeID
                    ),

                let point =
                    RoadEdgeGeometry.point(
                        atFraction:
                            fraction,
                        on:
                            edge,
                        graph:
                            graph,
                        cubicSegments:
                            96
                    )
            else {

                return nil
            }


            return MapCoordinateConverter
                .mapCoordinate(
                    for:
                        point
                )
        }
    }
}
