//
//  MapVisualWorldBounds.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/20/26.
//


import CoreGraphics


enum MapVisualWorldBounds {

    // =====================================================
    // MARK: - Decorative Progress Range
    // =====================================================

    /// This controls only how far decorative scenery
    /// is generated.
    ///
    /// It does NOT change Fifoo's coordinate system.
    static let minimumProgress:
        Double = -100


    static let maximumProgress:
        Double = 250


    // =====================================================
    // MARK: - Horizontal Bounds
    // =====================================================

    static var minimumX:
        CGFloat {

        worldX(
            forProgress:
                minimumProgress
        )
    }


    static var maximumX:
        CGFloat {

        worldX(
            forProgress:
                maximumProgress
        )
    }


    static var width:
        CGFloat {

        maximumX
        -
        minimumX
    }


    // =====================================================
    // MARK: - Vertical Bounds
    // =====================================================

    static let topY:
        CGFloat = 0


    static var bottomY:
        CGFloat {

        -MapWorldConfiguration.height
    }


    static var height:
        CGFloat {

        MapWorldConfiguration.height
    }


    // =====================================================
    // MARK: - Conversion
    // =====================================================

    private static func worldX(
        forProgress progress:
            Double
    ) -> CGFloat {

        let referenceMinimum =
            MapWorldConfiguration
                .minimumReferenceProgress


        let referenceMaximum =
            MapWorldConfiguration
                .maximumReferenceProgress


        let referenceRange =
            referenceMaximum
            -
            referenceMinimum


        guard referenceRange != 0 else {

            return 0
        }


        let fraction =
            (
                progress
                -
                referenceMinimum
            )
            /
            referenceRange


        return CGFloat(
            Double(
                MapWorldConfiguration.width
            )
            *
            fraction
        )
    }
}
