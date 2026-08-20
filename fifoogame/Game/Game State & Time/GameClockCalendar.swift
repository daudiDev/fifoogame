//
//  GameClockCalendar.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/20/26.
//


import Foundation

enum GameClockCalendar {

    static func dayTime(
        for date: Date,
        timeZone: TimeZone
    ) -> DayTime {

        DayTime.from(
            date: date,
            timeZone: timeZone
        )
    }


    static func date(
        for day:
            CalendarDayKey,
        at time:
            DayTime,
        timeZone:
            TimeZone
    ) -> Date? {

        var calendar =
            Calendar(identifier: .gregorian)

        calendar.timeZone =
            timeZone


        var components =
            DateComponents()

        components.year =
            day.year

        components.month =
            day.month

        components.day =
            day.day

        components.hour =
            0

        components.minute =
            0

        components.second =
            0


        guard let startOfDay =
            calendar.date(
                from: components
            )
        else {

            return nil
        }


        return startOfDay
            .addingTimeInterval(
                time.secondsFromMidnight
            )
    }
}


