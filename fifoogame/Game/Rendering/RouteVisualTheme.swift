//
//  RouteVisualTheme.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/19/26.
//


import SpriteKit


enum RouteVisualTheme {

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
        CGFloat = 8


    static let completedHaloWidth:
        CGFloat = 14


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
        CGFloat = 7


    static let chosenHaloWidth:
        CGFloat = 13


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
        CGFloat = 4


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
}
