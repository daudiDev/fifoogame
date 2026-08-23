//
//  RouteTimePolicy.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/22/26.
//


import Foundation


// =====================================================
// MARK: - Route Time Policy
// =====================================================

struct RouteTimePolicy:
    Equatable,
    Sendable {

    // =================================================
    // MARK: Backward-Time Tolerance
    // =================================================

    /// Maximum amount of backward-time geometry accepted by the
    /// defensive route-time validator.
    ///
    /// The old irregular city map needed a sizeable tolerance because
    /// vertices on the same visual street row could have slightly
    /// different times. The new Cartesian grid does not have that
    /// problem: every horizontal street is mathematically time-flat.
    ///
    /// Step 5 therefore uses ZERO tolerance for the normal Day Map.
    let backwardToleranceSeconds:
        TimeInterval


    // =================================================
    // MARK: Curved Geometry Samples
    // =================================================

    /// Retained for compatibility with generic road-geometry utilities.
    /// The active Cartesian roads are straight, but later route rendering
    /// can still use curved visual corners without changing road topology.
    let cubicGeometrySamples:
        Int


    // =================================================
    // MARK: Init
    // =================================================

    init(
        backwardToleranceSeconds:
            TimeInterval = 0,
        cubicGeometrySamples:
            Int = 64
    ) {

        self.backwardToleranceSeconds =
            max(
                0,
                backwardToleranceSeconds
            )


        self.cubicGeometrySamples =
            max(
                cubicGeometrySamples,
                8
            )
    }


    // =================================================
    // MARK: Day Map
    // =================================================

    /// The redesigned Fifoo map never permits upward route travel.
    static let dayMap =
        RouteTimePolicy(
            backwardToleranceSeconds:
                0,
            cubicGeometrySamples:
                64
        )


    // =================================================
    // MARK: Strict
    // =================================================

    static let strict =
        RouteTimePolicy(
            backwardToleranceSeconds:
                0,
            cubicGeometrySamples:
                64
        )


    // =================================================
    // MARK: Geometry-Only Diagnostic Policy
    // =================================================

    static let zeroTolerance =
        RouteTimePolicy(
            backwardToleranceSeconds:
                0,
            cubicGeometrySamples:
                64
        )
}
