//
//  GameNodeFactory.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/24/26.
//



import Foundation


// =====================================================
// MARK: - Add Node Types
// =====================================================

/// The five content choices that can be created from AddGameNodeView.
///
/// Meal / Workout / Task all produce an Activity node and seed the matching
/// Activity payload. Tip / Request both produce a Post node and seed the
/// Post snapshot with the matching postType.
enum AddGameNodeType:
    String,
    CaseIterable,
    Identifiable,
    Sendable {

    case meal
    case workout
    case task
    case tip
    case request


    var id: String {
        rawValue
    }


    var displayName: String {

        switch self {

        case .meal:
            return "Meal"

        case .workout:
            return "Workout"

        case .task:
            return "Task"

        case .tip:
            return "Tip"

        case .request:
            return "Request"
        }
    }


    var systemImageName: String {

        switch self {

        case .meal:
            return "fork.knife"

        case .workout:
            return "figure.run"

        case .task:
            return "checkmark.circle.fill"

        case .tip:
            return "lightbulb.fill"

        case .request:
            return "questionmark.circle.fill"
        }
    }


    var backingModelDescription: String {

        switch self {

        case .meal:
            return "Activity • SuggestedMeal"

        case .workout:
            return "Activity • Workout"

        case .task:
            return "Activity • Task"

        case .tip:
            return "Post • Tip"

        case .request:
            return "Post • Request"
        }
    }


    var description: String {

        switch self {

        case .meal:
            return "Creates an Activity with Activity Type already set to Meal and initializes its SuggestedMeal data."

        case .workout:
            return "Creates an Activity with Activity Type already set to Workout and initializes its Workout data."

        case .task:
            return "Creates an Activity with Activity Type already set to Task and initializes its Task data."

        case .tip:
            return "Creates a Post with Post Type already set to Tip."

        case .request:
            return "Creates a Post with Post Type already set to Request."
        }
    }
}


// =====================================================
// MARK: - Factory
// =====================================================

enum GameNodeFactory {

    static func make(
        kind: GameNodeKind,
        placement: GameNodePlacement,
        time: DayTime? = nil
    ) -> GameMapNode {

        let content: GameNodeContent

        switch kind {

        case .play:

            content =
                .play(
                    PlayNodeContent(
                        title: "Play",
                        image: nil
                    )
                )


        case .user:

            content =
                .user(
                    UserNodeContent(
                        userID: UUID().uuidString,
                        displayName: "New User",
                        image: nil
                    )
                )


        case .activity:

            content =
                .activity(
                    ActivityNodeContent(
                        activityID: UUID().uuidString,
                        title: "New Activity",
                        startTime: time?.displayClockString ?? "",
                        description: nil,
                        activityType: ActivityNodeContent.ActivityType.task.rawValue,
                        status: "Not Started",
                        task: ActivityTaskNodeSummary(
                            activityTaskID: UUID().uuidString,
                            taskID: UUID().uuidString,
                            title: "New Activity",
                            description: ""
                        ),
                        image: nil
                    )
                )


        case .post:

            content =
                .post(
                    PostNodeContent(
                        postID: UUID().uuidString,
                        title: "New Post",
                        image: nil
                    )
                )


        case .media:

            content =
                .media(
                    MediaNodeContent(
                        mediaID: UUID().uuidString,
                        title: "New Media",
                        mediaType: .image,
                        urlString: nil,
                        image: nil
                    )
                )


        case .hyperlink:

            content =
                .hyperlink(
                    HyperlinkNodeContent(
                        title: "New Link",
                        urlString: "https://",
                        image: nil
                    )
                )
        }

        return GameMapNode(
            placement: placement,
            time: time,
            content: content
        )
    }


    // =====================================================
    // MARK: AddGameNodeView drafts
    // =====================================================

