//
//  CalendarDayKey.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/20/26.
//


import Foundation

struct CalendarDayKey:
    Codable,
    Equatable,
    Hashable,
    Sendable {

    let year: Int
    let month: Int
    let day: Int

    init(
        date: Date,
        timeZone: TimeZone
    ) {

        var calendar =
            Calendar(identifier: .gregorian)

        calendar.timeZone =
            timeZone

        let components =
            calendar.dateComponents(
                [.year, .month, .day],
                from: date
            )

        year =
            components.year ?? 0

        month =
            components.month ?? 0

        day =
            components.day ?? 0
    }
}