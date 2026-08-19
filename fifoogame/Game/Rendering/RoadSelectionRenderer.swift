//
//  RoadSelectionRenderer.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/19/26.
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
        selection:
            SelectionState,
        graph:
            RoadGraph,
        roadRenderer:
            RoadLayerRenderer
    ) {

        clear()


        // =========================================
        // Edge
        // =========================================

        if
            let edgeID =
                selection
                    .selectedRoadEdgeID,

            let sourceNode =
                roadRenderer
                    .surfaceNode(
                        for:
                            edgeID
                    ),

            let path =
                sourceNode.path
        {

            let halo =
                SKShapeNode(
                    path:
                        path
                )


            halo.strokeColor =
                MapVisualTheme
                    .roadSelectionHaloColor


            halo.lineWidth =
                sourceNode.lineWidth
                +
                12


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
                sourceNode.lineWidth
                +
                3


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


            return
        }


        // =========================================
        // Vertex
        // =========================================

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

            let location =
                vertex
                    .worldPoint
                    .cgPoint


            let halo =
                SKShapeNode(
                    circleOfRadius:
                        28
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
                        20
                )


            ring.position =
                location


            ring.fillColor =
                .clear


            ring.strokeColor =
                MapVisualTheme
                    .roadSelectionColor


            ring.lineWidth =
                6


            ring.zPosition =
                1


            containerNode.addChild(
                ring
            )
        }
    }


    func clear() {

        containerNode
            .removeAllChildren()
    }
}
