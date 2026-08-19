//
//  DayTime.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/18/26.
//


//
//  MapCoordinate.swift
//  Fifoo
//

import Foundation
import CoreGraphics


// MARK: - Day Time

/// Semantic time within one Fifoo day.
///
/// Time is the source of truth.
/// SpriteKit Y coordinates will be DERIVED from this value.
struct DayTime: Codable, Hashable, Comparable, Sendable {

    static let secondsPerDay: TimeInterval = 86_400

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
/// That gives us room later to support values below 0 or above
/// 100 without redesigning the model.
struct MapProgress: Codable, Hashable, Sendable {

    var percent: Double

    init(_ percent: Double) {
        self.percent = percent
    }
}


// MARK: - Semantic Map Coordinate

/// A location in the Fifoo world described by GAME meaning,
/// rather than pixels.
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
/// We intentionally do not store CGPoint in persisted game state.
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
enum MapWorldConfiguration {

    // MARK: Reference World

    /// Width occupied by the normal 0...100%
    /// progress range.
    static let width: CGFloat = 1000

    /// Full 24-hour day height.
    static let height: CGFloat = 2400


    static let sceneSize = CGSize(
        width: width,
        height: height
    )


    // MARK: Reference Progress

    static let minimumReferenceProgress:
        Double = 0

    static let maximumReferenceProgress:
        Double = 100


    static var referenceProgressRange:
        Double {

        maximumReferenceProgress
        - minimumReferenceProgress
    }


    // MARK: Camera Exploration Range

    /*
     IMPORTANT:

     These are CAMERA / PRESENTATION limits.

     They are NOT domain limits.

     MapProgress itself remains capable of:

         -100%
         200%
         etc.
     */

    static let minimumExplorableProgress:
        Double = -50

    static let maximumExplorableProgress:
        Double = 150


    // MARK: Derived World X Bounds

    static var minimumExplorableX:
        CGFloat {

        width
        * CGFloat(
            (
                minimumExplorableProgress
                - minimumReferenceProgress
            )
            / referenceProgressRange
        )
    }


    static var maximumExplorableX:
        CGFloat {

        width
        * CGFloat(
            (
                maximumExplorableProgress
                - minimumReferenceProgress
            )
            / referenceProgressRange
        )
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

enum MapCoordinateConverter {

    /// Fifoo uses:
    ///
    ///     12 AM
    ///       ↓
    ///       ↓ time
    ///       ↓
    ///     End of day
    ///
    /// SpriteKit normally increases Y upward.
    ///
    /// We therefore use:
    ///
    /// top    = y 0
    /// bottom = y -2400
    ///
    static func worldPoint(
        for coordinate: MapCoordinate
    ) -> WorldPoint {

        let progressRange =
            MapWorldConfiguration.maximumReferenceProgress
            - MapWorldConfiguration.minimumReferenceProgress

        let progressFraction =
            (
                coordinate.progress.percent
                - MapWorldConfiguration.minimumReferenceProgress
            )
            / progressRange

        let x =
            Double(MapWorldConfiguration.width)
            * progressFraction

        let y =
            -Double(MapWorldConfiguration.height)
            * coordinate.time.fractionOfDay

        return WorldPoint(
            x: x,
            y: y
        )
    }


    /// Inverse conversion.
    ///
    /// Primarily useful for:
    /// - touches
    /// - debugging
    /// - map editing
    /// - future drag interactions
    static func mapCoordinate(
        for worldPoint: WorldPoint
    ) -> MapCoordinate {

        let progressFraction =
            worldPoint.x
            / Double(MapWorldConfiguration.width)

        let progressRange =
            MapWorldConfiguration.maximumReferenceProgress
            - MapWorldConfiguration.minimumReferenceProgress

        let progress =
            MapWorldConfiguration.minimumReferenceProgress
            + progressFraction * progressRange

        let dayFraction =
            -worldPoint.y
            / Double(MapWorldConfiguration.height)

        let seconds =
            dayFraction
            * DayTime.secondsPerDay

        return MapCoordinate(
            time: DayTime(
                secondsFromMidnight: seconds
            ),
            progress: MapProgress(progress)
        )
    }
}
