//
//  DenseCityRoadGraph 2.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/19/26.
//


//
//  DenseCityRoadGraph.swift
//  Fifoo
//

import Foundation


enum DenseCityRoadGraph {

    // MARK: - Grid

    private static let rowHours: [Double] = [
        0.75,
        3.00,
        5.25,
        7.50,
        9.75,
        12.00,
        14.25,
        16.50,
        18.75,
        21.00,
        23.25
    ]


    private static let columnProgress: [Double] = [
        -40,
        -20,
        0,
        20,
        40,
        60,
        80,
        100,
        120,
        140
    ]


    // MARK: - Roundabouts

    private struct RoundaboutAnchor {

        let name: String

        let row: Int

        let column: Int
    }


    private static let roundaboutAnchors: [RoundaboutAnchor] = [

        RoundaboutAnchor(
            name: "morning",
            row: 3,
            column: 3
        ),

        RoundaboutAnchor(
            name: "afternoon",
            row: 6,
            column: 7
        ),

        RoundaboutAnchor(
            name: "evening",
            row: 8,
            column: 2
        )
    ]


    // MARK: - Make

    static func make() -> RoadGraph {

        var vertices:
            [RoadVertex] = []

        var edges:
            [RoadEdge] = []


        appendGridVertices(
            to: &vertices
        )


        appendStreetEdges(
            to: &edges
        )


        appendRoundabouts(
            vertices: &vertices,
            edges: &edges
        )


        appendDiagonalStreets(
            to: &edges
        )


        appendCulDeSacs(
            vertices: &vertices,
            edges: &edges
        )


        return RoadGraph(
            id:
                RoadGraphID(
                    "fifoo.city.reference-style.v1"
                ),

            version: 2,

            vertices: vertices,

            edges: edges
        )
    }
}

// =====================================================
// MARK: - Grid Vertices
// =====================================================

private extension DenseCityRoadGraph {

    static func appendGridVertices(
        to vertices:
            inout [RoadVertex]
    ) {

        for row in rowHours.indices {

            for column in
                columnProgress.indices {

                /*
                 A roundabout REPLACES this
                 ordinary intersection.

                 We don't draw a road underneath
                 the roundabout.
                 */

                if isRoundaboutAnchor(
                    row: row,
                    column: column
                ) {

                    continue
                }


                let isBoundary =
                    row == 0
                    ||
                    row == rowHours.count - 1
                    ||
                    column == 0
                    ||
                    column ==
                    columnProgress.count - 1


                vertices.append(

                    RoadVertex(
                        id:
                            gridVertexID(
                                row: row,
                                column: column
                            ),

                        coordinate:
                            gridCoordinate(
                                row: row,
                                column: column
                            ),

                        kind:
                            isBoundary
                            ? .junction
                            : .intersection
                    )
                )
            }
        }
    }
}

// =====================================================
// MARK: - Street Grid
// =====================================================

private extension DenseCityRoadGraph {

