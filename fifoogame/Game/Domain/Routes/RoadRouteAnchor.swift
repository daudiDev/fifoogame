//
//  RoadRouteAnchor.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/19/26.
//


import Foundation


struct RoadRouteAnchor:
    Codable,
    Equatable,
    Hashable,
    Sendable {

    let coordinate:
        MapCoordinate

    let roadLocation:
        GameNodeRouteAnchor.RoadLocation


    init(
        coordinate: MapCoordinate,
        roadLocation: GameNodeRouteAnchor.RoadLocation
    ) {

        self.coordinate =
            coordinate

        self.roadLocation =
            roadLocation
    }
}


