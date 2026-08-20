//
//  RouteTimePolicy.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/19/26.
//


import Foundation


struct RouteTimePolicy:
    Equatable,
    Sendable {

    /// Small numerical tolerance.
    ///
    /// This should only compensate for floating-point
    /// and geometry sampling error. It is NOT permission
    /// to actually travel backward through the day.
    let backwardToleranceSeconds:
        TimeInterval


    /// Number of samples used for curved road geometry.
    let cubicGeometrySamples:
        Int


    init(
        backwardToleranceSeconds: TimeInterval = 1,
        cubicGeometrySamples: Int = 64
    ) {

        self.backwardToleranceSeconds =
            backwardToleranceSeconds

        self.cubicGeometrySamples =
            max(
                cubicGeometrySamples,
                8
            )
    }


    static let dayMap =
        RouteTimePolicy(
            backwardToleranceSeconds:
                1,
            cubicGeometrySamples:
                64
        )
}
