//
//  GameIdentifiers.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/18/26.
//

import Foundation

struct GameDayID: Hashable, Codable, Sendable, Identifiable {

    let rawValue: UUID

    var id: UUID {
        rawValue
    }

    init(_ rawValue: UUID = UUID()) {
        self.rawValue = rawValue
    }
}


struct RouteID: Hashable, Codable, Sendable, Identifiable {

    let rawValue: UUID

    var id: UUID {
        rawValue
    }

    init(_ rawValue: UUID = UUID()) {
        self.rawValue = rawValue
    }
}


struct GameNodeID: Hashable, Codable, Sendable, Identifiable {

    let rawValue: UUID

    var id: UUID {
        rawValue
    }

    init(_ rawValue: UUID = UUID()) {
        self.rawValue = rawValue
    }
}
