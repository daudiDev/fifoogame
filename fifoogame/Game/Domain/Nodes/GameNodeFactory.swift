//
//  GameNodeFactory.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/19/26.
//

import Foundation


enum GameNodeFactory {

    static func make(
        kind: GameNodeKind,
        placement: GameNodePlacement
    ) -> GameMapNode {

        switch kind {

        // =============================================
        // Label
        // =============================================

        case .label:

            return GameMapNode(
                placement:
                    placement,
                content:
                    .label(
                        LabelNodeContent(
                            text:
                                "New Label",
                            image:
                                .systemSymbol(
                                    name:
                                        "tag.fill"
                                )
                        )
                    )
            )


        // =============================================
        // User
        // =============================================

        case .user:

            return GameMapNode(
                placement:
                    placement,
                content:
                    .user(
                        UserNodeContent(
                            userID:
                                UUID()
                                    .uuidString,
                            displayName:
                                "New User",
                            image:
                                .systemSymbol(
                                    name:
                                        "person.crop.circle.fill"
                                )
                        )
                    )
            )


        // =============================================
        // Activity
        // =============================================

        case .activity:

            return GameMapNode(
                placement:
                    placement,
                content:
                    .activity(
                        ActivityNodeContent(
                            activityID:
                                UUID()
                                    .uuidString,
                            title:
                                "New Activity",
                            description:
                                nil,
                            image:
                                .systemSymbol(
                                    name:
                                        "figure.walk"
                                )
                        )
                    )
            )


        // =============================================
        // Post
        // =============================================

        case .post:

            return GameMapNode(
                placement:
                    placement,
                content:
                    .post(
                        PostNodeContent(
                            postID:
                                UUID()
                                    .uuidString,
                            title:
                                "New Post",
                            image:
                                .systemSymbol(
                                    name:
                                        "bubble.left.and.bubble.right.fill"
                                )
                        )
                    )
            )


        // =============================================
        // Media
        // =============================================

        case .media:

            return GameMapNode(
                placement:
                    placement,
                content:
                    .media(
                        MediaNodeContent(
                            mediaID:
                                UUID()
                                    .uuidString,
                            title:
                                "New Media",
                            mediaType:
                                .image,
                            urlString:
                                nil,
                            image:
                                .systemSymbol(
                                    name:
                                        "photo.fill"
                                )
                        )
                    )
            )


        // =============================================
        // Hyperlink
        // =============================================

        case .hyperlink:

            return GameMapNode(
                placement:
                    placement,
                content:
                    .hyperlink(
                        HyperlinkNodeContent(
                            title:
                                "New Link",
                            urlString:
                                "https://",
                            image:
                                .systemSymbol(
                                    name:
                                        "link.circle.fill"
                                )
                        )
                    )
            )
        }
    }


    static func make(
        kind: GameNodeKind,
        coordinate: MapCoordinate
    ) -> GameMapNode {

        make(
            kind:
                kind,
            placement:
                .coordinate(
                    coordinate
                )
        )
    }
}