    static func appendStreetEdges(
        to edges:
            inout [RoadEdge]
    ) {

        // MARK: Horizontal

        for row in rowHours.indices {

            for column in
                0..<(columnProgress.count - 1) {

                if
                    isRoundaboutAnchor(
                        row: row,
                        column: column
                    )
                    ||
                    isRoundaboutAnchor(
                        row: row,
                        column: column + 1
                    )
                {

                    continue
                }


                let roadClass =
                    horizontalRoadClass(
                        row: row
                    )


                let from =
                    gridCoordinate(
                        row: row,
                        column: column
                    )


                let to =
                    gridCoordinate(
                        row: row,
                        column: column + 1
                    )


                edges.append(

                    RoadEdge(
                        id:
                            RoadEdgeID(
                                String(
                                    format:
                                        "street.h.r%02d.c%02d-%02d",
                                    row,
                                    column,
                                    column + 1
                                )
                            ),

                        fromID:
                            gridVertexID(
                                row: row,
                                column: column
                            ),

                        toID:
                            gridVertexID(
                                row: row,
                                column: column + 1
                            ),

                        roadClass:
                            roadClass,

                        shape:
                            organicShape(
                                from: from,
                                to: to,
                                seed:
                                    1000
                                    +
                                    row * 100
                                    +
                                    column,
                                roadClass:
                                    roadClass
                            ),

                        attributes:
                            attributes(
                                name:
                                    horizontalStreetName(
                                        row: row
                                    ),
                                roadClass:
                                    roadClass
                            )
                    )
                )
            }
        }


        // MARK: Vertical

        for column in
            columnProgress.indices {

            for row in
                0..<(rowHours.count - 1) {

                if
                    isRoundaboutAnchor(
                        row: row,
                        column: column
                    )
                    ||
                    isRoundaboutAnchor(
                        row: row + 1,
                        column: column
                    )
                {

                    continue
                }


                let roadClass =
                    verticalRoadClass(
                        column: column
                    )


                let from =
                    gridCoordinate(
                        row: row,
                        column: column
                    )


                let to =
                    gridCoordinate(
                        row: row + 1,
                        column: column
                    )


                edges.append(

                    RoadEdge(
                        id:
                            RoadEdgeID(
                                String(
                                    format:
                                        "street.v.c%02d.r%02d-%02d",
                                    column,
                                    row,
                                    row + 1
                                )
                            ),

                        fromID:
                            gridVertexID(
                                row: row,
                                column: column
                            ),

                        toID:
                            gridVertexID(
                                row: row + 1,
                                column: column
                            ),

                        roadClass:
                            roadClass,

                        shape:
                            organicShape(
                                from: from,
                                to: to,
                                seed:
                                    2000
                                    +
                                    column * 100
                                    +
                                    row,
                                roadClass:
                                    roadClass
                            ),

                        attributes:
                            attributes(
                                name:
                                    verticalStreetName(
                                        column: column
                                    ),
                                roadClass:
                                    roadClass
                            )
                    )
                )
            }
        }
    }
}

// =====================================================
// MARK: - Road Hierarchy
// =====================================================

private extension DenseCityRoadGraph {

    static func horizontalRoadClass(
        row: Int
    ) -> RoadClass {

        /*
         Noon corridor is the major
         east/west highway.

         Because it uses the grid itself,
         every crossing is a real vertex.
         */

        if row == 5 {
            return .highway
        }


        if row == 2 || row == 8 {
            return .arterial
        }


        return .local
    }


    static func verticalRoadClass(
        column: Int
    ) -> RoadClass {

        /*
         Eastern corridor is the major
         north/south highway.
         */

        if column == 7 {
            return .highway
        }


        if
            column == 2
            ||
            column == 4
            ||
            column == 6
        {

            return .arterial
        }


        return .local
    }
}

// =====================================================
// MARK: - Grid Coordinates
// =====================================================

private extension DenseCityRoadGraph {

    static func gridVertexID(
        row: Int,
        column: Int
    ) -> RoadVertexID {

        RoadVertexID(
            String(
                format:
                    "grid.r%02d.c%02d",
                row,
                column
            )
        )
    }


    static func gridCoordinate(
        row: Int,
        column: Int
    ) -> MapCoordinate {

        /*
         Gentle deterministic waves create
         irregular city blocks without
         introducing random topology.
         */

        let hourWave =
            sin(
                Double(row) * 0.71
                +
                Double(column) * 0.47
            )
            * 0.16


        let secondaryHourWave =
            cos(
                Double(column) * 0.31
            )
            * 0.04


        let progressWave =
            sin(
                Double(column) * 0.83
                +
                Double(row) * 0.39
            )
            * 2.4


        let secondaryProgressWave =
            cos(
                Double(row) * 0.52
            )
            * 0.8


        return coordinate(
            hour:
                rowHours[row]
                +
                hourWave
                +
                secondaryHourWave,

            progress:
                columnProgress[column]
                +
                progressWave
                +
                secondaryProgressWave
        )
    }


