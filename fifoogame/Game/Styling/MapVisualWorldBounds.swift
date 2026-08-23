//
//  MapVisualWorldBounds 2.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/22/26.
//


//
//  MapVisualWorldBounds.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/20/26.
//

import CoreGraphics


/// Bounds used by decorative/world rendering.
///
/// These are deliberately separate from Fifoo's semantic coordinate
/// domain. Progress can still exist outside this decorative range.
enum MapVisualWorldBounds {

    // =====================================================
    // MARK: - Decorative Progress Range
    // =====================================================

    /// Controls how far decorative scenery is generated.
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

        MapCoordinateConverter
            .worldX(
                forProgress:
                    minimumProgress
            )
    }


    static var maximumX:
        CGFloat {

        MapCoordinateConverter
            .worldX(
                forProgress:
                    maximumProgress
            )
    }


    static var width:
        CGFloat {

        maximumX
        - minimumX
    }


    // =====================================================
    // MARK: - Vertical Bounds
    // =====================================================

    static var topY:
        CGFloat {

        MapCoordinateConverter
            .worldY(
                for:
                    .startOfDay
            )
    }


    static var bottomY:
        CGFloat {

        MapCoordinateConverter
            .worldY(
                for:
                    .endOfDay
            )
    }


    static var height:
        CGFloat {

        abs(
            topY
            - bottomY
        )
    }


    // =====================================================
    // MARK: - Convenience Rect
    // =====================================================

    static var rect:
        CGRect {

        CGRect(
            x: minimumX,
            y: bottomY,
            width: width,
            height: height
        )
    }
}