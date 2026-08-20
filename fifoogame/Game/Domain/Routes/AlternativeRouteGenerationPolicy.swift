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


    static let standard =
        AlternativeRouteGenerationPolicy()
}