    static func isRoundaboutAnchor(
        row: Int,
        column: Int
    ) -> Bool {

        roundaboutAnchors.contains {

            $0.row == row
            &&
            $0.column == column
        }
    }
}

// =====================================================
// MARK: - Organic Road Shape
// =====================================================

private extension DenseCityRoadGraph {

    static func organicShape(
        from startCoordinate:
            MapCoordinate,

        to endCoordinate:
            MapCoordinate,

        seed: Int,

        roadClass:
            RoadClass
    ) -> RoadEdgeShape {

        let start =
            MapCoordinateConverter
                .worldPoint(
                    for: startCoordinate
                )


        let end =
            MapCoordinateConverter
                .worldPoint(
                    for: endCoordinate
                )


        let dx =
            end.x - start.x

        let dy =
            end.y - start.y


        let length =
            sqrt(
                dx * dx
                +
                dy * dy
            )


        guard length > 0.001 else {
            return .straight
        }


        let normalX =
            -dy / length

        let normalY =
            dx / length


        let maximumBend: Double


        switch roadClass {

        case .local:
            maximumBend = 14

        case .connector:
            maximumBend = 12

        case .arterial:
            maximumBend = 10

        case .highway:
            maximumBend = 6

        case .culDeSac:
            maximumBend = 8

        case .circle:
            maximumBend = 0
        }


        let raw =
            Double(
                (
                    seed * 37
                )
                % 9
                -
                4
            )


        let bend =
            (
                raw / 4
            )
            *
            maximumBend


        let control1 =
            WorldPoint(
                x:
                    start.x
                    +
                    dx * 0.33
                    +
                    normalX * bend,

                y:
                    start.y
                    +
                    dy * 0.33
                    +
                    normalY * bend
            )


        let control2 =
            WorldPoint(
                x:
                    start.x
                    +
                    dx * 0.67
                    +
                    normalX * bend,

                y:
                    start.y
                    +
                    dy * 0.67
                    +
                    normalY * bend
            )


        return .cubicBezier(
            control1: control1,
            control2: control2
        )
    }
}

// =====================================================
// MARK: - Roundabouts
// =====================================================

private extension DenseCityRoadGraph {

    static func appendRoundabouts(
        vertices:
            inout [RoadVertex],
        edges:
            inout [RoadEdge]
    ) {

        for anchor in
            roundaboutAnchors {

            appendRoundabout(
                anchor: anchor,
                vertices: &vertices,
                edges: &edges
            )
        }
    }


