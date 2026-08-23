//
//  RoadRoutingOptions.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/22/26.
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
    /// Alternative-route generation uses this to discourage
    /// already-used streets while still allowing them when needed.
    var edgeCostMultipliers:
        [RoadEdgeID: Double]


    // =====================================================
    // MARK: - Step 5 Route Shape Costs
    // =====================================================

    /// Extra cost whenever the route changes direction.
    ///
    /// The standard value is expressed in world points and is a
    /// fraction of one Cartesian street pitch. This makes a route
    /// with long straight runs cheaper than a zig-zag route of the
    /// same geometric distance.
    var turnPenalty:
        Double


    /// Extra cost when the route changes its horizontal tendency
    /// after progressing downward to a later row.
    ///
    /// Example:
    ///
    ///     RIGHT -> DOWN -> LEFT
    ///
    /// is legal, but it is intentionally less desirable than a
    /// route that continues using the same horizontal direction.
    var horizontalDirectionChangePenalty:
        Double


    /// A direct RIGHT -> LEFT or LEFT -> RIGHT reversal at the same
    /// intersection has no useful routing value and is rejected.
    var rejectsImmediateHorizontalReversal:
        Bool


    // =====================================================
    // MARK: - Init
    // =====================================================

    init(
        excludedEdgeIDs:
            Set<RoadEdgeID> = [],
        edgeCostMultipliers:
            [RoadEdgeID: Double] = [:],
        turnPenalty:
            Double = Double(
                GridMapConfiguration
                    .cellPitchWorld
            ) * 0.35,
        horizontalDirectionChangePenalty:
            Double = Double(
                GridMapConfiguration
                    .cellPitchWorld
            ) * 1.25,
        rejectsImmediateHorizontalReversal:
            Bool = true
    ) {

        self.excludedEdgeIDs =
            excludedEdgeIDs

        self.edgeCostMultipliers =
            edgeCostMultipliers

        self.turnPenalty =
            max(
                turnPenalty,
                0
            )

        self.horizontalDirectionChangePenalty =
            max(
                horizontalDirectionChangePenalty,
                0
            )

        self.rejectsImmediateHorizontalReversal =
            rejectsImmediateHorizontalReversal
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