    static func make(
        addType: AddGameNodeType,
        placement: GameNodePlacement,
        time: DayTime? = nil
    ) -> GameMapNode {

        let resolvedTime =
            time
            ?? .startOfDay


        let content: GameNodeContent


        switch addType {

        case .meal:

            let activityID =
                UUID().uuidString

            content =
                .activity(
                    ActivityNodeContent(
                        activityID:
                            activityID,
                        title:
                            "New Meal",
                        startTime:
                            resolvedTime.displayClockString,
                        activityType:
                            ActivityNodeContent
                                .ActivityType
                                .meal
                                .rawValue,
                        status:
                            "Not Started",
                        meal:
                            ActivityMealNodeSummary(
                                suggestedMealID:
                                    UUID().uuidString,
                                title:
                                    "New Meal",
                                estimatedTimeMinutes:
                                    0,
                                priceRange:
                                    ""
                            ),
                        workout:
                            nil,
                        task:
                            nil,
                        image:
                            nil
                    )
                )


        case .workout:

            let activityID =
                UUID().uuidString

            content =
                .activity(
                    ActivityNodeContent(
                        activityID:
                            activityID,
                        title:
                            "New Workout",
                        startTime:
                            resolvedTime.displayClockString,
                        activityType:
                            ActivityNodeContent
                                .ActivityType
                                .workout
                                .rawValue,
                        status:
                            "Not Started",
                        meal:
                            nil,
                        workout:
                            ActivityWorkoutNodeSummary(
                                activityWorkoutID:
                                    UUID().uuidString,
                                workoutID:
                                    UUID().uuidString,
                                title:
                                    "New Workout",
                                location:
                                    "",
                                categories:
                                    [],
                                selectedWorkoutTime:
                                    resolvedTime.displayClockString,
                                durationInSeconds:
                                    0,
                                durationText:
                                    "",
                                distance:
                                    "",
                                workoutFormat:
                                    "",
                                rating:
                                    ""
                            ),
                        task:
                            nil,
                        image:
                            nil
                    )
                )


        case .task:

            let activityID =
                UUID().uuidString

            content =
                .activity(
                    ActivityNodeContent(
                        activityID:
                            activityID,
                        title:
                            "New Task",
                        startTime:
                            resolvedTime.displayClockString,
                        activityType:
                            ActivityNodeContent
                                .ActivityType
                                .task
                                .rawValue,
                        status:
                            "Not Started",
                        meal:
                            nil,
                        workout:
                            nil,
                        task:
                            ActivityTaskNodeSummary(
                                activityTaskID:
                                    UUID().uuidString,
                                taskID:
                                    UUID().uuidString,
                                title:
                                    "New Task",
                                description:
                                    ""
                            ),
                        image:
                            nil
                    )
                )


        case .tip:

            content =
                .post(
                    PostNodeContent(
                        snapshot:
                            makeNewPostSnapshot(
                                postType:
                                    "Tip"
                            )
                    )
                )


        case .request:

            content =
                .post(
                    PostNodeContent(
                        snapshot:
                            makeNewPostSnapshot(
                                postType:
                                    "Request"
                            )
                    )
                )
        }


        return GameMapNode(
            placement:
                placement,
            time:
                resolvedTime,
            content:
                content
        )
    }


    static func make(
        addType: AddGameNodeType,
        coordinate: MapCoordinate
    ) -> GameMapNode {

        make(
            addType:
                addType,
            placement:
                .coordinate(
                    coordinate
                ),
            time:
                coordinate.time
        )
    }


    private static func makeNewPostSnapshot(
        postType: String
    ) -> PostNodeSnapshot {

        let postID =
            UUID().uuidString


        let subject =
            "New \(postType)"


        return PostNodeSnapshot(
            postID:
                postID,
            postType:
                postType,
            subject:
                subject,
            postMainMediaURL:
                "",
            postMainMediaType:
                "",
            postMediaCount:
                0,
            postImageURLs:
                [],
            postVideoURLs:
                [],
            postGIFMedia:
                [:],
            posterID:
                "",
            posterName:
                "",
            posterImageURL:
                "",
            posterLocation:
                "",
            posterRole:
                "",
            posterConversationID:
                "",
            createdAt:
                ISO8601DateFormatter()
                    .string(
                        from:
                            Date()
                    ),
            status:
                "Active",
            tags:
                [],
            responderImageURLs:
                [],
            postResponseCount:
                0,
            postSavedCount:
                0,
            savedPostStatus:
                "",
            postMealID:
                "",
            postWorkoutID:
                "",
            postActivityID:
                "",
            postTaskID:
                ""
        )
    }


    /// Creates a user map node from a profile snapshot while keeping the
    /// marker title/image synchronized with that snapshot.
    static func makeUser(
        profile: UserProfileNodeSnapshot,
        placement: GameNodePlacement,
        time: DayTime? = nil
    ) -> GameMapNode {

        let cleanedImageURL =
            profile.imageURL
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )


        let image: GameNodeImage? =
            cleanedImageURL.isEmpty
            ? nil
            : .remote(
                urlString: cleanedImageURL
            )


        return GameMapNode(
            placement: placement,
            time: time,
            content:
                .user(
                    UserNodeContent(
                        userID: profile.userID,
                        displayName: profile.preferredDisplayName,
                        image: image,
                        profile: profile
                    )
                )
        )
    }


    static func makeUser(
        profile: UserProfileNodeSnapshot,
        coordinate: MapCoordinate
    ) -> GameMapNode {

        makeUser(
            profile: profile,
            placement:
                .coordinate(
                    coordinate
                ),
            time: coordinate.time
        )
    }


    /// Creates a read-only Post map node from the supplied Post snapshot.
    /// The snapshot drives the detail view while the preferred still image
    /// becomes the circular marker image.
    static func makePost(
        snapshot: PostNodeSnapshot,
        placement: GameNodePlacement,
        time: DayTime? = nil
    ) -> GameMapNode {

        GameMapNode(
            placement: placement,
            time: time,
            content:
                .post(
                    PostNodeContent(
                        snapshot: snapshot
                    )
                )
        )
    }


    static func makePost(
        snapshot: PostNodeSnapshot,
        coordinate: MapCoordinate
    ) -> GameMapNode {

        makePost(
            snapshot: snapshot,
            placement:
                .coordinate(
                    coordinate
                ),
            time: coordinate.time
        )
    }


    static func make(
        kind: GameNodeKind,
        coordinate: MapCoordinate
    ) -> GameMapNode {

        make(
            kind: kind,
            placement: .coordinate(
                coordinate
            ),
            time: coordinate.time
        )
    }
}
