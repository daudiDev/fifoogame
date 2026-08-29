//
//  SampleGameNodes.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/24/26.
//


import Foundation


enum SampleGameNodes {

    static func make() -> [GameMapNode] {

        [

            // MARK: - ActivityWorkout — Independent

            GameMapNode(
                placement:
                    .coordinate(
                        coordinate(
                            hour: 2.0,
                            progress: 12
                        )
                    ),
                time:
                    dayTime(
                        hour: 2.0
                    ),
                content:
                    .activity(
                        ActivityNodeContent(
                            activityID: "sample-independent-workout-001",
                            title: "Fifoo Strength Session",
                            date: "8/23/26",
                            startTime: "2:00 AM",
                            endTime: "2:45 AM",
                            location: "Home Gym",
                            description: "Independent full-body strength workout in Fifoo Play.",
                            activityType: ActivityNodeContent.ActivityType.workout.rawValue,
                            status: "Not Started",
                            workout: ActivityWorkoutNodeSummary(
                                activityWorkoutID: "activity-workout-independent-001",
                                workoutID: "workout-independent-001",
                                title: "Fifoo Strength Session",
                                location: "Home Gym",
                                categories: ["Strength", "Full Body"],
                                selectedWorkoutTime: "2:00 AM",
                                durationInSeconds: 2700,
                                durationText: "45 min",
                                distance: "",
                                workoutFormat: "Independent",
                                rating: "4.8",
                                workoutType: .independent,
                                imageURLs: ["https://picsum.photos/seed/fifoo-strength/900/900"],
                                description: "Independent full-body strength workout in Fifoo Play."
                            ),
                            image: .remote(
                                urlString: "https://picsum.photos/seed/fifoo-strength/900/900"
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
                time:
                    dayTime(
                        hour: 3.0
                    ),
                content:
                    .activity(
                        ActivityNodeContent(
                            activityID: "morning-walk",
                            title: "Morning Walk",
                            date: "8/23/26",
                            startTime: "3:00 AM",
                            endTime: "3:30 AM",
                            location: "Neighborhood",
                            description: "Start the day with a walk.",
                            activityType: ActivityNodeContent.ActivityType.task.rawValue,
                            status: "Not Started",
                            task: ActivityTaskNodeSummary(
                                activityTaskID: "activity-task-morning-walk",
                                taskID: "task-morning-walk",
                                title: "Morning Walk",
                                description: "Walk for thirty minutes."
                            ),
                            image: nil
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
                time:
                    dayTime(
                        hour: 6.0
                    ),
                content:
                    .post(
                        PostNodeContent(
                            snapshot:
                                PostNodeSnapshot(
                                    postID: "sample-post-001",
                                    postType: "Tip",
                                    subject: "A short walk after lunch helped me reset and stay on track today.",
                                    postMainMediaURL: "https://picsum.photos/900/700",
                                    postMainMediaType: "image",
                                    postMediaCount: 2,
                                    postImageURLs: [
                                        "https://picsum.photos/900/700",
                                        "https://picsum.photos/901/700"
                                    ],
                                    postVideoURLs: [],
                                    postGIFMedia: [:],
                                    posterID: "sample-user-001",
                                    posterName: "Alex Morgan",
                                    posterImageURL: "https://res.cloudinary.com/dgowl1p3x/image/upload/v1695991790/bots/male_agent_1.jpg",
                                    posterLocation: "Baltimore, MD",
                                    posterRole: "Member",
                                    posterConversationID: "sample-conversation-001",
                                    createdAt: "2026-08-25T10:15:00-04:00",
                                    status: "Active",
                                    tags: [
                                        "walking",
                                        "consistency",
                                        "progress"
                                    ],
                                    responderImageURLs: [],
                                    postResponseCount: 4,
                                    postSavedCount: 12,
                                    savedPostStatus: "Saved",
                                    postMealID: "",
                                    postWorkoutID: "sample-workout-001",
                                    postActivityID: "",
                                    postTaskID: "",
                                    comments: [
                                        PostNodeCommentSnapshot(
                                            commentID: "sample-comment-001",
                                            userID: "sample-user-002",
                                            userName: "Maya",
                                            userImageURL: "https://i.pravatar.cc/160?img=47",
                                            body: "I started doing this after lunch too. Even ten minutes makes a big difference.",
                                            createdAt: "2026-08-25T10:42:00-04:00",
                                            replyCount: 2,
                                            likeCount: 18,
                                            isPinned: true
                                        ),
                                        PostNodeCommentSnapshot(
                                            commentID: "sample-comment-002",
                                            userID: "sample-user-003",
                                            userName: "Jordan",
                                            userImageURL: "https://i.pravatar.cc/160?img=12",
                                            body: "Good reminder. I usually overthink the workout instead of just getting outside.",
                                            createdAt: "2026-08-25T11:08:00-04:00",
                                            replyCount: 0,
                                            likeCount: 7
                                        ),
                                        PostNodeCommentSnapshot(
                                            commentID: "sample-comment-003",
                                            userID: "sample-user-004",
                                            userName: "Nia",
                                            userImageURL: "https://i.pravatar.cc/160?img=32",
                                            body: "Trying this today 🙌",
                                            createdAt: "2026-08-25T11:31:00-04:00",
                                            replyCount: 1,
                                            likeCount: 5
                                        )
                                    ]
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
                time:
                    dayTime(
                        hour: 15.4
                    ),
                content:
                    .media(
                        MediaNodeContent(
                            mediaID: "sample-media-001",
                            title: "Workout Clip",
                            mediaType: .video,
                            urlString: nil,
                            image: nil
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
                time:
                    dayTime(
                        hour: 10.5
                    ),
                content:
                    .user(
                        UserNodeContent(
                            userID: "sample-user-001",
                            displayName: "Alex Morgan",
                            image: nil,
                            profile:
                                UserProfileNodeSnapshot(
                                    userID: "sample-user-001",
                                    username: "alexm",
                                    firstName: "Alex",
                                    lastName: "Morgan",
                                    phone: "(555) 010-1200",
                                    joined: "Jan 12, 2026",
                                    imageURL: "https://res.cloudinary.com/dgowl1p3x/image/upload/v1695991790/bots/male_agent_1.jpg",
                                    goal: "Build a consistent daily fitness routine.",
                                    lastActive: "Today, 10:18 AM",
                                    inFollowersCount: 428,
                                    outFollowersCount: 193,
                                    topTipster: true,
                                    topRequester: false,
                                    topResponder: true,
                                    topContributor: true,
                                    tipsCount: 86,
                                    responseCount: 142,
                                    requestCount: 31,
                                    progress: 0.64
                                )
                        )
                    )
            ),


            // MARK: - ActivityWorkout — Guided Class — 6:30 PM / 50%

            GameMapNode(
                placement:
                    .coordinate(
                        coordinate(
                            hour: 18.5,
                            progress: 50
                        )
                    ),
                time:
                    dayTime(
                        hour: 18.5
                    ),
                content:
                    .activity(
                        ActivityNodeContent(
                            activityID: "sample-guided-workout-001",
                            title: "HIIT Studio Class",
                            date: "8/23/26",
                            startTime: "6:30 PM",
                            endTime: "7:30 PM",
                            location: "Harbor Fitness Studio",
                            description: "Instructor-led HIIT class with fixed class time.",
                            activityType: ActivityNodeContent.ActivityType.workout.rawValue,
                            status: "Not Started",
                            workout: ActivityWorkoutNodeSummary(
                                activityWorkoutID: "activity-workout-class-001",
                                workoutID: "workout-class-001",
                                title: "HIIT Studio Class",
                                location: "Harbor Fitness Studio",
                                categories: ["HIIT", "Cardio"],
                                selectedWorkoutTime: "6:30 PM",
                                durationInSeconds: 3600,
                                durationText: "60 min",
                                distance: "2.1 mi",
                                workoutFormat: "Class",
                                rating: "4.9",
                                workoutType: .guidedClass,
                                imageURLs: ["https://picsum.photos/seed/hiit-studio-class/900/900"],
                                description: "Instructor-led HIIT class with fixed class time.",
                                phone: "(410) 555-0125",
                                website: "https://harborfitness.example/hiit",
                                trainer: ActivityTrainerNodeSummary(
                                    userID: "trainer-maya-001",
                                    name: "Maya Chen",
                                    location: "Harbor Fitness Studio",
                                    userImageURL: "https://picsum.photos/seed/trainer-maya/300/300",
                                    userDescription: "HIIT and conditioning coach.",
                                    conversationID: "conversation-trainer-maya",
                                    onlineStatus: "Online",
                                    rating: "4.9"
                                ),
                                workoutStatus: "Scheduled"
                            ),
                            image: .remote(
                                urlString: "https://picsum.photos/seed/hiit-studio-class/900/900"
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
                time:
                    dayTime(
                        hour: 21.3
                    ),
                content:
                    .hyperlink(
                        HyperlinkNodeContent(
                            title: "Nutrition Guide",
                            urlString: "https://example.com",
                            image: nil
                        )
                    )
            )
        ]
    }


    // MARK: - Helpers

    private static func coordinate(
        hour: Double,
        progress: Double
    ) -> MapCoordinate {

        MapCoordinate(
            time: dayTime(
                hour: hour
            ),
            progress: MapProgress(
                progress
            )
        )
    }


    private static func dayTime(
        hour: Double
    ) -> DayTime {

        DayTime(
            secondsFromMidnight:
                hour * 3600
        )
    }
}
