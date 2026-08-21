//
//  CompletedGameDaySnapshot.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/20/26.
//


import Foundation


struct CompletedGameDaySnapshot:
    Equatable,
    Sendable {

    let gameDayID:
        GameDayID

    let calendarDay:
        CalendarDayKey

    let completedRoute:
        CompletedRoute

    let progressState:
        DayProgressState
}
