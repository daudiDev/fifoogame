//
//  FutureRouteCommitResult.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/20/26.
//


import Foundation


enum FutureRouteCommitFailure:
    Equatable,
    Sendable {

    case noPreview

    case selectedRouteUnavailable

    case selectedRouteNotPlanned

    case sourceRouteChanged

    case timeMovedBackward

    case currentPositionChanged
}


struct FutureRouteCommitResult:
    Equatable,
    Sendable {

    let failure:
        FutureRouteCommitFailure?


    var succeeded:
        Bool {

        failure == nil
    }


    static let success =
        FutureRouteCommitResult(
            failure:
                nil
        )


    static func failure(
        _ reason:
            FutureRouteCommitFailure
    ) -> FutureRouteCommitResult {

        FutureRouteCommitResult(
            failure:
                reason
        )
    }
}
