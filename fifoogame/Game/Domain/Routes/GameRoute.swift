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


extension GameRoute {

    // =====================================================
    // MARK: - Planned Cost
    // =====================================================

    var plannedTotalCost:
        Double? {

        guard
            isFullyPlanned
        else {

            return nil
        }


        return legs.reduce(
            0
        ) { result, leg in

            result
            +
            (
                leg.path?
                    .totalCost
                ??
                0
            )
        }
    }
}

extension GameRoute {

    var orderedUniqueRoadEdgeIDs:
        [RoadEdgeID] {

        var seen =
            Set<RoadEdgeID>()


        var result:
            [RoadEdgeID] = []


        for leg in legs {

            guard let path =
                leg.path
            else {

                continue
            }


            for segment in
                path.segments {

                if
                    seen
                        .insert(
                            segment.edgeID
                        )
                        .inserted
                {

                    result.append(
                        segment.edgeID
                    )
                }
            }
        }


        return result
    }
}

extension GameRoute {

    var plannedPathSignature:
        String? {

        guard
            isFullyPlanned
        else {

            return nil
        }


        return legs
            .map { leg in

                let segmentSignature =
                    leg.path?
                        .segments
                        .map { segment in

                            let from =
                                Int(
                                    (
                                        segment
                                            .fromFraction
                                        *
                                        1_000_000
                                    )
                                    .rounded()
                                )


                            let to =
                                Int(
                                    (
                                        segment
                                            .toFraction
                                        *
                                        1_000_000
                                    )
                                    .rounded()
                                )


                            return """
                            \(segment.edgeID.rawValue):\(from)->\(to)
                            """
                        }
                        .joined(
                            separator:
                                ","
                        )
                    ??
                    ""


                return """
                \(leg.fromNodeID.rawValue.uuidString)->\(leg.toNodeID.rawValue.uuidString)[\(segmentSignature)]
                """
            }
            .joined(
                separator:
                    "||"
            )
    }
}

extension GameRoute {

    func withNewRouteID()
        -> GameRoute {

        GameRoute(
            id:
                RouteID(),
            stopNodeIDs:
                stopNodeIDs,
            legs:
                legs
        )
    }
}
