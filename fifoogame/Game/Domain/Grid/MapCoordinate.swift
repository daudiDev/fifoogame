//
//  MapCoordinate.swift
//  Fifoo
//
//  Cartesian coordinate foundation for the Fifoo Day Map.
//

import Foundation
import CoreGraphics


// MARK: - Day Time

/// Semantic time within one Fifoo day.
///
/// Time is the source of truth.
/// SpriteKit Y coordinates are derived from this value.
struct DayTime: Codable, Hashable, Comparable, Sendable {

    static let secondsPerDay: TimeInterval = 86_400
    static let secondsPerHour: TimeInterval = 3_600

    let secondsFromMidnight: TimeInterval

    init(secondsFromMidnight: TimeInterval) {

        self.secondsFromMidnight = min(
            max(secondsFromMidnight, 0),
            Self.secondsPerDay
        )
    }

    static func < (lhs: DayTime, rhs: DayTime) -> Bool {
        lhs.secondsFromMidnight < rhs.secondsFromMidnight
    }


    // MARK: Convenience

    static let startOfDay = DayTime(
        secondsFromMidnight: 0
    )

    static let noon = DayTime(
        secondsFromMidnight: 43_200
    )

    static let endOfDay = DayTime(
        secondsFromMidnight: 86_400
    )


    /// 0.0 = midnight
    /// 0.5 = noon
    /// 1.0 = end of day
    var fractionOfDay: Double {
        secondsFromMidnight / Self.secondsPerDay
    }


    /// Hours after midnight.
    ///
    /// Examples:
    /// 0.0  = 12:00 AM
    /// 6.5  = 6:30 AM
    /// 24.0 = end of day
    var hoursFromMidnight: Double {
        secondsFromMidnight / Self.secondsPerHour
    }


    /// Creates a Fifoo wall-clock time from a real Date.
    ///
    /// We intentionally use clock components instead of simply
    /// calculating elapsed seconds since midnight.
    static func from(
        date: Date,
        timeZone: TimeZone
    ) -> DayTime {

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone

        let components = calendar.dateComponents(
            [.hour, .minute, .second],
            from: date
        )

        let hour = components.hour ?? 0
        let minute = components.minute ?? 0
        let second = components.second ?? 0

        let totalSeconds =
            (hour * 3600)
            + (minute * 60)
            + second

        return DayTime(
            secondsFromMidnight: TimeInterval(totalSeconds)
        )
    }


    var debugClockString: String {

        let totalSeconds = Int(secondsFromMidnight)

        let hour = totalSeconds / 3600
        let minute = (totalSeconds % 3600) / 60

        if hour >= 24 {
            return "24:00"
        }

        return String(
            format: "%02d:%02d",
            hour,
            minute
        )
    }


    var displayClockString: String {

        let totalSeconds =
            Int(secondsFromMidnight)

        let hour24 =
            min(
                totalSeconds / 3600,
                23
            )

        let minute =
            (totalSeconds % 3600) / 60


        let period =
            hour24 < 12
            ? "AM"
            : "PM"


        let convertedHour =
            hour24 % 12


        let hour12 =
            convertedHour == 0
            ? 12
            : convertedHour


        return String(
            format:
                "%d:%02d %@",
            hour12,
            minute,
            period
        )
    }
}


// MARK: - Progress

/// Fifoo's horizontal progress value.
///
/// Important:
/// This is NOT clamped to 0...100 at the domain level.
///
/// That lets the world continue naturally into negative progress
/// and progress above 100%.
struct MapProgress: Codable, Hashable, Sendable {

    var percent: Double

    init(_ percent: Double) {
        self.percent = percent
    }
}


// MARK: - Semantic Map Coordinate

/// A location in the Fifoo world described by GAME meaning,
/// rather than SpriteKit pixels.
struct MapCoordinate: Codable, Hashable, Sendable {

    var time: DayTime
    var progress: MapProgress

    init(
        time: DayTime,
        progress: MapProgress
    ) {

        self.time = time
        self.progress = progress
    }
}


// MARK: - World Point

/// Renderer-independent representation of an X/Y world position.
///
/// We intentionally do not persist CGPoint in game state.
struct WorldPoint: Codable, Hashable, Sendable {

    var x: Double
    var y: Double

    init(
        x: Double,
        y: Double
    ) {

        self.x = x
        self.y = y
    }

