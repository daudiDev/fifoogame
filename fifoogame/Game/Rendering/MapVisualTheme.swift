//
//  MapVisualTheme.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/25/26.
//



import SpriteKit


enum MapVisualTheme {

    // =====================================================
    // MARK: - Tile Day Map
    // =====================================================

    /// Continuous background behind the square day cards. Roads are no
    /// longer visible in the redesigned UI.
    static let tileMapBackgroundColor =
        SKColor(
            red: 24 / 255,
            green: 34 / 255,
            blue: 46 / 255,
            alpha: 1
        )


    static let tileHiddenFillColor =
        SKColor(
            red: 45 / 255,
            green: 59 / 255,
            blue: 76 / 255,
            alpha: 1
        )


    static let tileHiddenBorderColor =
        SKColor(
            red: 92 / 255,
            green: 111 / 255,
            blue: 132 / 255,
            alpha: 0.52
        )


    static let tileHiddenInnerBorderColor =
        SKColor(
            white: 1,
            alpha: 0.035
        )


    static let tileRevealedFillColor =
        SKColor(
            red: 67 / 255,
            green: 87 / 255,
            blue: 111 / 255,
            alpha: 1
        )


    static let tileRevealedBorderColor =
        SKColor(
            red: 138 / 255,
            green: 158 / 255,
            blue: 179 / 255,
            alpha: 0.78
        )


    static let tileRevealedInnerBorderColor =
        SKColor(
            white: 1,
            alpha: 0.08
        )


    static let tileShadowColor =
        SKColor(
            red: 0,
            green: 0,
            blue: 0,
            alpha: 0.28
        )


    static let tilePrimaryTextColor =
        SKColor(
            red: 245 / 255,
            green: 248 / 255,
            blue: 251 / 255,
            alpha: 1
        )


    static let tileSecondaryTextColor =
        SKColor(
            red: 201 / 255,
            green: 213 / 255,
            blue: 225 / 255,
            alpha: 0.82
        )


    static let tileHiddenTextColor =
        SKColor(
            red: 166 / 255,
            green: 182 / 255,
            blue: 198 / 255,
            alpha: 0.42
        )


    static let tileHiddenSecondaryTextColor =
        SKColor(
            red: 151 / 255,
            green: 168 / 255,
            blue: 184 / 255,
            alpha: 0.45
        )


    static let tileRouteLabelColor =
        SKColor(
            red: 229 / 255,
            green: 237 / 255,
            blue: 245 / 255,
            alpha: 0.66
        )


    /// Neutral center motif used by route-only cards. Route-specific styling
    /// recolors this glyph at render time.
    static let tileRouteGlyphColor =
        SKColor(
            red: 190 / 255,
            green: 205 / 255,
            blue: 219 / 255,
            alpha: 0.48
        )


    static let tileSelectionColor =
        SKColor(
            white: 1,
            alpha: 0.82
        )


    static let tileArtworkBorderColor =
        SKColor(
            white: 1,
            alpha: 0.18
        )


    static let tileCollisionBadgeColor =
        SKColor(
            red: 20 / 255,
            green: 28 / 255,
            blue: 39 / 255,
            alpha: 0.90
        )


    static let tileCollisionBadgeBorderColor =
        SKColor(
            white: 1,
            alpha: 0.28
        )


    // =====================================================
    // MARK: - Step 3 Cartesian Map (legacy compatibility)
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
            alpha: 0.32
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


    /// Bright callout styling used by map nodes. The white capsule is
    /// intentionally close to native map/location-sharing UI and keeps the
    /// avatar + title/time readable over the darker game map.
    static let nodeCaptionBackgroundColor =
        SKColor(
            white: 1,
            alpha: 0.98
        )


    static let nodeCaptionBorderColor =
        SKColor(
            white: 0.84,
            alpha: 1
        )


    static let nodeCaptionShadowColor =
        SKColor(
            red: 0,
            green: 0,
            blue: 0,
            alpha: 0.16
        )


    static let nodeCaptionTitleColor =
        SKColor(
            red: 18 / 255,
            green: 18 / 255,
            blue: 20 / 255,
            alpha: 1
        )


    static let nodeCaptionTimeColor =
        SKColor(
            red: 78 / 255,
            green: 78 / 255,
            blue: 84 / 255,
            alpha: 0.92
        )

}
