//
//  ProgressOutcomeFailure.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/21/26.
//


import Foundation


enum ProgressOutcomeFailure:
    Equatable,
    Sendable {

    case nodeNotFound
    case nodeDisabled
    case scoringRuleUnavailable
    case invalidTimestamp
}


enum ProgressOutcomeApplyResult:
    Equatable,
    Sendable {

    case applied(
        ProgressLedgerEntry
    )

    case corrected(
        ProgressLedgerEntry
    )

    case unchanged

    case failed(
        ProgressOutcomeFailure
    )


    var succeeded:
        Bool {

        switch self {

        case .applied,
             .corrected,
             .unchanged:

            return true

        case .failed:

            return false
        }
    }
}