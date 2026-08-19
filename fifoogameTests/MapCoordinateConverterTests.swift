//
//  MapCoordinateConverterTests.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/18/26.
//

import XCTest
@testable import fifoogame


final class MapCoordinateConverterTests:
    XCTestCase {

    // MARK: - Midnight

    func testMidnightAtZeroProgress() {

        let coordinate =
            MapCoordinate(
                time: .startOfDay,
                progress:
                    MapProgress(0)
            )

        let point =
            MapCoordinateConverter
                .worldPoint(
                    for: coordinate
                )

        XCTAssertEqual(
            point.x,
            0,
            accuracy: 0.001
        )

        XCTAssertEqual(
            point.y,
            0,
            accuracy: 0.001
        )
    }


    // MARK: - Noon

    func testNoonAtFiftyPercent() {

        let coordinate =
            MapCoordinate(
                time: .noon,
                progress:
                    MapProgress(50)
            )

        let point =
            MapCoordinateConverter
                .worldPoint(
                    for: coordinate
                )

        XCTAssertEqual(
            point.x,
            500,
            accuracy: 0.001
        )

        XCTAssertEqual(
            point.y,
            -1200,
            accuracy: 0.001
        )
    }


    // MARK: - End Of Day

    func testEndOfDayAtOneHundredPercent() {

        let coordinate =
            MapCoordinate(
                time: .endOfDay,
                progress:
                    MapProgress(100)
            )

        let point =
            MapCoordinateConverter
                .worldPoint(
                    for: coordinate
                )

        XCTAssertEqual(
            point.x,
            1000,
            accuracy: 0.001
        )

        XCTAssertEqual(
            point.y,
            -2400,
            accuracy: 0.001
        )
    }


    // MARK: - Above 100%

    func testProgressMayExceedOneHundred() {

        let coordinate =
            MapCoordinate(
                time: .noon,
                progress:
                    MapProgress(125)
            )

        let point =
            MapCoordinateConverter
                .worldPoint(
                    for: coordinate
                )

        XCTAssertEqual(
            point.x,
            1250,
            accuracy: 0.001
        )
    }


    // MARK: - Negative Progress

    func testProgressMayBeNegative() {

        let coordinate =
            MapCoordinate(
                time: .noon,
                progress:
                    MapProgress(-20)
            )

        let point =
            MapCoordinateConverter
                .worldPoint(
                    for: coordinate
                )

        XCTAssertEqual(
            point.x,
            -200,
            accuracy: 0.001
        )
    }


    // MARK: - Round Trip

    func testCoordinateRoundTrip() {

        let original =
            MapCoordinate(
                time:
                    DayTime(
                        secondsFromMidnight:
                            17.5 * 3600
                    ),
                progress:
                    MapProgress(72.5)
            )

        let world =
            MapCoordinateConverter
                .worldPoint(
                    for: original
                )

        let reconstructed =
            MapCoordinateConverter
                .mapCoordinate(
                    for: world
                )


        XCTAssertEqual(
            reconstructed
                .progress
                .percent,
            72.5,
            accuracy: 0.001
        )


        XCTAssertEqual(
            reconstructed
                .time
                .secondsFromMidnight,
            17.5 * 3600,
            accuracy: 0.001
        )
    }
}
