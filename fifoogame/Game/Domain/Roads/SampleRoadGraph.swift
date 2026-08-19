//
//  SampleRoadGraph.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/18/26.
//

import Foundation

enum SampleRoadGraph {

    // MARK: - Vertex IDs

    private static let a =
        RoadVertexID("main.a")

    private static let b =
        RoadVertexID("main.b")

    private static let c =
        RoadVertexID("main.c")

    private static let d =
        RoadVertexID("main.d")

    private static let e =
        RoadVertexID("main.e")

    private static let f =
        RoadVertexID("main.f")

    private static let g =
        RoadVertexID("main.g")


    // MARK: - Cul-de-sac IDs

    private static let culJunction =
        RoadVertexID("cul.junction")

    private static let culEnd =
        RoadVertexID("cul.end")


    // MARK: - Roundabout IDs

    private static let circleNorth =
        RoadVertexID("circle.north")

    private static let circleEast =
        RoadVertexID("circle.east")

    private static let circleSouth =
        RoadVertexID("circle.south")

    private static let circleWest =
        RoadVertexID("circle.west")


    // MARK: - Public Graph Factory

    static func make() -> RoadGraph {

        RoadGraph(
            id:
                RoadGraphID(
                    "fifoo.sample.city"
                ),
            version:
                1,
            vertices:
                makeVertices(),
            edges:
                makeEdges()
        )
    }
}


// MARK: - Vertices

private extension SampleRoadGraph {

    static func makeVertices() -> [RoadVertex] {

        [

            // MARK: Main network

            RoadVertex(
                id: a,
                coordinate:
                    coordinate(
                        hour: 1,
                        progress: 35
                    ),
                kind:
                    .junction
            ),


            RoadVertex(
                id: b,
                coordinate:
                    coordinate(
                        hour: 4,
                        progress: 42
                    ),
                kind:
                    .intersection
            ),


            RoadVertex(
                id: c,
                coordinate:
                    coordinate(
                        hour: 7,
                        progress: 36
                    ),
                kind:
                    .intersection
            ),


            RoadVertex(
                id: d,
                coordinate:
                    coordinate(
                        hour: 10,
                        progress: 50
                    ),
                kind:
                    .intersection
            ),


            RoadVertex(
                id: e,
                coordinate:
                    coordinate(
                        hour: 14,
                        progress: 44
                    ),
                kind:
                    .intersection
            ),


            RoadVertex(
                id: f,
                coordinate:
                    coordinate(
                        hour: 18,
                        progress: 60
                    ),
                kind:
                    .intersection
            ),


            RoadVertex(
                id: g,
                coordinate:
                    coordinate(
                        hour: 23,
                        progress: 68
                    ),
                kind:
                    .junction
            ),


            // MARK: Cul-de-sac branch

            RoadVertex(
                id:
                    culJunction,
                coordinate:
                    coordinate(
                        hour: 9,
                        progress: 10
                    ),
                kind:
                    .junction
            ),


            RoadVertex(
                id:
                    culEnd,
                coordinate:
                    coordinate(
                        hour: 11,
                        progress: -10
                    ),
                kind:
                    .culDeSacEnd
            ),


            // MARK: Roundabout

            RoadVertex(
                id:
                    circleNorth,
                coordinate:
                    coordinate(
                        hour: 12.6,
                        progress: 82
                    ),
                kind:
                    .circleEntry
            ),


            RoadVertex(
                id:
                    circleEast,
                coordinate:
                    coordinate(
                        hour: 13.2,
                        progress: 90
                    ),
                kind:
                    .junction
            ),


            RoadVertex(
                id:
                    circleSouth,
                coordinate:
                    coordinate(
                        hour: 13.8,
                        progress: 82
                    ),
                kind:
                    .circleExit
            ),


            RoadVertex(
                id:
                    circleWest,
                coordinate:
                    coordinate(
                        hour: 13.2,
                        progress: 74
                    ),
                kind:
                    .junction
            )
        ]
    }
}


// MARK: - Edges

private extension SampleRoadGraph {

