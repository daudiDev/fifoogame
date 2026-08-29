//
//  GridMapGeometry.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/23/26.
//


import Foundation
import CoreGraphics


// MARK: - Grid Cell Identity

/// Deterministic identity for one land island / city block.
///
/// The grid origin is the intersection at:
///
///     progress = 0%
///     time     = 12:00 AM
///
/// A cell sits to the RIGHT and DOWN of its `(column, row)` street
/// intersection. Columns may be negative so the map can continue into
/// negative progress. Rows are rendered only inside the 24-hour day.
nonisolated struct GridCellID: Hashable, Sendable {

    let column: Int
    let row: Int

    init(
        column: Int,
        row: Int
    ) {

        self.column = column
        self.row = row
    }
}


// MARK: - Visible Grid Region

/// Rectangular range of deterministic cells needed around the camera.
///
/// Step 3 will use this to create/remove island SpriteKit nodes only when
/// the camera crosses into a new grid region instead of rebuilding the
/// world every frame.
struct GridVisibleRegion: Equatable, Sendable {

    let minimumColumn: Int
    let maximumColumn: Int
    let minimumRow: Int
    let maximumRow: Int


    var cellCount: Int {

        guard
            maximumColumn >= minimumColumn,
            maximumRow >= minimumRow
        else {
            return 0
        }

        return
            (maximumColumn - minimumColumn + 1)
            *
            (maximumRow - minimumRow + 1)
    }


    var cellIDs: [GridCellID] {

        guard cellCount > 0 else {
            return []
        }

        var result: [GridCellID] = []
        result.reserveCapacity(cellCount)

        for row in minimumRow ... maximumRow {

            for column in minimumColumn ... maximumColumn {

                result.append(
                    GridCellID(
                        column: column,
                        row: row
                    )
                )
            }
        }

        return result
    }


    func contains(
        _ id: GridCellID
    ) -> Bool {

        id.column >= minimumColumn
        && id.column <= maximumColumn
        && id.row >= minimumRow
        && id.row <= maximumRow
    }
}


// MARK: - Grid Configuration

/// Shared geometry constants for the new rounded-square island system.
///
/// These are WORLD-GEOMETRY values expressed first in the Cartesian map
/// units introduced in Step 1. Because X and Y now use the same scale,
/// equal map-unit dimensions render as true squares.
enum GridMapConfiguration {

    // =====================================================
    // MARK: - Repeating Cell Geometry
    // =====================================================

    /// The new low-density layout intentionally contains exactly four
    /// island rows in every six-hour window:
    ///
    ///     12 AM ...  6 AM = 4 islands
    ///      6 AM ... 12 PM = 4 islands
    ///     12 PM ...  6 PM = 4 islands
    ///      6 PM ... 12 AM = 4 islands
    ///
    /// The 24-hour axis itself remains exactly the same height as Step 1.
    static let sixHourWindowCountPerDay: Int = 4

    static let islandsPerSixHourWindow: Int = 4

    static let dayGridRowCount: Int =
        sixHourWindowCountPerDay
        * islandsPerSixHourWindow


    /// Distance from one street centerline to the next.
    ///
    /// The full day remains 200 Cartesian map units / 2000 SpriteKit points.
    /// With 16 pitches across the day:
    ///
    ///     200 / 16 = 12.5 map units
    ///     12.5 * 10 = 125 world points
    ///
    /// Vertically this is exactly 1.5 hours per pitch, which creates four
    /// complete island rows inside every six-hour window.
    static var cellPitchMapUnits: CGFloat {

        (
            MapWorldConfiguration.height
            / MapWorldConfiguration.worldPointsPerMapUnit
        )
        / CGFloat(dayGridRowCount)
    }


