//
//  RouteVisualTheme.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/22/26.
//



import SpriteKit


enum RouteVisualTheme {


    // =====================================================
    // MARK: - Curved Route Geometry
    // =====================================================

    /// Visual trim radius used at a 90-degree grid turn.
    ///
    /// The logical route still reaches the actual road intersection; only
    /// its rendered centerline is rounded. Keeping this tied to both the
    /// street width and grid pitch makes the curve feel like a vehicle turn
    /// without cutting visibly across the rounded land islands.
    static var cornerRadius: CGFloat {

        min(
            GridMapConfiguration.cellPitchWorld * 0.16,
            GridMapConfiguration.roadWidthWorld * 0.60
        )
    }


    /// Never trim more than this fraction of either road segment at a turn.
    /// This leaves a visible straight portion even when two turns occur on
    /// consecutive grid intersections.
    static let maximumCornerTrimFraction: CGFloat = 0.42

    // =====================================================
    // MARK: - Completed
    // =====================================================

    static let completedColor =
        SKColor(
            red:
                92 / 255,
            green:
                220 / 255,
            blue:
                161 / 255,
            alpha:
                1
        )


    static let completedHaloColor =
        SKColor(
            red:
                92 / 255,
            green:
                220 / 255,
            blue:
                161 / 255,
            alpha:
                0.20
        )


    static let completedWidth:
        CGFloat = 24


    static let completedHaloWidth:
        CGFloat = 30


    // =====================================================
    // MARK: - Chosen Future
    // =====================================================

    static let chosenColor =
        SKColor(
            red:
                132 / 255,
            green:
                190 / 255,
            blue:
                239 / 255,
            alpha:
                1
        )


    static let chosenHaloColor =
        SKColor(
            red:
                132 / 255,
            green:
                190 / 255,
            blue:
                239 / 255,
            alpha:
                0.18
        )


    static let chosenWidth:
        CGFloat = 21


    static let chosenHaloWidth:
        CGFloat = 27


    // =====================================================
    // MARK: - Alternatives
    // =====================================================

    static let alternativeColor =
        SKColor(
            red:
                198 / 255,
            green:
                213 / 255,
            blue:
                226 / 255,
            alpha:
                0.52
        )


    static let alternativeWidth:
        CGFloat = 21


    // =====================================================
    // MARK: - Current Boundary
    // =====================================================

    static let boundaryFillColor =
        SKColor.white


    static let boundaryStrokeColor =
        SKColor(
            red:
                92 / 255,
            green:
                220 / 255,
            blue:
                161 / 255,
            alpha:
                1
        )


    static let boundaryRadius:
        CGFloat = 7
    
    // =====================================================
    // MARK: - Draft Preview
    // =====================================================

    static let previewSelectedColor =
        SKColor(
            red:
                1.0,
            green:
                0.72,
            blue:
                0.24,
            alpha:
                1
        )


    static let previewSelectedHaloColor =
        SKColor(
            red:
                1.0,
            green:
                0.72,
            blue:
                0.24,
            alpha:
                0.22
        )


    static let previewAlternativeColor =
        SKColor(
            red:
                1.0,
            green:
                1.0,
            blue:
                1.0,
            alpha:
                0.38
        )


    static let previewSelectedWidth:
        CGFloat = 24


    static let previewSelectedHaloWidth:
        CGFloat = 30


    static let previewAlternativeWidth:
        CGFloat = 21
    
}
