//
//  MapVisualTheme.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/19/26.
//

import SpriteKit

enum MapVisualTheme {

    // MARK: - Base Map
    // Main background: #42566e
    static let landColor = SKColor(
        red: 26 / 255,
        green: 38 / 255,
        blue: 50 / 255,
        alpha: 1
    )

    // MARK: - Roads
    // Light blue-gray tint of the background
    static let roadSurfaceColor = SKColor(
        red: 66 / 255,
        green: 86 / 255,
        blue: 110 / 255,
        alpha: 0.95
    )

    // Slightly brighter tint for highways
    static let highwaySurfaceColor = SKColor(
        red: 66 / 255,
        green: 86 / 255,
        blue: 110 / 255,
        alpha: 1
    )
    
    // Border color: medium blue-gray tint
    static let roadBorderColor = SKColor(
        red: 46 / 255,
        green: 60 / 255,
        blue: 77 / 255,
        alpha: 0.95
    )

    // MARK: - Roundabout
    static let roundaboutIslandColor = SKColor(
        red: 26 / 255,
        green: 38 / 255,
        blue: 50 / 255,
        alpha: 1
    )

    static let roundaboutIslandBorderColor = SKColor(
        red: 90 / 255,    // #5a7089
        green: 112 / 255,
        blue: 137 / 255,
        alpha: 0.18
    )

    // MARK: - Future Environment
    static let parkColor = SKColor(
        red: 92 / 255,
        green: 135 / 255,
        blue: 112 / 255,
        alpha: 1
    )

    static let waterColor = SKColor(
        red: 97 / 255,
        green: 141 / 255,
        blue: 171 / 255,
        alpha: 1
    )

    // MARK: - Coordinate Grid
    static let minorGridColor = SKColor(
        red: 90 / 255,    // #5a7089
        green: 112 / 255,
        blue: 137 / 255,
        alpha: 0.18
    )

    static let majorGridColor = SKColor(
        red: 90 / 255,    // #5a7089
        green: 112 / 255,
        blue: 137 / 255,
        alpha: 0.18
    )

    static let referenceBoundaryColor = SKColor(
        red: 147 / 255,   // #93a5b8
        green: 165 / 255,
        blue: 184 / 255,
        alpha: 0.38
    )

    static let gridLabelColor = SKColor(
        red: 186 / 255,   // #bac7d5
        green: 199 / 255,
        blue: 213 / 255,
        alpha: 0.62
    )
    
    // MARK: - Selection

    static let roadSelectionColor =
        SKColor(
            red: 132 / 255,
            green: 190 / 255,
            blue: 239 / 255,
            alpha: 1
        )


    static let roadSelectionHaloColor =
        SKColor(
            red: 211 / 255,
            green: 229 / 255,
            blue: 246 / 255,
            alpha: 0.38
        )
}