   private static func appendRoundabout(
        anchor:
            RoundaboutAnchor,

        vertices:
            inout [RoadVertex],

        edges:
            inout [RoadEdge]
    ) {

        let center =
            gridCoordinate(
                row: anchor.row,
                column: anchor.column
            )


        let progressRadius =
            5.5


        let hourRadius =
            0.55


        // MARK: Ring vertices

        for index in 0..<8 {

            let angle =
                (
                    Double(index)
                    / 8
                )
                *
                2
                *
                Double.pi


            let coordinate =
                coordinate(
                    hour:
                        (
                            center
                                .time
                                .secondsFromMidnight
                            / 3600
                        )
                        -
                        hourRadius
                        *
                        sin(angle),

                    progress:
                        center
                            .progress
                            .percent
                        +
                        progressRadius
                        *
                        cos(angle)
                )


            let kind:
                RoadVertexKind


            switch index {

            case 0, 4:
                kind = .circleEntry

            case 2, 6:
                kind = .circleExit

            default:
                kind = .junction
            }


            vertices.append(

                RoadVertex(
                    id:
                        roundaboutVertexID(
                            name: anchor.name,
                            index: index
                        ),

                    coordinate:
                        coordinate,

                    kind:
                        kind
                )
            )
        }


        // MARK: Ring edges

        for index in 0..<8 {

            let next =
                (index + 1) % 8


            edges.append(

                RoadEdge(
                    id:
                        RoadEdgeID(
                            String(
                                format:
                                    "roundabout.%@.ring.%02d-%02d",
                                anchor.name,
                                index,
                                next
                            )
                        ),

                    fromID:
                        roundaboutVertexID(
                            name: anchor.name,
                            index: index
                        ),

                    toID:
                        roundaboutVertexID(
                            name: anchor.name,
                            index: next
                        ),

                    roadClass:
                        .circle,

                    attributes:
                        attributes(
                            name:
                                "\(anchor.name.capitalized) Circle",
                            roadClass:
                                .circle
                        )
                )
            )
        }


        /*
         index 0 = east
         index 2 = north
         index 4 = west
         index 6 = south
         */

        let connectors: [
            (
                row: Int,
                column: Int,
                ringIndex: Int
            )
        ] = [

            (
                anchor.row,
                anchor.column + 1,
                0
            ),

            (
                anchor.row - 1,
                anchor.column,
                2
            ),

            (
                anchor.row,
                anchor.column - 1,
                4
            ),

            (
                anchor.row + 1,
                anchor.column,
                6
            )
        ]


        for (
            connectorIndex,
            connector
        ) in connectors.enumerated() {

            let ringCoordinate =
                roundaboutCoordinate(
                    anchor: anchor,
                    index:
                        connector.ringIndex
                )


            let gridCoordinate =
                gridCoordinate(
                    row: connector.row,
                    column:
                        connector.column
                )


            edges.append(

                RoadEdge(
                    id:
                        RoadEdgeID(
                            "roundabout.\(anchor.name).connector.\(connectorIndex)"
                        ),

                    fromID:
                        gridVertexID(
                            row:
                                connector.row,
                            column:
                                connector.column
                        ),

                    toID:
                        roundaboutVertexID(
                            name:
                                anchor.name,
                            index:
                                connector.ringIndex
                        ),

                    roadClass:
                        .connector,

                    shape:
                        organicShape(
                            from:
                                gridCoordinate,
                            to:
                                ringCoordinate,
                            seed:
                                3000
                                +
                                anchor.row * 100
                                +
                                anchor.column * 10
                                +
                                connectorIndex,
                            roadClass:
                                .connector
                        ),

                    attributes:
                        attributes(
                            name:
                                "\(anchor.name.capitalized) Circle Access",
                            roadClass:
                                .connector
                        )
                )
            )
        }
    }
}

private extension DenseCityRoadGraph {

    static func roundaboutVertexID(
        name: String,
        index: Int
    ) -> RoadVertexID {

        RoadVertexID(
            String(
                format:
                    "roundabout.%@.v%02d",
                name,
                index
            )
        )
    }


    private static func roundaboutCoordinate(
        anchor: RoundaboutAnchor,
        index: Int
    ) -> MapCoordinate {

        let center =
            gridCoordinate(
                row: anchor.row,
                column: anchor.column
            )


        let angle =
            (
                Double(index)
                / 8
            )
            *
            2
            *
            Double.pi


        return coordinate(
            hour:
                (
                    center
                        .time
                        .secondsFromMidnight
                    / 3600
                )
                -
                0.55
                *
                sin(angle),

            progress:
                center
                    .progress
                    .percent
                +
                5.5
                *
                cos(angle)
        )
    }
}

// =====================================================
// MARK: - Diagonal Streets
// =====================================================

private extension DenseCityRoadGraph {

    static let diagonalCells:
        [(row: Int, column: Int)] = [

        (0, 1),
        (0, 5),

        (1, 3),
        (1, 7),

        (2, 0),
        (2, 5),
        (2, 8),

        (3, 1),
        (3, 5),

        (4, 2),
        (4, 6),

        (5, 0),
        (5, 4),

        (6, 2),
        (6, 5),

        (7, 0),

        (8, 4),

        (9, 6)
    ]


