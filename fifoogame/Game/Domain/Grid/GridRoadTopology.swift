//
//  GridRoadTopology.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/22/26.
//


import Foundation
import CoreGraphics


// MARK: - Grid Intersection Identity

/// Logical identity of one crossing in the new Cartesian street system.
///
/// `row` increases downward through time.
/// `column` increases toward higher progress and may be negative.
///
/// Unlike the old city graph, the identity is mathematical and does not
/// depend on a pre-authored road layout.
struct GridIntersectionID:
    Codable,
    Hashable,
    Sendable {

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


// MARK: - Underlying Road Direction

/// Directions physically present in the road network.
///
/// IMPORTANT:
/// The physical ROAD topology contains all four directions.
/// Fifoo ROUTES intentionally expose only left/right/down; see
/// `routeNeighbors(of:)` below.
enum GridRoadDirection:
    String,
    Codable,
    CaseIterable,
    Hashable,
    Sendable {

    case left
    case right
    case up
    case down
}


// MARK: - Neighbor

struct GridRoadNeighbor:
    Hashable,
    Sendable {

    let direction: GridRoadDirection
    let intersection: GridIntersectionID
    let edgeID: RoadEdgeID
}


// MARK: - Grid Road Topology

/// Pure road-network math for the redesigned map.
///
/// Horizontal topology is conceptually unbounded. Vertical topology is
/// bounded by the 24-hour day: rows 0...16 are street intersections, with
/// 16 island rows between them.
///
/// Most callers should use this type instead of deriving grid IDs or
/// coordinates themselves.
enum GridRoadTopology {

    // =====================================================
    // MARK: - Day Rows
    // =====================================================

    static let minimumIntersectionRow: Int = 0


    /// There is one more street intersection than there are island rows.
    ///
    /// 16 islands through the day => rows 0...16 => 17 horizontal streets.
    static var maximumIntersectionRow: Int {

        GridMapConfiguration.dayRowCount
    }


    static var intersectionRowRange: ClosedRange<Int> {

        minimumIntersectionRow ... maximumIntersectionRow
    }


    // =====================================================
    // MARK: - Semantic Pitch
    // =====================================================

    /// Progress represented by one street-centerline pitch.
    /// Current Cartesian design: 12.5 progress points.
    static var progressPerPitch: Double {

        Double(
            GridMapConfiguration
                .cellPitchMapUnits
        )
        * MapWorldConfiguration
            .progressPercentPerMapUnit
    }


    /// Time represented by one street-centerline pitch.
    /// Current Cartesian design: 1.5 hours.
    static var hoursPerPitch: Double {

        Double(
            GridMapConfiguration
                .cellPitchMapUnits
        )
        * MapWorldConfiguration
            .hoursPerMapUnit
    }


    // =====================================================
    // MARK: - Compatibility Materialization Range
    // =====================================================

    /// Existing route/domain APIs still accept a concrete `RoadGraph`.
    ///
    /// The underlying topology itself remains dynamic/unbounded in X, but
    /// while the rest of the app is migrated we materialize a modest window
    /// around the camera's normal exploration range.
    ///
    /// Eight extra columns = 100 progress points on either side with the
    /// current 12.5-point pitch.
    static let materializationBufferColumns: Int = 8


    static var defaultMaterializedColumnRange: ClosedRange<Int> {

        let pitch =
            max(
                progressPerPitch,
                0.000_001
            )

        let minimumBaseColumn =
            Int(
                floor(
                    MapWorldConfiguration
                        .minimumExplorableProgress
                    / pitch
                )
            )

        let maximumBaseColumn =
            Int(
                ceil(
                    MapWorldConfiguration
                        .maximumExplorableProgress
                    / pitch
                )
            )

        return
            (
                minimumBaseColumn
                - materializationBufferColumns
            )
            ...
            (
                maximumBaseColumn
                + materializationBufferColumns
            )
    }


    // =====================================================
    // MARK: - Validity
    // =====================================================

    static func isValid(
        _ id: GridIntersectionID
    ) -> Bool {

        intersectionRowRange
            .contains(
                id.row
            )
    }


    // =====================================================
    // MARK: - Deterministic IDs
    // =====================================================

    static func vertexID(
        for intersection: GridIntersectionID
    ) -> RoadVertexID {

        RoadVertexID(
            "grid.r\(formatted(intersection.row)).c\(formatted(intersection.column))"
        )
    }


    /// Converts the compatibility RoadVertexID back into grid coordinates.
    ///
    /// Existing IDs such as `grid.r06.c04` therefore continue to work.
    static func intersectionID(
        from vertexID: RoadVertexID
    ) -> GridIntersectionID? {

        let raw = vertexID.rawValue

        guard
            raw.hasPrefix("grid.r"),
            let columnMarker = raw.range(of: ".c")
        else {

            return nil
        }

        let rowStart =
            raw.index(
                raw.startIndex,
                offsetBy: "grid.r".count
            )

        let rowText =
            String(
                raw[
                    rowStart
                    ..<
                    columnMarker.lowerBound
                ]
            )

        let columnText =
            String(
                raw[
                    columnMarker.upperBound
                    ..<
                    raw.endIndex
                ]
            )

        guard
            let row = Int(rowText),
            let column = Int(columnText)
        else {

            return nil
        }

        let result =
            GridIntersectionID(
                column: column,
                row: row
            )

        guard isValid(result) else {
            return nil
        }

        return result
    }


    static func horizontalEdgeID(
        row: Int,
        leftColumn: Int
    ) -> RoadEdgeID {

        RoadEdgeID(
            "street.h.r\(formatted(row)).c\(formatted(leftColumn))-\(formatted(leftColumn + 1))"
        )
    }


    static func verticalEdgeID(
        column: Int,
        topRow: Int
    ) -> RoadEdgeID {

        RoadEdgeID(
            "street.v.c\(formatted(column)).r\(formatted(topRow))-\(formatted(topRow + 1))"
        )
    }


    // =====================================================
    // MARK: - Coordinates
    // =====================================================

    static func coordinate(
        for intersection: GridIntersectionID
    ) -> MapCoordinate {

        let progress =
            Double(intersection.column)
            * progressPerPitch

        let hours =
            Double(intersection.row)
            * hoursPerPitch

        return MapCoordinate(
            time:
                DayTime(
                    secondsFromMidnight:
                        hours
                        * DayTime.secondsPerHour
                ),
            progress:
                MapProgress(
                    progress
                )
        )
    }


    static func worldPoint(
        for intersection: GridIntersectionID
    ) -> WorldPoint {

        MapCoordinateConverter
            .worldPoint(
                for:
                    coordinate(
                        for: intersection
                    )
            )
    }


    // =====================================================
    // MARK: - Dynamic Neighbor Generation
    // =====================================================

    static func neighbor(
        of intersection: GridIntersectionID,
        direction: GridRoadDirection
    ) -> GridRoadNeighbor? {

        guard isValid(intersection) else {
            return nil
        }

        let destination: GridIntersectionID
        let edgeID: RoadEdgeID

        switch direction {

        case .left:

            destination =
                GridIntersectionID(
                    column:
                        intersection.column - 1,
                    row:
                        intersection.row
                )

            edgeID =
                horizontalEdgeID(
                    row:
                        intersection.row,
                    leftColumn:
                        intersection.column - 1
                )


        case .right:

            destination =
                GridIntersectionID(
                    column:
                        intersection.column + 1,
                    row:
                        intersection.row
                )

            edgeID =
                horizontalEdgeID(
                    row:
                        intersection.row,
                    leftColumn:
                        intersection.column
                )


        case .up:

            guard
                intersection.row
                > minimumIntersectionRow
            else {

                return nil
            }

            destination =
                GridIntersectionID(
                    column:
                        intersection.column,
                    row:
                        intersection.row - 1
                )

            edgeID =
                verticalEdgeID(
                    column:
                        intersection.column,
                    topRow:
                        intersection.row - 1
                )


        case .down:

            guard
                intersection.row
                < maximumIntersectionRow
            else {

                return nil
            }

            destination =
                GridIntersectionID(
                    column:
                        intersection.column,
                    row:
                        intersection.row + 1
                )

            edgeID =
                verticalEdgeID(
                    column:
                        intersection.column,
                    topRow:
                        intersection.row
                )
        }

        guard isValid(destination) else {
            return nil
        }

        return GridRoadNeighbor(
            direction:
                direction,
            intersection:
                destination,
            edgeID:
                edgeID
        )
    }


    static func neighbors(
        of intersection: GridIntersectionID
    ) -> [GridRoadNeighbor] {

        GridRoadDirection
            .allCases
            .compactMap { direction in

                neighbor(
                    of:
                        intersection,
                    direction:
                        direction
                )
            }
    }


    // =====================================================
    // MARK: - Step 5 Route Neighbors
    // =====================================================

    /// Directions a Fifoo route is allowed to travel.
    ///
    /// The physical street above an intersection still exists, but it is
    /// deliberately absent from route search because time may never move
    /// upward.
    static let allowedRouteDirections: [GridRoadDirection] = [
        .left,
        .right,
        .down
    ]


    static func routeNeighbors(
        of intersection: GridIntersectionID
    ) -> [GridRoadNeighbor] {

        allowedRouteDirections
            .compactMap { direction in

                neighbor(
                    of:
                        intersection,
                    direction:
                        direction
                )
            }
    }


    /// Returns the exact Cartesian direction from one adjacent grid
    /// intersection to another. Returns nil for non-adjacent points.
    static func direction(
        from source: GridIntersectionID,
        to destination: GridIntersectionID
    ) -> GridRoadDirection? {

        let deltaColumn =
            destination.column
            - source.column

        let deltaRow =
            destination.row
            - source.row

        switch (deltaColumn, deltaRow) {

        case (-1, 0):
            return .left

        case (1, 0):
            return .right

        case (0, -1):
            return .up

        case (0, 1):
            return .down

        default:
            return nil
        }
    }


    // =====================================================
    // MARK: - World-Space Helpers
    // =====================================================

    static func nearestColumn(
        toWorldX x: CGFloat
    ) -> Int {

        let pitch =
            GridMapConfiguration
                .cellPitchWorld

        guard pitch > 0 else {
            return 0
        }

        return Int(
            round(
                (
                    x
                    - GridMapGeometry.origin.x
                )
                / pitch
            )
        )
    }


    static func nearestRow(
        toWorldY y: CGFloat
    ) -> Int {

        let pitch =
            GridMapConfiguration
                .cellPitchWorld

        guard pitch > 0 else {
            return 0
        }

        return Int(
            round(
                (
                    GridMapGeometry.origin.y
                    - y
                )
                / pitch
            )
        )
    }


    static func nearestIntersection(
        to point: CGPoint
    ) -> GridIntersectionID? {

        let result =
            GridIntersectionID(
                column:
                    nearestColumn(
                        toWorldX:
                            point.x
                    ),
                row:
                    nearestRow(
                        toWorldY:
                            point.y
                    )
            )

        guard isValid(result) else {
            return nil
        }

        return result
    }


    // =====================================================
    // MARK: - Debug Validation
    // =====================================================

    static func debugAssertTopology(
        file: StaticString = #fileID,
        line: UInt = #line
    ) {

        let originIntersection =
            GridIntersectionID(
                column: 0,
                row: 0
            )

        let originPoint =
            worldPoint(
                for:
                    originIntersection
            )
            .cgPoint

        assert(
            abs(
                originPoint.x
                - GridMapGeometry
                    .verticalStreetCenterX(
                        column: 0
                    )
            ) < 0.001,
            "Grid road X topology must align with rendered street centerlines.",
            file: file,
            line: line
        )

        assert(
            abs(
                originPoint.y
                - GridMapGeometry
                    .horizontalStreetCenterY(
                        row: 0
                    )
            ) < 0.001,
            "Grid road Y topology must align with rendered street centerlines.",
            file: file,
            line: line
        )

        let oneDown =
            GridIntersectionID(
                column: 0,
                row: 1
            )

        let downPoint =
            worldPoint(
                for:
                    oneDown
            )
            .cgPoint

        assert(
            abs(
                abs(
                    downPoint.y
                    - originPoint.y
                )
                - GridMapConfiguration
                    .cellPitchWorld
            ) < 0.001,
            "Adjacent road intersections must be exactly one grid pitch apart.",
            file: file,
            line: line
        )

        assert(
            abs(hoursPerPitch - 1.5) < 0.000_1,
            "Cartesian topology expects 1.5 hours per pitch (4 islands per 6 hours).",
            file: file,
            line: line
        )

        assert(
            abs(progressPerPitch - 12.5) < 0.000_1,
            "Cartesian topology expects 12.5 progress points per pitch.",
            file: file,
            line: line
        )


        let middle =
            GridIntersectionID(
                column: 0,
                row: min(
                    8,
                    maximumIntersectionRow - 1
                )
            )

        let routeDirections =
            Set(
                routeNeighbors(
                    of: middle
                )
                .map(\.direction)
            )

        assert(
            routeDirections.contains(.left)
            && routeDirections.contains(.right)
            && routeDirections.contains(.down)
            && !routeDirections.contains(.up),
            "Fifoo path topology must expose left/right/down and never up.",
            file: file,
            line: line
        )
    }
}


// MARK: - Formatting

private extension GridRoadTopology {

    static func formatted(
        _ value: Int
    ) -> String {

        String(
            format: "%02d",
            value
        )
    }
}