    var cgPoint: CGPoint {

        CGPoint(
            x: x,
            y: y
        )
    }
}


// MARK: - Fifoo World Configuration

/// Defines the permanent geometry of the semantic Fifoo map.
///
/// The key rule for the redesigned map is:
///
///     1 progress percentage point == 0.12 hour
///
/// in rendered world distance.
///
/// Therefore one map unit means either:
///
///     1 progress percentage point horizontally
///
/// or:
///
///     0.12 hour / 7.2 minutes vertically.
///
/// This gives the map a true Cartesian scale and lets a 6 x 6
/// grid island render as an actual square.
enum MapWorldConfiguration {

    // =====================================================
    // MARK: - Cartesian Scale
    // =====================================================

    /// Semantic time represented by one vertical map unit.
    static let hoursPerMapUnit: Double = 0.12

    /// One horizontal map unit equals exactly one progress point.
    static let progressPercentPerMapUnit: Double = 1.0

    /// SpriteKit world-space size of one map unit.
    ///
    /// 10 points keeps the existing 0...100% width at 1000 points.
    static let worldPointsPerMapUnit: CGFloat = 10


    /// 7.2 minutes per map unit.
    static var minutesPerMapUnit: Double {
        hoursPerMapUnit * 60
    }


    /// Number of map units contained in one hour.
    static var mapUnitsPerHour: Double {
        1 / hoursPerMapUnit
    }


    /// World-space points for one hour of vertical time.
    static var worldPointsPerHour: CGFloat {

        worldPointsPerMapUnit
        * CGFloat(mapUnitsPerHour)
    }


    /// World-space points for one progress percentage point.
    static var worldPointsPerProgressPercent: CGFloat {

        worldPointsPerMapUnit
        / CGFloat(progressPercentPerMapUnit)
    }


    // =====================================================
    // MARK: - Reference Progress
    // =====================================================

    static let minimumReferenceProgress:
        Double = 0

    static let maximumReferenceProgress:
        Double = 100


    static var referenceProgressRange:
        Double {

        maximumReferenceProgress
        - minimumReferenceProgress
    }


    // =====================================================
    // MARK: - Derived Reference World Size
    // =====================================================

    /// Width occupied by the normal 0...100% progress range.
    ///
    /// 100 progress points * 10 world points = 1000.
    static var width: CGFloat {

        CGFloat(
            referenceProgressRange
            / progressPercentPerMapUnit
        )
        * worldPointsPerMapUnit
    }


    /// Full 24-hour height using the Cartesian scale.
    ///
    /// 24 hours / 0.12 hour per unit = 200 map units.
    /// 200 * 10 world points = 2000.
    static var height: CGFloat {

        CGFloat(
            24 / hoursPerMapUnit
        )
        * worldPointsPerMapUnit
    }


    static var sceneSize: CGSize {

        CGSize(
            width: width,
            height: height
        )
    }


    // =====================================================
    // MARK: - Camera Exploration Range
    // =====================================================

    /*
     IMPORTANT:

     These are CAMERA / PRESENTATION limits.

     They are NOT domain limits.

     MapProgress itself remains capable of values such as:

         -100%
         200%
         etc.
    */

    static let minimumExplorableProgress:
        Double = -50

    static let maximumExplorableProgress:
        Double = 150


    // =====================================================
    // MARK: - Derived Camera X Bounds
    // =====================================================

    static var minimumExplorableX:
        CGFloat {

        CGFloat(
            minimumExplorableProgress
            - minimumReferenceProgress
        )
        * worldPointsPerProgressPercent
    }


    static var maximumExplorableX:
        CGFloat {

        CGFloat(
            maximumExplorableProgress
            - minimumReferenceProgress
        )
        * worldPointsPerProgressPercent
    }


    static var explorableWorldWidth:
        CGFloat {

        maximumExplorableX
        - minimumExplorableX
    }


    static var explorableWorldCenterX:
        CGFloat {

        (
            minimumExplorableX
            + maximumExplorableX
        )
        / 2
    }
}


// MARK: - Coordinate Converter

/// The single authoritative conversion layer between Fifoo semantic
/// coordinates and SpriteKit world coordinates.
///
/// Do not duplicate time/progress-to-world calculations in renderers.
enum MapCoordinateConverter {

