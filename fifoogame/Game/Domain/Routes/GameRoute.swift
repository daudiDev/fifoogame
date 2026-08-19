//
//  GameRoute.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/19/26.
//

import Foundation


struct GameRoute:
    Codable,
    Equatable,
    Hashable,
    Sendable,
    Identifiable {

    let id:
        RouteID


    /// Ordered gameplay nodes that define the route.
    ///
    /// The order is significant.
    var stopNodeIDs:
        [GameNodeID]


    /// Consecutive road-routing legs.
    ///
    /// For:
    ///
    /// A → B → C
    ///
    /// there should be:
    ///
    /// A→B
    /// B→C
    var legs:
        [GameRouteLeg]


    init(
        id: RouteID = RouteID(),
        stopNodeIDs: [GameNodeID] = [],
        legs: [GameRouteLeg] = []
    ) {

        self.id =
            id

        self.stopNodeIDs =
            stopNodeIDs

        self.legs =
            legs
    }
}

extension GameRoute {

    // =====================================================
    // MARK: - State
    // =====================================================

    var isEmpty:
        Bool {

        stopNodeIDs.isEmpty
    }


    var stopCount:
        Int {

        stopNodeIDs.count
    }


    var expectedLegCount:
        Int {

        max(
            stopNodeIDs.count - 1,
            0
        )
    }


    var isFullyPlanned:
        Bool {

        guard
            legs.count ==
                expectedLegCount
        else {

            return false
        }


        return legs.allSatisfy {

            $0.path != nil
        }
    }


    var roadEdgeIDs:
        [RoadEdgeID] {

        legs.flatMap {

            $0.path?
                .edgeIDs
            ??
            []
        }
    }
}

extension GameRoute {

    static func unplanned(
        stopNodeIDs:
            [GameNodeID]
    ) -> GameRoute {

        let legs =
            zip(
                stopNodeIDs,
                stopNodeIDs.dropFirst()
            )
            .map { from, to in

                GameRouteLeg(
                    fromNodeID:
                        from,
                    toNodeID:
                        to
                )
            }


        return GameRoute(
            stopNodeIDs:
                stopNodeIDs,
            legs:
                legs
        )
    }
}
