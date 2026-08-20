//
//  RoadRouteSegment.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/19/26.
//

import Foundation


struct RoadRouteSegment:
    Codable,
    Equatable,
    Hashable,
    Sendable {

    let edgeID:
        RoadEdgeID


    /// Fraction along the canonical edge geometry.
    ///
    /// 0 = fromID
    /// 1 = toID
    let fromFraction:
        Double


    let toFraction:
        Double


    var isForward:
        Bool {

        toFraction >=
            fromFraction
    }


    var traversedFraction:
        Double {

        abs(
            toFraction
            -
            fromFraction
        )
    }
}