    /// Baseline street share from the previous low-density Step 3 layout.
    ///
    /// The current visual experiment asks for two simultaneous changes:
    ///
    ///     island emphasis  × 0.70
    ///     road emphasis    × 1.30
    ///
    /// The grid pitch itself MUST remain fixed at 12.5 map units so we keep:
    ///
    ///     4 islands per 6-hour window
    ///     16 island rows across the day
    ///     8 matching columns across 0...100% progress
    ///
    /// Because islandSize + roadWidth must equal the fixed pitch, literal
    /// -30% and +30% world-space changes cannot both happen independently.
    /// We therefore apply those factors as relative visual weights and then
    /// normalize them back into the same 12.5-unit pitch.
    static let baselineRoadWidthFractionOfPitch: CGFloat = 0.2688

    static let requestedIslandScale: CGFloat = 0.70
    static let requestedRoadScale: CGFloat = 1.30


    static var roadWidthFractionOfPitch: CGFloat {

        let baselineRoad =
            baselineRoadWidthFractionOfPitch

        let baselineIsland =
            1 - baselineRoad

        let weightedRoad =
            baselineRoad
            * requestedRoadScale

        let weightedIsland =
            baselineIsland
            * requestedIslandScale

        return
            weightedRoad
            / (weightedRoad + weightedIsland)
    }


    static var roadWidthMapUnits: CGFloat {

        cellPitchMapUnits
        * roadWidthFractionOfPitch
    }


    /// The island occupies the remaining portion of the fixed pitch.
    ///
    /// With the normalized -30% island / +30% road visual weighting, the
    /// current 125-point pitch becomes approximately:
    ///
    ///     road   = 50.72 world points
    ///     island = 74.28 world points
    ///
    /// This is intentionally much more road-dominant than the prior:
    ///
    ///     road   = 33.6
    ///     island = 91.4
    ///
    /// while preserving all Cartesian/time/progress topology.
    static var islandSizeMapUnits: CGFloat {

        cellPitchMapUnits
        - roadWidthMapUnits
    }


    /// Slightly increase the proportional rounding on the smaller islands so
    /// they still read as soft rounded squares beside the wider streets.
    static var islandCornerRadiusMapUnits: CGFloat {

        islandSizeMapUnits
        * 0.145
    }


    // =====================================================
    // MARK: - Horizontal Progress Match
    // =====================================================

    /// Because the coordinate plane is Cartesian, the exact same 12.5-unit
    /// pitch is used horizontally.
    ///
    /// One map unit equals one progress percentage point, so the standard
    /// 0...100% progress span contains exactly:
    ///
    ///     100 / 12.5 = 8 grid columns
    ///
    /// This is the horizontal counterpart to the four-islands-per-six-hours
    /// vertical rule and keeps every land island square.
    static var standardProgressGridColumnCount: Int {

        Int(
            round(
                MapWorldConfiguration.width
                / cellPitchWorld
            )
        )
    }


    // =====================================================
    // MARK: - Step 3 Visual Geometry
    // =====================================================

    /// Keep the perimeter delicate after shrinking the islands.
    static var islandBorderWidthMapUnits: CGFloat {

        islandSizeMapUnits
        * 0.015
    }


    /// The smaller islands need a slightly shallower shadow so the raised
    /// effect does not visually eat into the newly widened road corridor.
    static var islandShadowOffsetXMapUnits: CGFloat {

        islandSizeMapUnits
        * 0.030
    }

    static var islandShadowOffsetYMapUnits: CGFloat {

        islandSizeMapUnits
        * 0.034
    }


    /// Keep the sparse two-dash street language, but lengthen each dash just
    /// enough to feel intentional inside the substantially wider roads.
    static var roadDashLengthMapUnits: CGFloat {

        cellPitchMapUnits
        * 0.105
        

    }

    /// Road markings grow with road width, but at a restrained 6% so the
    /// wider asphalt does not make the center dashes visually heavy.
    static var roadDashLineWidthMapUnits: CGFloat {

        roadWidthMapUnits
        * 0.060
        //MARK: todo temp
//        roadWidthMapUnits
//        * 0.090
        
    }

    static let roadDashCountPerSegment: Int = 2

    /// Give the larger intersections a little more breathing room before
    /// lane dashes resume.
    static var roadIntersectionClearanceMapUnits: CGFloat {

        cellPitchMapUnits
        * 0.235
    }


