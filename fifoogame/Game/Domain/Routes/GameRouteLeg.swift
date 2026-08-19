//
//  GameRouteLeg.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/19/26.
//

import Foundation


struct GameRouteLeg:
    Codable,
    Equatable,
    Hashable,
    Sendable,
    Identifiable {

    let fromNodeID:
        GameNodeID


    let toNodeID:
        GameNodeID


    /// nil means:
    ///
    /// The leg exists semantically but pathfinding
    /// has not yet produced its road path.
    var path:
        RoadRoutePath?


    var id:
        String {

        "\(fromNodeID.rawValue.uuidString)->\(toNodeID.rawValue.uuidString)"
    }


    init(
        fromNodeID: GameNodeID,
        toNodeID: GameNodeID,
        path: RoadRoutePath? = nil
    ) {

        self.fromNodeID =
            fromNodeID

        self.toNodeID =
            toNodeID

        self.path =
            path
    }
}
