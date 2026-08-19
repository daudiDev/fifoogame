//
//  RoadHitTesterTests.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/19/26.
//


import XCTest

@testable import fifoogame


final class RoadHitTesterTests:
    XCTestCase {

    func testStraightRoadCanBeHit() {

        let a =
            RoadVertex(
                id:
                    RoadVertexID(
                        "a"
                    ),
                coordinate:
                    MapCoordinate(
                        time:
                            DayTime(
                                secondsFromMidnight:
                                    6 * 3600
                            ),
                        progress:
                            MapProgress(
                                20
                            )
                    ),
                kind:
                    .junction
            )


        let b =
            RoadVertex(
                id:
                    RoadVertexID(
                        "b"
                    ),
                coordinate:
                    MapCoordinate(
                        time:
                            DayTime(
                                secondsFromMidnight:
                                    6 * 3600
                            ),
                        progress:
                            MapProgress(
                                80
                            )
                    ),
                kind:
                    .junction
            )


        let edge =
            RoadEdge(
                id:
                    RoadEdgeID(
                        "a-b"
                    ),
                fromID:
                    a.id,
                toID:
                    b.id,
                roadClass:
                    .local
            )


        let graph =
            RoadGraph(
                id:
                    RoadGraphID(
                        "test"
                    ),
                version:
                    1,
                vertices: [
                    a,
                    b
                ],
                edges: [
                    edge
                ]
            )


        let midpoint =
            MapCoordinateConverter
                .worldPoint(
                    for:
                        MapCoordinate(
                            time:
                                DayTime(
                                    secondsFromMidnight:
                                        6 * 3600
                                ),
                            progress:
                                MapProgress(
                                    50
                                )
                        )
                )
                .cgPoint


        let hit =
            RoadHitTester()
                .hitTest(
                    at:
                        midpoint,
                    graph:
                        graph,
                    tolerance:
                        10
                )


        XCTAssertEqual(
            hit,
            .edge(
                edge.id
            )
        )
    }
}
