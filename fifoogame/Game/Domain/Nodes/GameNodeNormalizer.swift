//
//  GameNodeNormalizer.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/19/26.
//


import Foundation


enum GameNodeNormalizer {

    static func normalize(
        _ node: GameMapNode
    ) -> GameMapNode {

        var updated =
            node


        switch updated.content {

        case var .label(
            content
        ):

            content.text =
                clean(
                    content.text
                )

            updated.content =
                .label(
                    content
                )


        case var .user(
            content
        ):

            content.displayName =
                clean(
                    content.displayName
                )

            content.userID =
                clean(
                    content.userID
                )

            updated.content =
                .user(
                    content
                )


        case var .activity(
            content
        ):

            content.title =
                clean(
                    content.title
                )

            content.activityID =
                clean(
                    content.activityID
                )


            if let description =
                content.description {

                let cleaned =
                    clean(
                        description
                    )

                content.description =
                    cleaned.isEmpty
                    ? nil
                    : cleaned
            }


            updated.content =
                .activity(
                    content
                )


        case var .post(
            content
        ):

            content.title =
                clean(
                    content.title
                )

            content.postID =
                clean(
                    content.postID
                )

            updated.content =
                .post(
                    content
                )


        case var .media(
            content
        ):

            content.title =
                clean(
                    content.title
                )

            content.mediaID =
                clean(
                    content.mediaID
                )


            if let url =
                content.urlString {

                let cleaned =
                    clean(
                        url
                    )

                content.urlString =
                    cleaned.isEmpty
                    ? nil
                    : cleaned
            }


            updated.content =
                .media(
                    content
                )


        case var .hyperlink(
            content
        ):

            content.title =
                clean(
                    content.title
                )

            content.urlString =
                clean(
                    content.urlString
                )

            updated.content =
                .hyperlink(
                    content
                )
        }


        return updated
    }


    private static func clean(
        _ value: String
    ) -> String {

        value.trimmingCharacters(
            in:
                .whitespacesAndNewlines
        )
    }
}