    // =====================================================
    // MARK: - World-Space Values
    // =====================================================

    static var cellPitchWorld: CGFloat {

        cellPitchMapUnits
        * MapWorldConfiguration.worldPointsPerMapUnit
    }


    static var roadWidthWorld: CGFloat {

        roadWidthMapUnits
        * MapWorldConfiguration.worldPointsPerMapUnit
    }


    static var roadHalfWidthWorld: CGFloat {

        roadWidthWorld / 2
    }


    static var islandSizeWorld: CGFloat {

        islandSizeMapUnits
        * MapWorldConfiguration.worldPointsPerMapUnit
    }


    static var islandCornerRadiusWorld: CGFloat {

        islandCornerRadiusMapUnits
        * MapWorldConfiguration.worldPointsPerMapUnit
    }


    static var islandBorderWidthWorld: CGFloat {

        islandBorderWidthMapUnits
        * MapWorldConfiguration.worldPointsPerMapUnit
    }


    static var islandShadowOffsetXWorld: CGFloat {

        islandShadowOffsetXMapUnits
        * MapWorldConfiguration.worldPointsPerMapUnit
    }


    static var islandShadowOffsetYWorld: CGFloat {

        islandShadowOffsetYMapUnits
        * MapWorldConfiguration.worldPointsPerMapUnit
    }


    static var roadDashLengthWorld: CGFloat {

        roadDashLengthMapUnits
        * MapWorldConfiguration.worldPointsPerMapUnit
    }


    static var roadDashLineWidthWorld: CGFloat {

        roadDashLineWidthMapUnits
        * MapWorldConfiguration.worldPointsPerMapUnit
    }


    static var roadIntersectionClearanceWorld: CGFloat {

        roadIntersectionClearanceMapUnits
        * MapWorldConfiguration.worldPointsPerMapUnit
    }


    // =====================================================
    // MARK: - Camera Rendering Buffer
    // =====================================================

    /// Keep one full extra cell around the visible camera rectangle.
    ///
    /// The Step 3 low-density grid uses a 125-point pitch, and Step 8 updates
    /// the visible region every rendered frame while the camera is moving.
    /// One buffered pitch is therefore enough to prevent edge pop-in while
    /// avoiding the unnecessary extra islands created by the old two-cell
    /// buffer.
    static let visibleRenderBufferCells: Int = 1


    static var dayRowCount: Int {

        dayGridRowCount
    }


    static var maximumDayRow: Int {

        max(
            0,
            dayRowCount - 1
        )
    }
}


// MARK: - Grid Geometry

/// Pure deterministic geometry for the new map.
///
/// There is deliberately no SpriteKit node creation here. Step 2 defines
/// where the grid exists; Step 3 will decide how it looks.
enum GridMapGeometry {

    // =====================================================
    // MARK: - Origin / Day Bounds
    // =====================================================

    /// Street intersection aligned with 0% progress at midnight.
    static var origin: CGPoint {

        CGPoint(
            x:
                MapCoordinateConverter
                    .worldX(
                        forProgress: 0
                    ),
            y:
                MapCoordinateConverter
                    .worldY(
                        for: .startOfDay
                    )
        )
    }


    static var dayTopY: CGFloat {

        MapCoordinateConverter
            .worldY(
                for: .startOfDay
            )
    }


    static var dayBottomY: CGFloat {

        MapCoordinateConverter
            .worldY(
                for: .endOfDay
            )
    }


    // =====================================================
    // MARK: - Street Centerlines
    // =====================================================

    /// X position of a vertical street centerline.
    static func verticalStreetCenterX(
        column: Int
    ) -> CGFloat {

        origin.x
        + CGFloat(column)
        * GridMapConfiguration.cellPitchWorld
    }


    /// Y position of a horizontal street centerline.
    ///
    /// Row increases as time moves DOWN, while SpriteKit world Y becomes
    /// more negative.
    static func horizontalStreetCenterY(
        row: Int
    ) -> CGFloat {

        origin.y
        - CGFloat(row)
        * GridMapConfiguration.cellPitchWorld
    }


