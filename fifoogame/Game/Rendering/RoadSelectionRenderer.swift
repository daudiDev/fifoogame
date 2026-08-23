//
//  RoadSelectionRenderer.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/22/26.
//


import SpriteKit


@MainActor
final class RoadSelectionRenderer {

    let containerNode =
        SKNode()


    init() {

        containerNode.name =
            "roadSelectionRenderer"
    }


    func render(
        selection: SelectionState,
        graph: RoadGraph
    ) {

        clear()


        if
            let edgeID =
                selection
                    .selectedRoadEdgeID,
            let edge =
                graph.edge(
                    id:
                        edgeID
                )
        {

            renderEdgeSelection(
                edge:
                    edge,
                graph:
                    graph
            )

            return
        }


        if
            let vertexID =
                selection
                    .selectedRoadVertexID,
            let vertex =
                graph.vertex(
                    id:
                        vertexID
                )
        {

            renderVertexSelection(
                vertex:
                    vertex
            )
        }
    }


    func clear() {

        containerNode
            .removeAllChildren()
    }
}


// =====================================================
// MARK: - Edge Selection
// =====================================================

private extension RoadSelectionRenderer {

    func renderEdgeSelection(
        edge: RoadEdge,
        graph: RoadGraph
    ) {

        let points =
            RoadEdgeGeometry
                .sampledPoints(
                    for:
                        edge,
                    graph:
                        graph
                )
                .map(\.cgPoint)


        guard
            let first = points.first,
            points.count >= 2
        else {

            return
        }


        let path =
            CGMutablePath()

        path.move(
            to:
                first
        )


        for point in points.dropFirst() {

            path.addLine(
                to:
                    point
            )
        }


        let baseWidth =
            GridMapConfiguration
                .roadWidthWorld


        let halo =
            SKShapeNode(
                path:
                    path
            )

        halo.strokeColor =
            MapVisualTheme
                .roadSelectionHaloColor

        halo.lineWidth =
            baseWidth + 10

        halo.lineCap =
            .round

        halo.lineJoin =
            .round

        halo.fillColor =
            .clear

        halo.zPosition =
            0


        containerNode.addChild(
            halo
        )


        let highlight =
            SKShapeNode(
                path:
                    path
            )

        highlight.strokeColor =
            MapVisualTheme
                .roadSelectionColor

        highlight.lineWidth =
            max(
                4,
                baseWidth * 0.18
            )

        highlight.lineCap =
            .round

        highlight.lineJoin =
            .round

        highlight.fillColor =
            .clear

        highlight.zPosition =
            1


        containerNode.addChild(
            highlight
        )
    }
}


// =====================================================
// MARK: - Vertex Selection
// =====================================================

private extension RoadSelectionRenderer {

    func renderVertexSelection(
        vertex: RoadVertex
    ) {

        let location =
            vertex
                .worldPoint
                .cgPoint

        let baseRadius =
            max(
                12,
                GridMapConfiguration
                    .roadHalfWidthWorld
                    * 0.9
            )


        let halo =
            SKShapeNode(
                circleOfRadius:
                    baseRadius + 7
            )

        halo.position =
            location

        halo.fillColor =
            MapVisualTheme
                .roadSelectionHaloColor

        halo.strokeColor =
            .clear


        containerNode.addChild(
            halo
        )


        let ring =
            SKShapeNode(
                circleOfRadius:
                    baseRadius
            )

        ring.position =
            location

        ring.fillColor =
            .clear

        ring.strokeColor =
            MapVisualTheme
                .roadSelectionColor

        ring.lineWidth =
            5

        ring.zPosition =
            1


        containerNode.addChild(
            ring
        )
    }
}
