//
//  MapDetailLevel.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/20/26.
//


import SpriteKit

enum MapDetailLevel:
    Equatable,
    Sendable {

    case overview
    case normal
    case detailed


    static func resolve(
        cameraScale: CGFloat
    ) -> MapDetailLevel {

        // Larger camera scale = farther zoomed out.

        if cameraScale > 1.65 {
            return .overview
        }

        if cameraScale > 0.82 {
            return .normal
        }

        return .detailed
    }
}