    // =====================================================
    // MARK: - Cell Geometry
    // =====================================================

    /// World-space top-left street intersection that owns a grid cell.
    /// Renderers can position cached local cell geometry at this point rather
    /// than rebuilding identical CGPaths at every column/row coordinate.
    static func cellOrigin(
        for id: GridCellID
    ) -> CGPoint {

        CGPoint(
            x:
                verticalStreetCenterX(
                    column: id.column
                ),
            y:
                horizontalStreetCenterY(
                    row: id.row
                )
        )
    }


    /// Full pitch footprint for a grid cell, including half of each road
    /// corridor around the island.
    static func footprintRect(
        for id: GridCellID
    ) -> CGRect {

        let leftStreetX =
            verticalStreetCenterX(
                column: id.column
            )

        let topStreetY =
            horizontalStreetCenterY(
                row: id.row
            )

        let pitch =
            GridMapConfiguration
                .cellPitchWorld

        return CGRect(
            x: leftStreetX,
            y: topStreetY - pitch,
            width: pitch,
            height: pitch
        )
    }


    /// Rounded-square island rectangle inside one repeating grid pitch.
    ///
    /// The exposed gap between adjacent island rectangles is exactly the
    /// configured road width.
    static func islandRect(
        for id: GridCellID
    ) -> CGRect {

        let leftStreetX =
            verticalStreetCenterX(
                column: id.column
            )

        let topStreetY =
            horizontalStreetCenterY(
                row: id.row
            )

        let halfRoad =
            GridMapConfiguration
                .roadHalfWidthWorld

        let islandSize =
            GridMapConfiguration
                .islandSizeWorld

        let islandLeft =
            leftStreetX
            + halfRoad

        let islandTop =
            topStreetY
            - halfRoad

        return CGRect(
            x: islandLeft,
            y: islandTop - islandSize,
            width: islandSize,
            height: islandSize
        )
    }


    static func islandCenter(
        for id: GridCellID
    ) -> CGPoint {

        let rect =
            islandRect(
                for: id
            )

        return CGPoint(
            x: rect.midX,
            y: rect.midY
        )
    }


    // =====================================================
    // MARK: - Tile/Card Geometry
    // =====================================================

    /// Visual gap between neighboring cards in the redesigned day map.
    ///
    /// This intentionally does not change the semantic grid pitch. The old
    /// road topology can therefore continue to power routing/pathfinding while
    /// the visible UI reads as a field of cards instead of streets.
    static var tileGapWorld: CGFloat {

        // Pass 3: give the cards enough breathing room to read as discrete
        // islands rather than a nearly continuous board. The semantic pitch
        // is unchanged, so routing/time/progress math is untouched.
        min(
            22,
            GridMapConfiguration.cellPitchWorld * 0.18
        )
    }


    /// Square card rectangle centered inside the existing deterministic cell.
    static func tileRect(
        for id: GridCellID
    ) -> CGRect {

        footprintRect(
            for: id
        )
        .insetBy(
            dx: tileGapWorld / 2,
            dy: tileGapWorld / 2
        )
    }


    static func tileCenter(
        for id: GridCellID
    ) -> CGPoint {

        let rect =
            tileRect(
                for: id
            )

        return CGPoint(
            x: rect.midX,
            y: rect.midY
        )
    }


    /// Deterministically resolves a world point to the cell footprint that
    /// contains it. Rows remain limited to the semantic 24-hour day.
    static func cellID(
        containingWorldPoint point: CGPoint
    ) -> GridCellID? {

        let pitch =
            GridMapConfiguration
                .cellPitchWorld

        guard pitch > 0 else {
            return nil
        }

        let column =
            Int(
                floor(
                    (point.x - origin.x)
                    / pitch
                )
            )

        let row =
            Int(
                floor(
                    (origin.y - point.y)
                    / pitch
                )
            )

        guard
            row >= 0,
            row <= GridMapConfiguration.maximumDayRow
        else {
            return nil
        }

        return GridCellID(
            column: column,
            row: row
        )
    }


