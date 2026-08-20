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

    var stopNodeIDs:
        [GameNodeID]

    var entryLeg:
        GameRouteEntryLeg?

    var legs:
        [GameRouteLeg]

    init(
        id: RouteID = RouteID(),
        stopNodeIDs: [GameNodeID] = [],
        entryLeg: GameRouteEntryLeg? = nil,
        legs: [GameRouteLeg] = []
    ) {

        self.id =
            id

        self.stopNodeIDs =
            stopNodeIDs

        self.entryLeg =
            entryLeg

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


        guard
            legs.allSatisfy({
                $0.path != nil
            })
        else {

            return false
        }


        if let entryLeg {

            guard
                entryLeg.path != nil
            else {

                return false
            }
        }


        return true
    }
    
    var allRoadSegments:
        [RoadRouteSegment] {

        var result:
            [RoadRouteSegment] = []


        if let entrySegments =
            entryLeg?
                .path?
                .segments
        {

            result.append(
                contentsOf:
                    entrySegments
            )
        }


        for leg in
            legs {

            guard let path =
                leg.path
            else {

                continue
            }


            result.append(
                contentsOf:
                    path.segments
            )
        }


        return result
    }
    
    var roadEdgeIDs:
        [RoadEdgeID] {

        allRoadSegments.map(
            \.edgeID
        )
    }

}

extension GameRoute {

    static func unplanned(
        stopNodeIDs: [GameNodeID]
    ) -> GameRoute {

        let legs =
            zip(
                stopNodeIDs,
                stopNodeIDs.dropFirst()
            )
            .map {

                GameRouteLeg(
                    fromNodeID:
                        $0.0,
                    toNodeID:
                        $0.1
                )
            }

        return GameRoute(
            stopNodeIDs:
                stopNodeIDs,
            entryLeg:
                nil,
            legs:
                legs
        )
    }
    
    static func unplanned(
        startingAt startAnchor:
            RoadRouteAnchor,
        stopNodeIDs:
            [GameNodeID]
    ) -> GameRoute {

        guard let firstStopID =
            stopNodeIDs.first
        else {

            return GameRoute()
        }


        let entryLeg =
            GameRouteEntryLeg(
                startAnchor:
                    startAnchor,
                toNodeID:
                    firstStopID
            )


        let legs =
            zip(
                stopNodeIDs,
                stopNodeIDs.dropFirst()
            )
            .map {

                GameRouteLeg(
                    fromNodeID:
                        $0.0,
                    toNodeID:
                        $0.1
                )
            }


        return GameRoute(
            stopNodeIDs:
                stopNodeIDs,
            entryLeg:
                entryLeg,
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


        var total =
            0.0


        if let entryCost =
            entryLeg?
                .path?
                .totalCost
        {

            total +=
                entryCost
        }


        for leg in
            legs {

            total +=
                leg.path?
                    .totalCost
                ??
                0
        }


        return total
    }
}

extension GameRoute {

    var orderedUniqueRoadEdgeIDs:
        [RoadEdgeID] {

        var seen =
            Set<RoadEdgeID>()


        var result:
            [RoadEdgeID] = []


        for segment in
            allRoadSegments {

            if
                seen.insert(
                    segment.edgeID
                )
                .inserted
            {

                result.append(
                    segment.edgeID
                )
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


        let segmentSignature =
            allRoadSegments
                .map { segment in

                    let from =
                        Int(
                            (
                                segment.fromFraction
                                *
                                1_000_000
                            )
                            .rounded()
                        )


                    let to =
                        Int(
                            (
                                segment.toFraction
                                *
                                1_000_000
                            )
                            .rounded()
                        )


                    return
                        "\(segment.edgeID.rawValue):\(from)->\(to)"
                }
                .joined(
                    separator:
                        ","
                )


        let stopSignature =
            stopNodeIDs
                .map {
                    $0.rawValue.uuidString
                }
                .joined(
                    separator:
                        ">"
                )


        return
            "\(stopSignature)[\(segmentSignature)]"
    }
}

extension GameRoute {

    func withNewRouteID() -> GameRoute {

        GameRoute(
            id:
                RouteID(),
            stopNodeIDs:
                stopNodeIDs,
            entryLeg:
                entryLeg,
            legs:
                legs
        )
    }
    
}

extension GameRoute {

    /// Creates an unplanned route with the same gameplay stops
    /// and the same route-start semantics as this route.
    ///
    /// If this route begins from the player's current road
    /// position, that exact RoadRouteAnchor is preserved.
    func unplannedPreservingStart() -> GameRoute {

        if let entryLeg {

            return GameRoute.unplanned(
                startingAt:
                    entryLeg.startAnchor,
                stopNodeIDs:
                    stopNodeIDs
            )
        }


        return GameRoute.unplanned(
            stopNodeIDs:
                stopNodeIDs
        )
    }
}
