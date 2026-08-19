//
//  GameNodeTypeDetailViews.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/19/26.
//

import SwiftUI

struct GameNodeTypeDetailViews: View {
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

struct LabelNodeDetailView:
    View {

    let content:
        LabelNodeContent


    var body: some View {

        VStack(
            spacing:
                20
        ) {

            Image(
                systemName:
                    "tag.fill"
            )
            .font(
                .system(
                    size:
                        50
                )
            )


            Text(
                content.text
            )
            .font(
                .title2
            )
            .fontWeight(
                .semibold
            )
        }
        .padding()
    }
}

struct UserNodeDetailView:
    View {

    let content:
        UserNodeContent


    var body: some View {

        VStack(
            spacing:
                16
        ) {

            Image(
                systemName:
                    "person.crop.circle.fill"
            )
            .font(
                .system(
                    size:
                        80
                )
            )


            Text(
                content.displayName
            )
            .font(
                .title2
            )
            .fontWeight(
                .semibold
            )


            Text(
                "User ID: \(content.userID)"
            )
            .font(
                .caption.monospaced()
            )
            .foregroundStyle(
                .secondary
            )
        }
        .padding()
    }
}

struct ActivityNodeDetailView:
    View {

    let content:
        ActivityNodeContent


    var body: some View {

        ScrollView {

            VStack(
                alignment:
                    .leading,
                spacing:
                    18
            ) {

                Image(
                    systemName:
                        "figure.walk.circle.fill"
                )
                .font(
                    .system(
                        size:
                            72
                    )
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


                if
                    let description =
                        content.description
                {

                    Text(
                        description
                    )
                }


                Divider()


                Text(
                    "Activity ID"
                )
                .font(
                    .caption
                )
                .foregroundStyle(
                    .secondary
                )


                Text(
                    content.activityID
                )
                .font(
                    .caption.monospaced()
                )
            }
            .frame(
                maxWidth:
                    .infinity,
                alignment:
                    .leading
            )
            .padding()
        }
    }
}

struct PostNodeDetailView:
    View {

    let content:
        PostNodeContent


    var body: some View {

        VStack(
            alignment:
                .leading,
            spacing:
                18
        ) {

            Image(
                systemName:
                    "bubble.left.and.bubble.right.fill"
            )
            .font(
                .system(
                    size:
                        60
                )
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


            Divider()


            Text(
                "Post ID"
            )
            .font(
                .caption
            )
            .foregroundStyle(
                .secondary
            )


            Text(
                content.postID
            )
            .font(
                .caption.monospaced()
            )


            Spacer()
        }
        .frame(
            maxWidth:
                .infinity,
            alignment:
                .leading
        )
        .padding()
    }
}

struct HyperlinkNodeDetailView:
    View {

    let content:
        HyperlinkNodeContent


    var body: some View {

        VStack(
            spacing:
                16
        ) {

            Image(
                systemName:
                    "link.circle.fill"
            )
            .font(
                .system(
                    size:
                        64
                )
            )


            Text(
                content.title
            )
            .font(
                .title2
            )


            Text(
                content.urlString
            )
            .font(
                .caption.monospaced()
            )
            .foregroundStyle(
                .secondary
            )
        }
        .padding()
    }
}

struct MediaNodeMetadataView:
    View {

    let content:
        MediaNodeContent


    var body: some View {

        VStack(
            spacing:
                16
        ) {

            Image(
                systemName:
                    mediaIcon
            )
            .font(
                .system(
                    size:
                        64
                )
            )


            Text(
                content.title
            )
            .font(
                .title2
            )


            Text(
                content.mediaType
                    .rawValue
                    .capitalized
            )
            .foregroundStyle(
                .secondary
            )
        }
        .padding()
    }


    private var mediaIcon:
        String {

        switch content.mediaType {

        case .image:

            return "photo.fill"


        case .video:

            return "play.rectangle.fill"


        case .gif:

            return "sparkles.rectangle.stack.fill"
        }
    }
}