    static func appendDiagonalStreets(
        to edges:
            inout [RoadEdge]
    ) {

        for (
            index,
            cell
        ) in diagonalCells.enumerated() {

            let fromRow =
                cell.row

            let fromColumn =
                cell.column


            let toRow =
                cell.row + 1

            let toColumn =
                cell.column + 1


            let from =
                gridCoordinate(
                    row: fromRow,
                    column: fromColumn
                )


            let to =
                gridCoordinate(
                    row: toRow,
                    column: toColumn
                )


            edges.append(

                RoadEdge(
                    id:
                        RoadEdgeID(
                            String(
                                format:
                                    "street.diagonal.%02d",
                                index
                            )
                        ),

                    fromID:
                        gridVertexID(
                            row: fromRow,
                            column: fromColumn
                        ),

                    toID:
                        gridVertexID(
                            row: toRow,
                            column: toColumn
                        ),

                    roadClass:
                        .connector,

                    shape:
                        organicShape(
                            from: from,
                            to: to,
                            seed:
                                4000
                                +
                                fromRow * 100
                                +
                                fromColumn,
                            roadClass:
                                .connector
                        ),

                    attributes:
                        attributes(
                            name:
                                "Diagonal Way \(index + 1)",
                            roadClass:
                                .connector
                        )
                )
            )
        }
    }
}

// =====================================================
// MARK: - Cul-de-sacs
// =====================================================

private extension DenseCityRoadGraph {

    struct CulDeSacDefinition {

        let name: String

        let parentRow: Int

        let parentColumn: Int

        let endHour: Double

        let endProgress: Double

        let usesIntermediateJunction:
            Bool
    }


    static func appendCulDeSacs(
        vertices:
            inout [RoadVertex],
        edges:
            inout [RoadEdge]
    ) {

        let definitions: [
            CulDeSacDefinition
        ] = [

            CulDeSacDefinition(
                name: "north",
                parentRow: 0,
                parentColumn: 5,
                endHour: 0.10,
                endProgress: 62,
                usesIntermediateJunction: true
            ),

            CulDeSacDefinition(
                name: "northwest",
                parentRow: 1,
                parentColumn: 0,
                endHour: 3.70,
                endProgress: -48,
                usesIntermediateJunction: false
            ),

            CulDeSacDefinition(
                name: "northeast",
                parentRow: 2,
                parentColumn: 9,
                endHour: 5.90,
                endProgress: 148,
                usesIntermediateJunction: false
            ),

            CulDeSacDefinition(
                name: "west-mid",
                parentRow: 4,
                parentColumn: 0,
                endHour: 10.50,
                endProgress: -48,
                usesIntermediateJunction: false
            ),

            CulDeSacDefinition(
                name: "east-mid",
                parentRow: 5,
                parentColumn: 9,
                endHour: 12.80,
                endProgress: 148,
                usesIntermediateJunction: false
            ),

            CulDeSacDefinition(
                name: "east-south",
                parentRow: 8,
                parentColumn: 9,
                endHour: 19.50,
                endProgress: 148,
                usesIntermediateJunction: false
            ),

            CulDeSacDefinition(
                name: "southwest",
                parentRow: 9,
                parentColumn: 0,
                endHour: 21.80,
                endProgress: -48,
                usesIntermediateJunction: false
            ),

            CulDeSacDefinition(
                name: "southeast",
                parentRow: 9,
                parentColumn: 9,
                endHour: 22.00,
                endProgress: 148,
                usesIntermediateJunction: false
            )
        ]


        for (
            index,
            definition
        ) in definitions.enumerated() {

            let parentCoordinate =
                gridCoordinate(
                    row:
                        definition.parentRow,
                    column:
                        definition.parentColumn
                )


            let endpointCoordinate =
                coordinate(
                    hour:
                        definition.endHour,
                    progress:
                        definition.endProgress
                )


            let endpointID =
                RoadVertexID(
                    "culdesac.\(definition.name).end"
                )


            vertices.append(

                RoadVertex(
                    id: endpointID,
                    coordinate:
                        endpointCoordinate,
                    kind:
                        .culDeSacEnd
                )
            )


            if definition
                .usesIntermediateJunction {

                let midpoint =
                    midpoint(
                        parentCoordinate,
                        endpointCoordinate
                    )


                let midpointID =
                    RoadVertexID(
                        "culdesac.\(definition.name).mid"
                    )


                vertices.append(

                    RoadVertex(
                        id:
                            midpointID,
                        coordinate:
                            midpoint,
                        kind:
                            .junction
                    )
                )


                edges.append(

                    RoadEdge(
                        id:
                            RoadEdgeID(
                                "culdesac.\(definition.name).a"
                            ),

                        fromID:
                            gridVertexID(
                                row:
                                    definition.parentRow,
                                column:
                                    definition.parentColumn
                            ),

                        toID:
                            midpointID,

                        roadClass:
                            .culDeSac,

                        shape:
                            organicShape(
                                from:
                                    parentCoordinate,
                                to:
                                    midpoint,
                                seed:
                                    5000
                                    +
                                    index * 2,
                                roadClass:
                                    .culDeSac
                            )
                    )
                )


                edges.append(

                    RoadEdge(
                        id:
                            RoadEdgeID(
                                "culdesac.\(definition.name).b"
                            ),

                        fromID:
                            midpointID,

                        toID:
                            endpointID,

                        roadClass:
                            .culDeSac,

                        shape:
                            organicShape(
                                from:
                                    midpoint,
                                to:
                                    endpointCoordinate,
                                seed:
                                    5001
                                    +
                                    index * 2,
                                roadClass:
                                    .culDeSac
                            )
                    )
                )

            } else {

                edges.append(

                    RoadEdge(
                        id:
                            RoadEdgeID(
                                "culdesac.\(definition.name)"
                            ),

                        fromID:
                            gridVertexID(
                                row:
                                    definition.parentRow,
                                column:
                                    definition.parentColumn
                            ),

                        toID:
                            endpointID,

                        roadClass:
                            .culDeSac,

                        shape:
                            organicShape(
                                from:
                                    parentCoordinate,
                                to:
                                    endpointCoordinate,
                                seed:
                                    5000 + index,
                                roadClass:
                                    .culDeSac
                            )
                    )
                )
            }
        }
    }
}

