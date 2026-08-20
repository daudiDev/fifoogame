//
//  GameRouteProgressSnapshot.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/19/26.
//

import Foundation


struct GameRouteProgressSnapshot:
    Equatable,
    Sendable {

    let time:
        DayTime


    /// Portion of this particular planned route
    /// at-or-before the supplied time.
    ///
    /// This is NOT necessarily the app's historical
    /// completed route. It is only a snapshot of this
    /// GameRoute.
    let completedSegments:
        [RoadRouteSegment]


    /// Portion after the supplied time.
    let futureSegments:
        [RoadRouteSegment]


    let reachedNodeIDs:
        [GameNodeID]


    let futureNodeIDs:
        [GameNodeID]


    /// Position along the route at this time.
    let boundary:
        GameNodeRouteAnchor.RoadLocation?
}
