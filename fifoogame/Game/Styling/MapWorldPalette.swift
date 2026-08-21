//
//  MapWorldPalette.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/20/26.
//


import SpriteKit

enum MapWorldPalette {

    // MARK: - Day / Night

    static let midnight =
        SKColor(
            red: 24 / 255,
            green: 34 / 255,
            blue: 49 / 255,
            alpha: 1
        )

    static let dawn =
        SKColor(
            red: 54 / 255,
            green: 74 / 255,
            blue: 92 / 255,
            alpha: 1
        )

    static let daylight =
        SKColor(
            red: 70 / 255,
            green: 91 / 255,
            blue: 110 / 255,
            alpha: 1
        )

    static let noon =
        SKColor(
            red: 78 / 255,
            green: 101 / 255,
            blue: 119 / 255,
            alpha: 1
        )

    static let sunset =
        SKColor(
            red: 88 / 255,
            green: 78 / 255,
            blue: 92 / 255,
            alpha: 1
        )

    static let lateNight =
        SKColor(
            red: 31 / 255,
            green: 43 / 255,
            blue: 60 / 255,
            alpha: 1
        )


    // MARK: - Urban

    static let block =
        SKColor(
            red: 58 / 255,
            green: 75 / 255,
            blue: 92 / 255,
            alpha: 0.42
        )

    static let blockAlternate =
        SKColor(
            red: 63 / 255,
            green: 81 / 255,
            blue: 99 / 255,
            alpha: 0.40
        )

    static let building =
        SKColor(
            red: 82 / 255,
            green: 98 / 255,
            blue: 113 / 255,
            alpha: 0.72
        )

    static let buildingAlternate =
        SKColor(
            red: 91 / 255,
            green: 106 / 255,
            blue: 120 / 255,
            alpha: 0.68
        )

    static let buildingShadow =
        SKColor(
            red: 0,
            green: 0,
            blue: 0,
            alpha: 0.15
        )


    // MARK: - Nature

    static let park =
        SKColor(
            red: 64 / 255,
            green: 100 / 255,
            blue: 86 / 255,
            alpha: 0.68
        )

    static let parkEdge =
        SKColor(
            red: 86 / 255,
            green: 123 / 255,
            blue: 102 / 255,
            alpha: 0.50
        )

    static let tree =
        SKColor(
            red: 80 / 255,
            green: 123 / 255,
            blue: 96 / 255,
            alpha: 0.88
        )

    static let water =
        SKColor(
            red: 50 / 255,
            green: 102 / 255,
            blue: 128 / 255,
            alpha: 0.82
        )

    static let waterEdge =
        SKColor(
            red: 35 / 255,
            green: 77 / 255,
            blue: 101 / 255,
            alpha: 0.75
        )


    // MARK: - Roads

    static let roadShadow =
        SKColor(
            red: 0,
            green: 0,
            blue: 0,
            alpha: 0.22
        )

    static let roadMarking =
        SKColor(
            red: 0.93,
            green: 0.94,
            blue: 0.93,
            alpha: 0.58
        )

    static let crosswalk =
        SKColor(
            red: 1,
            green: 1,
            blue: 1,
            alpha: 0.52
        )
}