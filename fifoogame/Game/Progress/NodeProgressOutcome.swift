//
//  NodeProgressOutcome.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/21/26.
//


import Foundation


// =====================================================
// MARK: - Node Outcome
// =====================================================

enum NodeProgressOutcome:
    String,
    Codable,
    Equatable,
    Sendable {

    case completed
    case skipped
    case missed
}


// =====================================================
// MARK: - Scoring Rule
// =====================================================

struct ProgressScoringRule:
    Codable,
    Equatable,
    Sendable {

    var completedDelta:
        Double

    var skippedDelta:
        Double

    var missedDelta:
        Double


    init(
        completedDelta: Double = 0,
        skippedDelta: Double = 0,
        missedDelta: Double = 0
    ) {

        self.completedDelta =
            completedDelta

        self.skippedDelta =
            skippedDelta

        self.missedDelta =
            missedDelta
    }


    func delta(
        for outcome:
            NodeProgressOutcome
    ) -> Double {

        switch outcome {

        case .completed:
            return completedDelta

        case .skipped:
            return skippedDelta

        case .missed:
            return missedDelta
        }
    }
}


// =====================================================
// MARK: - Change Reason
// =====================================================

enum ProgressChangeReason:
    String,
    Codable,
    Equatable,
    Sendable {

    case nodeCompleted
    case nodeSkipped
    case nodeMissed

    case nodeOutcomeCorrection

    case bonus
    case penalty
    case manualAdjustment
}


// =====================================================
// MARK: - Ledger Entry
// =====================================================

struct ProgressLedgerEntry:
    Identifiable,
    Codable,
    Equatable,
    Sendable {

    let id:
        UUID

    let occurredAt:
        DayTime

    let delta:
        Double

    let progressBefore:
        MapProgress

    let progressAfter:
        MapProgress

    let reason:
        ProgressChangeReason

    let nodeID:
        GameNodeID?

    let note:
        String?


    init(
        id: UUID = UUID(),
        occurredAt: DayTime,
        delta: Double,
        progressBefore: MapProgress,
        progressAfter: MapProgress,
        reason: ProgressChangeReason,
        nodeID: GameNodeID? = nil,
        note: String? = nil
    ) {

        self.id =
            id

        self.occurredAt =
            occurredAt

        self.delta =
            delta

        self.progressBefore =
            progressBefore

        self.progressAfter =
            progressAfter

        self.reason =
            reason

        self.nodeID =
            nodeID

        self.note =
            note
    }
}


// =====================================================
// MARK: - Applied Node Outcome
// =====================================================

struct AppliedNodeProgressOutcome:
    Codable,
    Equatable,
    Sendable {

    let outcome:
        NodeProgressOutcome

    let appliedDelta:
        Double

    let occurredAt:
        DayTime
}