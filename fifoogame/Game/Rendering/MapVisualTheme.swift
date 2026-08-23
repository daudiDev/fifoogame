//
//  MapVisualTheme.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/22/26.
//


import SpriteKit


enum MapVisualTheme {

    // =====================================================
    // MARK: - Step 3 Cartesian Map
    // =====================================================

    /// The entire scene background is the continuous road surface.
    /// Dark blue-charcoal keeps the existing Fifoo palette while matching
    /// the supplied reference's road/land contrast.
    static let roadSurfaceColor =
        SKColor(
            red: 26 / 255,
            green: 38 / 255,
            blue: 50 / 255,
            alpha: 1
        )


    /// Raised rounded-square land islands.
    static let islandFillColor =
        SKColor(
            red: 66 / 255,
            green: 86 / 255,
            blue: 110 / 255,
            alpha: 1
        )


    /// Thin lighter curb/perimeter around each island.
    static let islandBorderColor =
        SKColor(
            red: 112 / 255,
            green: 133 / 255,
            blue: 155 / 255,
            alpha: 0.72
        )


    /// Subtle lower/right depth edge beneath each island.
    static let islandShadowColor =
        SKColor(
            red: 0,
            green: 0,
            blue: 0,
            alpha: 0.24
        )


    /// Sparse center markings inside each road section.
    static let roadDashColor =
        SKColor(
            red: 235 / 255,
            green: 240 / 255,
            blue: 245 / 255,
            alpha: 0.72
        )


    // =====================================================
    // MARK: - Compatibility Aliases
    // =====================================================

    /// Legacy renderers still compile during the staged migration. Step 3
    /// no longer uses them for the visible map.
    static let landColor =
        islandFillColor


    static let highwaySurfaceColor =
        roadSurfaceColor


    static let roadBorderColor =
        SKColor(
            red: 46 / 255,
            green: 60 / 255,
            blue: 77 / 255,
            alpha: 0.95
        )


    static let roundaboutIslandColor =
        islandFillColor


    static let roundaboutIslandBorderColor =
        SKColor(
            red: 90 / 255,
            green: 112 / 255,
            blue: 137 / 255,
            alpha: 0.18
        )


    // =====================================================
    // MARK: - Legacy Environment Compatibility
    // =====================================================

    static let parkColor =
        SKColor(
            red: 92 / 255,
            green: 135 / 255,
            blue: 112 / 255,
            alpha: 1
        )


    static let waterColor =
        SKColor(
            red: 97 / 255,
            green: 141 / 255,
            blue: 171 / 255,
            alpha: 1
        )


    // =====================================================
    // MARK: - Legacy Coordinate Grid Compatibility
    // =====================================================

    static let minorGridColor =
        SKColor(
            red: 90 / 255,
            green: 112 / 255,
            blue: 137 / 255,
            alpha: 0.18
        )


    static let majorGridColor =
        minorGridColor


    static let referenceBoundaryColor =
        SKColor(
            red: 147 / 255,
            green: 165 / 255,
            blue: 184 / 255,
            alpha: 0.38
        )


    static let gridLabelColor =
        SKColor(
            red: 186 / 255,
            green: 199 / 255,
            blue: 213 / 255,
            alpha: 0.62
        )


    // =====================================================
    // MARK: - Selection
    // =====================================================

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


    // =====================================================
    // MARK: - Game Nodes
    // =====================================================

    static let nodeFillColor =
        SKColor(
            red: 216 / 255,
            green: 226 / 255,
            blue: 236 / 255,
            alpha: 1
        )


    static let nodeBorderColor =
        SKColor(
            red: 153 / 255,
            green: 174 / 255,
            blue: 195 / 255,
            alpha: 1
        )


    static let nodeTextColor =
        SKColor(
            red: 41 / 255,
            green: 57 / 255,
            blue: 75 / 255,
            alpha: 1
        )


    static let nodeLabelColor =
        SKColor(
            red: 224 / 255,
            green: 232 / 255,
            blue: 240 / 255,
            alpha: 0.95
        )
}
