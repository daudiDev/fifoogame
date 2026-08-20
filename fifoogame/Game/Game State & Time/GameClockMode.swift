//
//  GameClockMode.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/20/26.
//


import Foundation

enum GameClockMode:
    String,
    Codable,
    Equatable,
    Sendable {

    case realTime
    case simulated
}