    // =====================================================
    // MARK: - Semantic -> World
    // =====================================================

    /// Converts one progress percentage value into world X.
    ///
    /// Examples with the current scale:
    ///
    /// -50% -> -500
    ///   0%  ->    0
    ///  50%  ->  500
    /// 100%  -> 1000
    /// 150%  -> 1500
    static func worldX(
        forProgress progress: Double
    ) -> CGFloat {

        CGFloat(
            progress
            - MapWorldConfiguration.minimumReferenceProgress
        )
        * MapWorldConfiguration.worldPointsPerProgressPercent
    }


    /// Converts Fifoo day time into world Y.
    ///
    /// Time moves DOWN the map, so world Y becomes more negative
    /// as the day advances.
    static func worldY(
        for time: DayTime
    ) -> CGFloat {

        -CGFloat(
            time.hoursFromMidnight
        )
        * MapWorldConfiguration.worldPointsPerHour
    }


    /// Converts Fifoo semantic coordinates into the permanent
    /// SpriteKit world coordinate system.
    static func worldPoint(
        for coordinate: MapCoordinate
    ) -> WorldPoint {

        let x =
            worldX(
                forProgress:
                    coordinate.progress.percent
            )

        let y =
            worldY(
                for:
                    coordinate.time
            )


        return WorldPoint(
            x: Double(x),
            y: Double(y)
        )
    }


    // =====================================================
    // MARK: - World -> Semantic
    // =====================================================

    static func progress(
        forWorldX x: CGFloat
    ) -> MapProgress {

        let pointsPerPercent =
            MapWorldConfiguration
                .worldPointsPerProgressPercent


        guard pointsPerPercent != 0 else {

            return MapProgress(
                MapWorldConfiguration
                    .minimumReferenceProgress
            )
        }


        let progress =
            MapWorldConfiguration
                .minimumReferenceProgress
            + Double(
                x / pointsPerPercent
            )


        return MapProgress(
            progress
        )
    }


    static func dayTime(
        forWorldY y: CGFloat
    ) -> DayTime {

        let pointsPerHour =
            MapWorldConfiguration
                .worldPointsPerHour


        guard pointsPerHour != 0 else {

            return .startOfDay
        }


        let hoursFromMidnight =
            Double(
                -y / pointsPerHour
            )


        let seconds =
            hoursFromMidnight
            * DayTime.secondsPerHour


        return DayTime(
            secondsFromMidnight:
                seconds
        )
    }


    /// Inverse world -> semantic coordinate conversion.
    static func mapCoordinate(
        for worldPoint: WorldPoint
    ) -> MapCoordinate {

        MapCoordinate(
            time:
                dayTime(
                    forWorldY:
                        CGFloat(worldPoint.y)
                ),
            progress:
                progress(
                    forWorldX:
                        CGFloat(worldPoint.x)
                )
        )
    }


    // =====================================================
    // MARK: - Debug Validation
    // =====================================================

    /// Confirms the core redesign invariant:
    ///
    ///     1 progress point == 0.12 hour
    ///
    /// in SpriteKit world distance.
    ///
    /// This only needs to be called from DEBUG builds.
    static func debugAssertCartesianScale(
        file: StaticString = #fileID,
        line: UInt = #line
    ) {

        let start =
            worldPoint(
                for:
                    MapCoordinate(
                        time: .startOfDay,
                        progress: MapProgress(0)
                    )
            )


        let oneProgressPoint =
            worldPoint(
                for:
                    MapCoordinate(
                        time: .startOfDay,
                        progress: MapProgress(1)
                    )
            )


        let pointTwelveHour =
            worldPoint(
                for:
                    MapCoordinate(
                        time:
                            DayTime(
                                secondsFromMidnight:
                                    0.12
                                    * DayTime.secondsPerHour
                            ),
                        progress: MapProgress(0)
                    )
            )


        let horizontalDistance =
            abs(
                oneProgressPoint.x
                - start.x
            )


        let verticalDistance =
            abs(
                pointTwelveHour.y
                - start.y
            )


        assert(
            abs(
                horizontalDistance
                - verticalDistance
            ) < 0.000_1,
            "Fifoo map Cartesian scale is invalid: 1 progress point must equal 0.12 hour in world distance.",
            file: file,
            line: line
        )
    }
}