// =====================================================
// MARK: - Helpers
// =====================================================

private extension DenseCityRoadGraph {

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


    static func midpoint(
        _ first: MapCoordinate,
        _ second: MapCoordinate
    ) -> MapCoordinate {

        MapCoordinate(
            time:
                DayTime(
                    secondsFromMidnight:
                        (
                            first
                                .time
                                .secondsFromMidnight
                            +
                            second
                                .time
                                .secondsFromMidnight
                        )
                        / 2
                ),

            progress:
                MapProgress(
                    (
                        first
                            .progress
                            .percent
                        +
                        second
                            .progress
                            .percent
                    )
                    / 2
                )
        )
    }


    static func attributes(
        name: String?,
        roadClass: RoadClass
    ) -> RoadAttributes {

        RoadAttributes(
            displayName:
                name,

            isTraversable:
                true,

            /*
             Reference-style Fifoo map:
             overpasses are intentionally
             disabled.
             */

            isGradeSeparated:
                false,

            routingCostMultiplier:
                routingCost(
                    roadClass
                )
        )
    }


    static func routingCost(
        _ roadClass: RoadClass
    ) -> Double {

        switch roadClass {

        case .highway:
            return 0.70

        case .arterial:
            return 0.85

        case .connector,
             .circle:
            return 1.0

        case .local:
            return 1.10

        case .culDeSac:
            return 1.20
        }
    }


    static func horizontalStreetName(
        row: Int
    ) -> String {

        [
            "North Way",
            "Early Street",
            "Sunrise Avenue",
            "Morning Road",
            "Market Street",
            "Central Boulevard",
            "Afternoon Road",
            "Cedar Avenue",
            "Evening Avenue",
            "Night Street",
            "South Way"
        ][row]
    }


    static func verticalStreetName(
        column: Int
    ) -> String {

        [
            "Far West Road",
            "West Street",
            "Zero Avenue",
            "Oak Street",
            "Central Avenue",
            "Maple Street",
            "East Central Avenue",
            "Grand Boulevard",
            "East Avenue",
            "Far East Road"
        ][column]
    }
}