    static func makeEdges() -> [RoadEdge] {

        [

            // =====================================================
            // Main Road
            // =====================================================

            RoadEdge(
                id:
                    RoadEdgeID(
                        "main.a-b"
                    ),
                fromID:
                    a,
                toID:
                    b,
                roadClass:
                    .local
            ),


            RoadEdge(
                id:
                    RoadEdgeID(
                        "main.b-c"
                    ),
                fromID:
                    b,
                toID:
                    c,
                roadClass:
                    .arterial
            ),


            RoadEdge(
                id:
                    RoadEdgeID(
                        "main.c-d"
                    ),
                fromID:
                    c,
                toID:
                    d,
                roadClass:
                    .arterial
            ),


            RoadEdge(
                id:
                    RoadEdgeID(
                        "main.d-e"
                    ),
                fromID:
                    d,
                toID:
                    e,
                roadClass:
                    .arterial
            ),


            RoadEdge(
                id:
                    RoadEdgeID(
                        "main.e-f"
                    ),
                fromID:
                    e,
                toID:
                    f,
                roadClass:
                    .arterial
            ),


            RoadEdge(
                id:
                    RoadEdgeID(
                        "main.f-g"
                    ),
                fromID:
                    f,
                toID:
                    g,
                roadClass:
                    .local
            ),


            // =====================================================
            // Highway Alternative
            // =====================================================

            RoadEdge(
                id:
                    RoadEdgeID(
                        "highway.b-e"
                    ),
                fromID:
                    b,
                toID:
                    e,
                roadClass:
                    .highway,
                travelDirection:
                    .bidirectional,
                shape:
                    .polyline(
                        intermediatePoints: [

                            worldPoint(
                                hour: 7,
                                progress: 65
                            ),

                            worldPoint(
                                hour: 11,
                                progress: 68
                            )
                        ]
                    ),
                attributes:
                    RoadAttributes(
                        displayName:
                            "Expressway",
                        routingCostMultiplier:
                            0.75,
                        tags: [
                            "sample",
                            "express"
                        ]
                    )
            ),


            // =====================================================
            // Cul-de-sac
            // =====================================================

            RoadEdge(
                id:
                    RoadEdgeID(
                        "cul.c-junction"
                    ),
                fromID:
                    c,
                toID:
                    culJunction,
                roadClass:
                    .connector
            ),


            RoadEdge(
                id:
                    RoadEdgeID(
                        "cul.junction-end"
                    ),
                fromID:
                    culJunction,
                toID:
                    culEnd,
                roadClass:
                    .culDeSac
            ),


            // =====================================================
            // Roundabout Entry
            // =====================================================

            RoadEdge(
                id:
                    RoadEdgeID(
                        "circle.entry"
                    ),
                fromID:
                    d,
                toID:
                    circleNorth,
                roadClass:
                    .connector
            ),


            // =====================================================
            // Roundabout Cycle
            // =====================================================

            RoadEdge(
                id:
                    RoadEdgeID(
                        "circle.north-east"
                    ),
                fromID:
                    circleNorth,
                toID:
                    circleEast,
                roadClass:
                    .circle
            ),


            RoadEdge(
                id:
                    RoadEdgeID(
                        "circle.east-south"
                    ),
                fromID:
                    circleEast,
                toID:
                    circleSouth,
                roadClass:
                    .circle
            ),


            RoadEdge(
                id:
                    RoadEdgeID(
                        "circle.south-west"
                    ),
                fromID:
                    circleSouth,
                toID:
                    circleWest,
                roadClass:
                    .circle
            ),


            RoadEdge(
                id:
                    RoadEdgeID(
                        "circle.west-north"
                    ),
                fromID:
                    circleWest,
                toID:
                    circleNorth,
                roadClass:
                    .circle
            ),


            // =====================================================
            // Roundabout Exit
            // =====================================================

            RoadEdge(
                id:
                    RoadEdgeID(
                        "circle.exit"
                    ),
                fromID:
                    circleSouth,
                toID:
                    f,
                roadClass:
                    .connector
            )
        ]
    }
}


// MARK: - Coordinate Helpers

private extension SampleRoadGraph {

    static func coordinate(
        hour: Double,
        progress: Double
    ) -> MapCoordinate {

        MapCoordinate(
            time:
                DayTime(
                    secondsFromMidnight:
                        hour * 3600
                ),
            progress:
                MapProgress(
                    progress
                )
        )
    }


    static func worldPoint(
        hour: Double,
        progress: Double
    ) -> WorldPoint {

        MapCoordinateConverter
            .worldPoint(
                for:
                    coordinate(
                        hour:
                            hour,
                        progress:
                            progress
                    )
            )
    }
}
