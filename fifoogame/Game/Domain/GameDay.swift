//
//  GameDay.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/18/26.
//

import Foundation


struct GameDay: Identifiable, Codable, Equatable, Sendable {

    let id: GameDayID

    /// Beginning of the local calendar day.
    let localDate: Date

    /// Example:
    /// "America/New_York"
    let timeZoneID: String

    /// Incremented whenever authoritative game state changes.
    private(set) var revision: Int


    init(
        id: GameDayID = GameDayID(),
        localDate: Date,
        timeZoneID: String,
        revision: Int = 0
    ) {

        self.id = id
        self.localDate = localDate
        self.timeZoneID = timeZoneID
        self.revision = revision
    }


    mutating func incrementRevision() {
        revision += 1
    }
}


// MARK: - Factory

extension GameDay {

    static func today(
        now: Date = .now,
        timeZone: TimeZone = .autoupdatingCurrent
    ) -> GameDay {

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone

        let startOfDay =
            calendar.startOfDay(for: now)

        return GameDay(
            localDate: startOfDay,
            timeZoneID: timeZone.identifier
        )
    }
}