    static func cellID(
        containing coordinate: MapCoordinate
    ) -> GridCellID? {

        let point =
            MapCoordinateConverter
                .worldPoint(
                    for: coordinate
                )
                .cgPoint

        return cellID(
            containingWorldPoint: point
        )
    }


    /// Resolves to the nearest card center. This is used to project the old
    /// hidden road-route geometry into a visible sequence of route cards.
    static func cellID(
        nearestToWorldPoint point: CGPoint
    ) -> GridCellID? {

        guard let containing =
            cellID(
                containingWorldPoint: point
            )
        else {
            return nil
        }

        var candidates:
            [GridCellID] = []

        for rowOffset in -1...1 {

            let row =
                containing.row
                + rowOffset

            guard
                row >= 0,
                row <= GridMapConfiguration.maximumDayRow
            else {
                continue
            }

            for columnOffset in -1...1 {

                candidates.append(
                    GridCellID(
                        column:
                            containing.column
                            + columnOffset,
                        row: row
                    )
                )
            }
        }

        return candidates.min { lhs, rhs in

            let l =
                tileCenter(
                    for: lhs
                )

            let r =
                tileCenter(
                    for: rhs
                )

            let ld =
                hypot(
                    l.x - point.x,
                    l.y - point.y
                )

            let rd =
                hypot(
                    r.x - point.x,
                    r.y - point.y
                )

            if abs(ld - rd) < 0.0001 {

                // Exact street-boundary ties belong to the deterministic
                // footprint returned by `cellID(containingWorldPoint:)`.
                // This keeps a hidden routing anchor on a card edge visually
                // associated with that same card rather than its neighbor.
                if lhs == containing {
                    return true
                }

                if rhs == containing {
                    return false
                }

                if lhs.row != rhs.row {
                    return lhs.row < rhs.row
                }

                return lhs.column < rhs.column
            }

            return ld < rd
        }
    }


    /// Returns a cell only when the point is actually inside the visible card
    /// rectangle. Gaps between cards remain ordinary map background.
    static func tileCellID(
        hitByWorldPoint point: CGPoint
    ) -> GridCellID? {

        guard let id =
            cellID(
                containingWorldPoint: point
            )
        else {
            return nil
        }

        return tileRect(
            for: id
        )
        .contains(point)
        ? id
        : nil
    }


    static func mapCoordinateAtTileCenter(
        for id: GridCellID
    ) -> MapCoordinate {

        let center =
            tileCenter(
                for: id
            )

        return MapCoordinateConverter
            .mapCoordinate(
                for:
                    WorldPoint(
                        x: Double(center.x),
                        y: Double(center.y)
                    )
            )
    }


    // =====================================================
    // MARK: - Visible Region
    // =====================================================

