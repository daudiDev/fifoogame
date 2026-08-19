//
//  RoadInspectorHUD.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/19/26.
//

import SwiftUI


struct RoadInspectorHUD:
    View {

    let graph:
        RoadGraph

    let selection:
        SelectionState


    var body: some View {

        Group {

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

                edgeView(
                    edge
                )


            } else if
                let vertexID =
                    selection
                        .selectedRoadVertexID,

                let vertex =
                    graph.vertex(
                        id:
                            vertexID
                    )
            {

                vertexView(
                    vertex
                )


            } else {

                Text(
                    "Tap a road or intersection"
                )
                .font(
                    .caption
                )
            }
        }
        .foregroundStyle(
            .white
        )
        .padding(
            12
        )
        .background(
            Color.black
                .opacity(
                    0.58
                )
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius:
                    12
            )
        )
    }
}

private extension RoadInspectorHUD {

    @ViewBuilder
    func edgeView(
        _ edge:
            RoadEdge
    ) -> some View {

        VStack(
            alignment:
                .leading,
            spacing:
                4
        ) {

            Text(
                edge.attributes
                    .displayName
                ??
                edge.id.rawValue
            )
            .font(
                .headline
            )


            Text(
                "Edge: \(edge.id.rawValue)"
            )


            Text(
                "Class: \(edge.roadClass.rawValue)"
            )


            Text(
                """
                \(edge.fromID.rawValue) → \
                \(edge.toID.rawValue)
                """
            )
        }
        .font(
            .caption
        )
    }


    @ViewBuilder
    func vertexView(
        _ vertex:
            RoadVertex
    ) -> some View {

        let degree =
            graph.degree(
                of:
                    vertex.id
            )


        VStack(
            alignment:
                .leading,
            spacing:
                4
        ) {

            Text(
                "Intersection"
            )
            .font(
                .headline
            )


            Text(
                "Vertex: \(vertex.id.rawValue)"
            )


            Text(
                "Kind: \(vertex.kind.rawValue)"
            )


            Text(
                "Degree: \(degree)"
            )


            Text(
                String(
                    format:
                        "Progress: %.1f%%",
                    vertex
                        .coordinate
                        .progress
                        .percent
                )
            )


            Text(
                "Time: \(vertex.coordinate.time.displayClockString)"
            )
        }
        .font(
            .caption
        )
    }
}
