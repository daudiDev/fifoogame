//
//  GameNodeInspectorHUD.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/19/26.
//


import SwiftUI


struct GameNodeInspectorHUD:
    View {

    let node:
        GameMapNode


    var body: some View {

        VStack(
            alignment:
                .leading,
            spacing:
                6
        ) {

            HStack {

                Text(
                    node
                        .content
                        .title
                )
                .font(
                    .headline
                )


                Spacer()


                Text(
                    node
                        .content
                        .kind
                        .rawValue
                        .capitalized
                )
                .font(
                    .caption
                )
                .fontWeight(
                    .semibold
                )
            }


            Divider()


            Text(
                "Stop ID"
            )
            .foregroundStyle(
                .secondary
            )


            Text(
                node
                    .id
                    .rawValue
                    .uuidString
            )
            .font(
                .caption2.monospaced()
            )


            placementDescription
        }
        .font(
            .caption
        )
        .foregroundStyle(
            .white
        )
        .padding()
        .background(
            Color.black
                .opacity(
                    0.58
                )
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius:
                    16
            )
        )
    }
}

private extension GameNodeInspectorHUD {

    @ViewBuilder
    var placementDescription:
        some View {

        switch node.placement {

        case let .coordinate(
            coordinate
        ):

            Text(
                String(
                    format:
                        "Progress %.1f%% • %@",
                    coordinate
                        .progress
                        .percent,
                    coordinate
                        .time
                        .displayClockString
                )
            )


        case let .roadVertex(
            vertexID
        ):

            Text(
                "Attached to \(vertexID.rawValue)"
            )
        }
    }
}