    /// Returns the deterministic grid cell range needed for the supplied
    /// world-space camera rectangle.
    ///
    /// Horizontal columns are intentionally unbounded. Vertical rows are
    /// clipped to the semantic 24-hour day.
    static func visibleRegion(
        in visibleWorldRect: CGRect,
        bufferCells: Int =
            GridMapConfiguration
                .visibleRenderBufferCells
    ) -> GridVisibleRegion? {

        guard
            visibleWorldRect.width.isFinite,
            visibleWorldRect.height.isFinite,
            visibleWorldRect.minX.isFinite,
            visibleWorldRect.maxX.isFinite,
            visibleWorldRect.minY.isFinite,
            visibleWorldRect.maxY.isFinite,
            visibleWorldRect.width > 0,
            visibleWorldRect.height > 0
        else {
            return nil
        }

        let pitch =
            GridMapConfiguration
                .cellPitchWorld

        guard pitch > 0 else {
            return nil
        }

        let safeBuffer =
            max(
                0,
                bufferCells
            )

        let bufferDistance =
            CGFloat(safeBuffer)
            * pitch

        let expanded =
            visibleWorldRect
                .insetBy(
                    dx: -bufferDistance,
                    dy: -bufferDistance
                )


        // -------------------------------------------------
        // Horizontal range — intentionally unbounded.
        // -------------------------------------------------

        let minimumColumn =
            Int(
                floor(
                    (
                        expanded.minX
                        - origin.x
                    )
                    / pitch
                )
            )

        let maximumColumn =
            Int(
                floor(
                    (
                        expanded.maxX
                        - origin.x
                    )
                    / pitch
                )
            )


        // -------------------------------------------------
        // Vertical range — clamp to 12 AM ... end of day.
        // -------------------------------------------------

        let clippedTopY =
            min(
                dayTopY,
                expanded.maxY
            )

        let clippedBottomY =
            max(
                dayBottomY,
                expanded.minY
            )

        guard
            clippedBottomY < clippedTopY
            || abs(
                clippedBottomY - clippedTopY
            ) < 0.0001
        else {
            return nil
        }

        // If the expanded camera area lies entirely above or below the
        // day, there is no grid region to render.
        guard
            expanded.maxY >= dayBottomY,
            expanded.minY <= dayTopY
        else {
            return nil
        }

        let topDistanceFromOrigin =
            max(
                0,
                origin.y - clippedTopY
            )

        let bottomDistanceFromOrigin =
            min(
                MapWorldConfiguration.height,
                max(
                    0,
                    origin.y - clippedBottomY
                )
            )

        let minimumRow =
            min(
                GridMapConfiguration.maximumDayRow,
                max(
                    0,
                    Int(
                        floor(
                            topDistanceFromOrigin
                            / pitch
                        )
                    )
                )
            )

        // Probe just inside the lower boundary so an exact street line at
        // 24:00 does not create a non-existent extra row.
        let bottomProbe =
            max(
                0,
                bottomDistanceFromOrigin
                - 0.0001
            )

        let maximumRow =
            min(
                GridMapConfiguration.maximumDayRow,
                max(
                    minimumRow,
                    Int(
                        floor(
                            bottomProbe
                            / pitch
                        )
                    )
                )
            )

        return GridVisibleRegion(
            minimumColumn: minimumColumn,
            maximumColumn: maximumColumn,
            minimumRow: minimumRow,
            maximumRow: maximumRow
        )
    }


    // =====================================================
    // MARK: - Debug Validation
    // =====================================================

    static func debugAssertGeometry(
        file: StaticString = #fileID,
        line: UInt = #line
    ) {

        let pitch =
            GridMapConfiguration
                .cellPitchWorld

        let road =
            GridMapConfiguration
                .roadWidthWorld

        let island =
            GridMapConfiguration
                .islandSizeWorld

        assert(
            abs(
                pitch
                - (road + island)
            ) < 0.001,
            "Grid pitch must equal road width + island size.",
            file: file,
            line: line
        )

        let testRect =
            islandRect(
                for:
                    GridCellID(
                        column: 0,
                        row: 0
                    )
            )

        assert(
            abs(
                testRect.width
                - testRect.height
            ) < 0.001,
            "Fifoo grid islands must remain square in world space.",
            file: file,
            line: line
        )

        assert(
            GridMapConfiguration.dayRowCount > 0,
            "Fifoo grid must contain at least one day row.",
            file: file,
            line: line
        )

        assert(
            GridMapConfiguration.dayRowCount == 16,
            "The redesigned day grid must contain exactly 16 island rows (4 per 6-hour window).",
            file: file,
            line: line
        )

        let sixHourWorldHeight =
            MapWorldConfiguration.height / 4

        let fourPitchWorldHeight =
            GridMapConfiguration.cellPitchWorld * 4

        assert(
            abs(sixHourWorldHeight - fourPitchWorldHeight) < 0.001,
            "Exactly four grid pitches must fit inside every six-hour window.",
            file: file,
            line: line
        )

        assert(
            GridMapConfiguration.standardProgressGridColumnCount == 8,
            "The normal 0...100% progress span must contain exactly eight matching Cartesian grid columns.",
            file: file,
            line: line
        )
    }
}
