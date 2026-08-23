//
//  AlternativeRouteGenerationPolicy.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/19/26.
//


import Foundation


struct AlternativeRouteGenerationPolicy:
    Equatable,
    Sendable {

    /// Maximum alternatives returned to the app.
    var maxAlternatives:
        Int


    /// Strongly discourage roads from already-discovered
    /// routes while still allowing them if unavoidable.
    var penaltyMultiplier:
        Double


    /// Prevent combinatorial explosion.
    var maxPlanningAttempts:
        Int


    /// Don't offer a route dramatically worse than
    /// the selected shortest route.
    var maximumCostRatio:
        Double


    init(
        maxAlternatives:
            Int = 3,

        penaltyMultiplier:
            Double = 8,

        maxPlanningAttempts:
            Int = 40,

        maximumCostRatio:
            Double = 2.5
    ) {

        self.maxAlternatives =
            max(
                maxAlternatives,
                0
            )


        self.penaltyMultiplier =
            max(
                penaltyMultiplier,
                1
            )


        self.maxPlanningAttempts =
            max(
                maxPlanningAttempts,
                1
            )


        self.maximumCostRatio =
            max(
                maximumCostRatio,
                1
            )
    }


    // =====================================================
    // MARK: - Standard
    //
    // More exhaustive policy. Useful where responsiveness
    // is less important than finding additional options.
    // =====================================================

    static let standard =
        AlternativeRouteGenerationPolicy(
            maxAlternatives:
                3,

            penaltyMultiplier:
                8,

            maxPlanningAttempts:
                40,

            maximumCostRatio:
                2.5
        )


    // =====================================================
    // MARK: - Interactive Preview
    //
    // Intended for route generation while the user is
    // actively using the day map.
    //
    // We only search for the number of alternatives the
    // UI actually intends to show.
    // =====================================================

    static func interactivePreview(
        maxAlternatives:
            Int
    ) -> AlternativeRouteGenerationPolicy {

        AlternativeRouteGenerationPolicy(

            maxAlternatives:
                maxAlternatives,

            penaltyMultiplier:
                8,

            // 40 is unnecessarily expensive for an
            // interactive operation.
            //
            // For 2 alternatives, 10–12 attempts gives
            // plenty of opportunity on this graph without
            // letting the search explode.
            maxPlanningAttempts:
                12,

            maximumCostRatio:
                2.5
        )
    }
}
