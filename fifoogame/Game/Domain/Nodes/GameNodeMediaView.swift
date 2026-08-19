//
//  GameNodeMediaView.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/19/26.
//


import SwiftUI


struct GameNodeMediaView:
    View {

    let node:
        GameMapNode


    @Environment(\.dismiss)
    private var dismiss


    var body: some View {

        ZStack {

            Color.black
                .ignoresSafeArea()


            if case let .media(
                content
            ) = node.content {

                VStack(
                    spacing:
                        20
                ) {

                    Spacer()


                    Image(
                        systemName:
                            icon(
                                for:
                                    content.mediaType
                            )
                    )
                    .font(
                        .system(
                            size:
                                90
                        )
                    )
                    .foregroundStyle(
                        .white
                    )


                    Text(
                        content.title
                    )
                    .font(
                        .title2
                    )
                    .fontWeight(
                        .bold
                    )
                    .foregroundStyle(
                        .white
                    )


                    if let urlString =
                        content.urlString {

                        Text(
                            urlString
                        )
                        .font(
                            .caption
                        )
                        .foregroundStyle(
                            .secondary
                        )
                        .multilineTextAlignment(
                            .center
                        )
                        .padding(
                            .horizontal
                        )
                    }


                    Spacer()
                }
            }


            VStack {

                HStack {

                    Spacer()


                    Button {

                        dismiss()

                    } label: {

                        Image(
                            systemName:
                                "xmark.circle.fill"
                        )
                        .font(
                            .system(
                                size:
                                    30
                            )
                        )
                        .foregroundStyle(
                            .white
                        )
                    }
                }


                Spacer()
            }
            .padding()
        }
    }


    private func icon(
        for type:
            MediaNodeContent.MediaType
    ) -> String {

        switch type {

        case .image:

            return "photo.fill"


        case .video:

            return "play.rectangle.fill"


        case .gif:

            return "sparkles.rectangle.stack.fill"
        }
    }
}
