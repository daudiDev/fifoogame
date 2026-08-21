//
//  DayProgressState.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/21/26.
//


import Foundation


struct DayProgressState:
    Codable,
    Equatable,
    Sendable {

    var startingProgress:
        MapProgress

    var currentProgress:
        MapProgress

    var entries:
        [ProgressLedgerEntry]

    var nodeOutcomes:
        [GameNodeID: AppliedNodeProgressOutcome]


    init(
        startingProgress:
            MapProgress = MapProgress(0)
    ) {

        self.startingProgress =
            startingProgress

        self.currentProgress =
            startingProgress

        self.entries =
            []

        self.nodeOutcomes =
            [:]
    }
}


// =====================================================
// MARK: - Convenience
// =====================================================

extension DayProgressState {

    var totalChange:
        Double {

        currentProgress.percent
        -
        startingProgress.percent
    }


    var hasChanges:
        Bool {

        !entries.isEmpty
    }
}