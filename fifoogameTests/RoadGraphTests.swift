//
//  RoadGraphTests.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/18/26.
//


//
//  RoadGraphTests.swift
//  FifooTests
//

import XCTest
@testable import fifoogame


final class RoadGraphTests:
    XCTestCase {

    // MARK: - Sample

    func testSampleGraphIsValid() {

        let graph =
            SampleRoadGraph.make()


        let result =
            RoadGraphValidator
                .validate(
                    graph
                )


        XCTAssertTrue(
            result.isValid,
            result.issues
                .map(\.message)
                .joined(
                    separator:
                        "\n"
                )
        )
    }


    // MARK: - Determinism

    func testSampleGraphUsesStableIDs() {

        let first =
            SampleRoadGraph.make()


        let second =
            SampleRoadGraph.make()


        XCTAssertEqual(
            first.id,
            second.id
        )


        XCTAssertEqual(
            first.vertices.map(\.id),
            second.vertices.map(\.id)
        )


        XCTAssertEqual(
            first.edges.map(\.id),
            second.edges.map(\.id)
        )
    }


    // MARK: - Cul-de-sac

    func testCulDeSacHasDegreeOne() {

        let graph =
            SampleRoadGraph.make()


        guard
            let culEnd =
                graph.vertices
                    .first(
                        where: {

                            $0.kind ==
                                .culDeSacEnd
                        }
                    )
        else {

            XCTFail(
                "Missing cul-de-sac endpoint."
            )

            return
        }


        XCTAssertEqual(
            graph.degree(
                of:
                    culEnd.id
            ),
            1
        )
    }


    // MARK: - Roundabout

    func testRoundaboutContainsCycle() {

        let graph =
            SampleRoadGraph.make()


        let circleEdges =
            graph.edges.filter {

                $0.roadClass ==
                    .circle
            }


        XCTAssertEqual(
            circleEdges.count,
            4
        )


        let result =
            RoadGraphValidator
                .validate(
                    graph
                )


        let circleErrors =
            result.errors.filter {

                $0.code ==
                    .invalidCircle
            }


        XCTAssertTrue(
            circleErrors.isEmpty
        )
    }


    // MARK: - Connections

    func testOutgoingConnectionsExist() {

        let graph =
            SampleRoadGraph.make()


        let vertex =
            RoadVertexID(
                "main.b"
            )


        let connections =
            graph.outgoingConnections(
                from:
                    vertex
            )


        XCTAssertFalse(
            connections.isEmpty
        )
    }


    // MARK: - Missing Endpoint

    func testMissingVertexIsRejected() {

        let graph =
            RoadGraph(
                id:
                    RoadGraphID(
                        "invalid"
                    ),
                version:
                    1,
                vertices: [

                    RoadVertex(
                        id:
                            RoadVertexID(
                                "a"
                            ),
                        coordinate:
                            MapCoordinate(
                                time:
                                    .noon,
                                progress:
                                    MapProgress(
                                        50
                                    )
                            ),
                        kind:
                            .junction
                    )
                ],
                edges: [

                    RoadEdge(
                        id:
                            RoadEdgeID(
                                "a-missing"
                            ),
                        fromID:
                            RoadVertexID(
                                "a"
                            ),
                        toID:
                            RoadVertexID(
                                "missing"
                            ),
                        roadClass:
                            .local
                    )
                ]
            )


        let result =
            RoadGraphValidator
                .validate(
                    graph
                )


        XCTAssertFalse(
            result.isValid
        )


        XCTAssertTrue(
            result.errors
                .contains {

                    $0.code ==
                        .missingToVertex
                }
        )
    }


    // MARK: - Invalid Cul-de-sac

    func testInvalidCulDeSacIsRejected() {

        let endpoint =
            RoadVertex(
                id:
                    RoadVertexID(
                        "dead-end"
                    ),
                coordinate:
                    MapCoordinate(
                        time:
                            .noon,
                        progress:
                            MapProgress(
                                50
                            )
                    ),
                kind:
                    .culDeSacEnd
            )


        let graph =
            RoadGraph(
                id:
                    RoadGraphID(
                        "bad-cul"
                    ),
                version:
                    1,
                vertices: [
                    endpoint
                ],
                edges: []
            )


        let result =
            RoadGraphValidator
                .validate(
                    graph
                )


        XCTAssertTrue(
            result.errors
                .contains {

                    $0.code ==
                        .invalidCulDeSacDegree
                }
        )
    }
    
    // MARK: - Dense City

    func testDenseCityGraphIsValid() {

        let graph =
            DenseCityRoadGraph.make()


        let result =
            RoadGraphValidator
                .validate(
                    graph
                )


        XCTAssertTrue(
            result.isValid,
            result.errors
                .map(\.message)
                .joined(
                    separator: "\n"
                )
        )
    }


    func testDenseCityIsDeterministic() {

        let first =
            DenseCityRoadGraph.make()


        let second =
            DenseCityRoadGraph.make()


        XCTAssertEqual(
            first.id,
            second.id
        )


        XCTAssertEqual(
            first.vertices,
            second.vertices
        )


        XCTAssertEqual(
            first.edges,
            second.edges
        )
    }


    func testDenseCityIsActuallyDense() {

        let graph =
            DenseCityRoadGraph.make()


        XCTAssertGreaterThanOrEqual(
            graph.vertices.count,
            140
        )


        XCTAssertGreaterThanOrEqual(
            graph.edges.count,
            250
        )
    }


    func testDenseCityContainsMultipleRoundabouts() {

        let graph =
            DenseCityRoadGraph.make()


        let circleEdges =
            graph.edges.filter {

                $0.roadClass ==
                    .circle
            }


        /*
         3 roundabouts × 8 ring edges.
         */

        XCTAssertEqual(
            circleEdges.count,
            24
        )
    }


    func testDenseCityContainsMultipleCulDeSacs() {

        let graph =
            DenseCityRoadGraph.make()


        let endpoints =
            graph.vertices.filter {

                $0.kind ==
                    .culDeSacEnd
            }


        XCTAssertEqual(
            endpoints.count,
            8
        )


        for endpoint in endpoints {

            XCTAssertEqual(
                graph.degree(
                    of:
                        endpoint.id
                ),
                1
            )
        }
    }


    func testDenseCityContainsNegativeProgress() {

        let graph =
            DenseCityRoadGraph.make()


        XCTAssertTrue(
            graph.vertices.contains {

                $0.coordinate
                    .progress
                    .percent < 0
            }
        )
    }


    func testDenseCityContainsProgressAbove100() {

        let graph =
            DenseCityRoadGraph.make()


        XCTAssertTrue(
            graph.vertices.contains {

                $0.coordinate
                    .progress
                    .percent > 100
            }
        )
    }


    func testDenseCityHasNoDisconnectedWarning() {

        let graph =
            DenseCityRoadGraph.make()


        let result =
            RoadGraphValidator
                .validate(
                    graph
                )


        XCTAssertFalse(
            result.warnings.contains {

                $0.code ==
                    .disconnectedGraph
            }
        )
    }


    func testDenseCityDoesNotUseGradeSeparatedRoads() {

        let graph =
            DenseCityRoadGraph.make()


        XCTAssertFalse(
            graph.edges.contains {

                $0.attributes
                    .isGradeSeparated
            }
        )
    }
    
    func testDenseCityHasNoRoadCrossingsWithoutIntersections() {

        let graph =
            DenseCityRoadGraph.make()


        let issues =
            RoadGeometryValidator
                .crossingsWithoutSharedVertex(
                    in: graph
                )


        XCTAssertTrue(
            issues.isEmpty,
            issues
                .map(\.description)
                .joined(
                    separator: "\n"
                )
        )
    }
}
