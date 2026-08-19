//
//  RoadIdentifiers.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/18/26.
//


import Foundation


// MARK: - Road Graph ID

struct RoadGraphID:
    Hashable,
    Codable,
    Sendable,
    Identifiable,
    CustomStringConvertible {

    let rawValue: String

    var id: String {
        rawValue
    }

    var description: String {
        rawValue
    }

    init(_ rawValue: String) {
        self.rawValue = rawValue
    }
}


// MARK: - Road Vertex ID

struct RoadVertexID:
    Hashable,
    Codable,
    Sendable,
    Identifiable,
    CustomStringConvertible {

    let rawValue: String

    var id: String {
        rawValue
    }

    var description: String {
        rawValue
    }

    init(_ rawValue: String) {
        self.rawValue = rawValue
    }
}


// MARK: - Road Edge ID

struct RoadEdgeID:
    Hashable,
    Codable,
    Sendable,
    Identifiable,
    CustomStringConvertible {

    let rawValue: String

    var id: String {
        rawValue
    }

    var description: String {
        rawValue
    }

    init(_ rawValue: String) {
        self.rawValue = rawValue
    }
}
