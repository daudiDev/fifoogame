//
//  MapLayerZ.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/20/26.
//


import CoreGraphics

enum MapLayerZ {

    static let terrain:
        CGFloat = 0

    static let districts:
        CGFloat = 50

    static let blocks:
        CGFloat = 100

    static let parks:
        CGFloat = 150

    static let buildingShadows:
        CGFloat = 200

    static let buildings:
        CGFloat = 250

    static let vegetation:
        CGFloat = 300

    static let water:
        CGFloat = 350

    static let roadShadows:
        CGFloat = 800

    static let roads:
        CGFloat = 900

    static let roadMarkings:
        CGFloat = 1_000

    static let roadSelection:
        CGFloat = 1_050

    static let routes:
        CGFloat = 1_100

    static let nodes:
        CGFloat = 1_300

    static let persistentUI:
        CGFloat = 100_000
}