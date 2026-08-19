//
//  SampleGameNodes.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/19/26.
//


import Foundation


enum SampleGameNodes {

    static func make() -> [GameMapNode] {

        [

            // MARK: - Label

            GameMapNode(
                placement:
                    .coordinate(
                        coordinate(
                            hour: 2.0,
                            progress: 12
                        )
                    ),
                content:
                    .label(
                        LabelNodeContent(
                            text:
                                "Morning",
                            image:
                                .systemSymbol(
                                    name:
                                        "sunrise.fill"
                                )
                        )
                    )
            ),


            // MARK: - Activity

            GameMapNode(
                placement:
                    .roadVertex(
                        RoadVertexID(
                            "grid.r02.c02"
                        )
                    ),
                content:
                    .activity(
                        ActivityNodeContent(
                            activityID:
                                "morning-walk",
                            title:
                                "Morning Walk",
                            description:
                                "Start the day with a walk.",
                            image:
                                .systemSymbol(
                                    name:
                                        "figure.walk"
                                )
                        )
                    )
            ),


            // MARK: - Post

            GameMapNode(
                placement:
                    .roadVertex(
                        RoadVertexID(
                            "grid.r04.c06"
                        )
                    ),
                content:
                    .post(
                        PostNodeContent(
                            postID:
                                "sample-post-001",
                            title:
                                "Progress Check-in",
                            image:
                                .systemSymbol(
                                    name:
                                        "bubble.left.and.bubble.right.fill"
                                )
                        )
                    )
            ),


            // MARK: - Media

            GameMapNode(
                placement:
                    .coordinate(
                        coordinate(
                            hour: 15.4,
                            progress: 110
                        )
                    ),
                content:
                    .media(
                        MediaNodeContent(
                            mediaID:
                                "sample-media-001",
                            title:
                                "Workout Clip",
                            mediaType:
                                .video,
                            urlString:
                                nil,
                            image:
                                .systemSymbol(
                                    name:
                                        "play.rectangle.fill"
                                )
                        )
                    )
            ),


            // MARK: - User

            GameMapNode(
                placement:
                    .roadVertex(
                        RoadVertexID(
                            "grid.r07.c04"
                        )
                    ),
                content:
                    .user(
                        UserNodeContent(
                            userID:
                                "sample-user-001",
                            displayName:
                                "Alex",
                            image:
                                .systemSymbol(
                                    name:
                                        "person.crop.circle.fill"
                                )
                        )
                    )
            ),


            // MARK: - Hyperlink

            GameMapNode(
                placement:
                    .coordinate(
                        coordinate(
                            hour: 21.3,
                            progress: 116
                        )
                    ),
                content:
                    .hyperlink(
                        HyperlinkNodeContent(
                            title:
                                "Nutrition Guide",
                            urlString:
                                "https://example.com",
                            image:
                                .systemSymbol(
                                    name:
                                        "link.circle.fill"
                                )
                        )
                    )
            )
        ]
    }


    // MARK: - Helper

    private static func coordinate(
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
}



