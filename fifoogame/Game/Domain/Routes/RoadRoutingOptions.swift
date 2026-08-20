//
//  RoadRoutingOptions.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/19/26.
//


import Foundation


struct RoadRoutingOptions:
    Equatable,
    Sendable {

    // =====================================================
    // MARK: - Edge Restrictions
    // =====================================================

    /// Completely prevent these edges from being used.
    var excludedEdgeIDs:
        Set<RoadEdgeID>


    /// Additional cost multiplier for selected edges.
    ///
    /// Example:
    ///
    /// edge A = normal cost * 8
    ///
    /// Dijkstra may still use it if necessary, but will
    /// strongly prefer another valid road.
    var edgeCostMultipliers:
        [RoadEdgeID: Double]


    // =====================================================
    // MARK: - Init
    // =====================================================

    init(
        excludedEdgeIDs:
            Set<RoadEdgeID> = [],
        edgeCostMultipliers:
            [RoadEdgeID: Double] = [:]
    ) {

        self.excludedEdgeIDs =
            excludedEdgeIDs

        self.edgeCostMultipliers =
            edgeCostMultipliers
    }


    static let standard =
        RoadRoutingOptions()
}

extension RoadRoutingOptions {

    func costMultiplier(
        for edgeID:
            RoadEdgeID
    ) -> Double {

        max(
            edgeCostMultipliers[
                edgeID
            ]
            ??
            1,
            0.000_001
        )
    }


    func isExcluded(
        _ edgeID:
            RoadEdgeID
    ) -> Bool {

        excludedEdgeIDs.contains(
            edgeID
        )
    }


    func applyingPenalty(
        to edgeIDs:
            Set<RoadEdgeID>,
        multiplier:
            Double
    ) -> RoadRoutingOptions {

        var updated =
            self


        let safeMultiplier =
            max(
                multiplier,
                1
            )


        for edgeID in
            edgeIDs {

            let existing =
                updated
                    .edgeCostMultipliers[
                        edgeID
                    ]
                ??
                1


            updated
                .edgeCostMultipliers[
                    edgeID
                ] =
                    existing
                    *
                    safeMultiplier
        }


        return updated
    }
}
