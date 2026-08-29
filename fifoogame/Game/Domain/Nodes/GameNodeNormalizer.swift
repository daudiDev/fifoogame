//
//  GameNodeNormalizer.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/24/26.
//


import Foundation


enum GameNodeNormalizer {

    static func normalize(
        _ node: GameMapNode
    ) -> GameMapNode {

        var updated =
            node


        switch updated.content {

        case var .play(
            content
        ):

            content.title =
                clean(
                    content.title
                )

            if content.title.isEmpty {
                content.title = "Play"
            }

            updated.content =
                .play(
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


            if var profile =
                content.profile {

                profile.userID = clean(profile.userID)
                profile.username = clean(profile.username)
                profile.firstName = clean(profile.firstName)
                profile.lastName = clean(profile.lastName)
                profile.phone = clean(profile.phone)
                profile.joined = clean(profile.joined)
                profile.imageURL = clean(profile.imageURL)
                profile.goal = clean(profile.goal)
                profile.lastActive = clean(profile.lastActive)

                profile.inFollowersCount = max(0, profile.inFollowersCount)
                profile.outFollowersCount = max(0, profile.outFollowersCount)
                profile.tipsCount = max(0, profile.tipsCount)
                profile.responseCount = max(0, profile.responseCount)
                profile.requestCount = max(0, profile.requestCount)
                profile.progress = max(0, profile.progress)


                if profile.userID.isEmpty {
                    profile.userID = content.userID
                } else {
                    content.userID = profile.userID
                }


                let preferredName =
                    profile.preferredDisplayName

                if !preferredName.isEmpty {
                    content.displayName = preferredName
                }


                if !profile.imageURL.isEmpty {
                    content.image =
                        .remote(
                            urlString:
                                profile.imageURL
                        )
                }


                content.profile =
                    profile
            }


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

            content.date =
                clean(
                    content.date
                )

            // GameMapNode.time is the map's semantic source of truth for
            // the activity start time. Saving the editor keeps the Activity
            // snapshot synchronized with its vertical map position.
            content.startTime =
                updated.time
                    .displayClockString

            content.endTime =
                clean(
                    content.endTime
                )

            content.location =
                clean(
                    content.location
                )

            content.activityType =
                content.resolvedActivityType
                    .rawValue

            content.status =
                clean(
                    content.status
                )

            if content.status.isEmpty {

                content.status =
                    "Not Started"
            }


            if var meal =
                content.meal {

                meal.title =
                    clean(
                        meal.title
                    )

                meal.priceRange =
                    clean(
                        meal.priceRange
                    )

                meal.estimatedTimeMinutes =
                    max(
                        0,
                        meal.estimatedTimeMinutes
                    )

                if let imageURL =
                    meal.imageURL {

                    let cleanedImageURL =
                        clean(
                            imageURL
                        )

                    meal.imageURL =
                        cleanedImageURL.isEmpty
                        ? nil
                        : cleanedImageURL
                }

                if var user =
                    meal.user {

                    user.name = clean(user.name)
                    user.location = clean(user.location)
                    user.avatarURL = clean(user.avatarURL)
                    meal.user = user
                }

                if var meals =
                    meal.meals {

                    for index in
                        meals.indices {

                        meals[index].title = clean(meals[index].title)
                        meals[index].estimatedTimeMinutes = max(0, meals[index].estimatedTimeMinutes)
                        meals[index].recipeCount = max(0, meals[index].recipeCount)
                        meals[index].ingredientCount = max(0, meals[index].ingredientCount)
                        meals[index].sourceCount = max(0, meals[index].sourceCount)

                        if let imageURL = meals[index].imageURL {
                            let cleaned = clean(imageURL)
                            meals[index].imageURL = cleaned.isEmpty ? nil : cleaned
                        }

                        if let priceRange = meals[index].priceRange {
                            let cleaned = clean(priceRange)
                            meals[index].priceRange = cleaned.isEmpty ? nil : cleaned
                        }
                    }

                    meal.meals = meals
                }

                if var copyStatus = meal.copyStatus {
                    copyStatus.status = clean(copyStatus.status)
                    copyStatus.timestamp = clean(copyStatus.timestamp)
                    meal.copyStatus = copyStatus
                }

                if let createdAt = meal.createdAt {
                    let cleaned = clean(createdAt)
                    meal.createdAt = cleaned.isEmpty ? nil : cleaned
                }

                content.meal =
                    meal
            }


            if var workout =
                content.workout {

                workout.title = clean(workout.title)
                workout.location = clean(workout.location)
                workout.selectedWorkoutTime = clean(workout.selectedWorkoutTime)
                workout.durationText = clean(workout.durationText)
                workout.distance = clean(workout.distance)
                workout.workoutFormat = clean(workout.workoutFormat)
                workout.rating = clean(workout.rating)
                workout.categories =
                    workout.categories
                        .map { clean($0) }
                        .filter { !$0.isEmpty }

                workout.durationInSeconds =
                    max(
                        0,
                        workout.durationInSeconds
                    )

                if let description = workout.description {
                    let cleaned = clean(description)
                    workout.description = cleaned.isEmpty ? nil : cleaned
                }

                if let phone = workout.phone {
                    let cleaned = clean(phone)
                    workout.phone = cleaned.isEmpty ? nil : cleaned
                }

                if let website = workout.website {
                    let cleaned = clean(website)
                    workout.website = cleaned.isEmpty ? nil : cleaned
                }

                if let imageURLs = workout.imageURLs {
                    let cleanedURLs = uniqueMediaURLs(imageURLs)
                    workout.imageURLs = cleanedURLs.isEmpty ? nil : cleanedURLs
                }

                if let status = workout.workoutStatus {
                    let cleaned = clean(status)
                    workout.workoutStatus = cleaned.isEmpty ? nil : cleaned
                }

                if let count = workout.commentsCount {
                    workout.commentsCount = max(0, count)
                }

                if var trainer = workout.trainer {
                    trainer.name = clean(trainer.name)
                    trainer.location = clean(trainer.location)
                    trainer.userImageURL = clean(trainer.userImageURL)
                    trainer.userDescription = clean(trainer.userDescription)
                    trainer.onlineStatus = clean(trainer.onlineStatus)
                    trainer.rating = clean(trainer.rating)
                    workout.trainer = trainer
                }

                if var user = workout.user {
                    user.name = clean(user.name)
                    user.location = clean(user.location)
                    user.avatarURL = clean(user.avatarURL)
                    workout.user = user
                }

                if var copyStatus = workout.copyStatus {
                    copyStatus.status = clean(copyStatus.status)
                    copyStatus.timestamp = clean(copyStatus.timestamp)
                    workout.copyStatus = copyStatus
                }

                if let createdAt = workout.createdAt {
                    let cleaned = clean(createdAt)
                    workout.createdAt = cleaned.isEmpty ? nil : cleaned
                }

                content.workout =
                    workout
            }


            if var task =
                content.task {

                task.title =
                    clean(
                        task.title
                    )

                task.description =
                    clean(
                        task.description
                    )

                if let imageURLs = task.imageURLs {
                    let cleanedURLs = uniqueMediaURLs(imageURLs)
                    task.imageURLs = cleanedURLs.isEmpty ? nil : cleanedURLs
                }

                if let videoURLs = task.videoURLs {
                    let cleanedURLs = uniqueMediaURLs(videoURLs)
                    task.videoURLs = cleanedURLs.isEmpty ? nil : cleanedURLs
                }

                if var copyStatus = task.copyStatus {
                    copyStatus.status = clean(copyStatus.status)
                    copyStatus.timestamp = clean(copyStatus.timestamp)
                    task.copyStatus = copyStatus
                }

                content.task =
                    task
            }


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


            let activityType =
                content.activityType
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .lowercased()

            switch activityType {
            case "meal":
                if let imageURL = content.meal?.imageURL {
                    content.image = .remote(urlString: imageURL)
                }

            case "workout":
                if let imageURL = content.workout?.imageURLs?.first {
                    content.image = .remote(urlString: imageURL)
                }

            default:
                if let imageURL = content.task?.imageURLs?.first {
                    content.image = .remote(urlString: imageURL)
                }
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


            if var snapshot =
                content.snapshot
            {
                snapshot.postID = clean(snapshot.postID)
                snapshot.postType = clean(snapshot.postType)
                snapshot.subject = clean(snapshot.subject)
                snapshot.postMainMediaURL = clean(snapshot.postMainMediaURL)
                snapshot.postMainMediaType = clean(snapshot.postMainMediaType)
                snapshot.posterID = clean(snapshot.posterID)
                snapshot.posterName = clean(snapshot.posterName)
                snapshot.posterImageURL = clean(snapshot.posterImageURL)
                snapshot.posterLocation = clean(snapshot.posterLocation)
                snapshot.posterRole = clean(snapshot.posterRole)
                snapshot.posterConversationID = clean(snapshot.posterConversationID)
                snapshot.createdAt = clean(snapshot.createdAt)
                snapshot.status = clean(snapshot.status)
                snapshot.savedPostStatus = clean(snapshot.savedPostStatus)
                snapshot.postMealID = clean(snapshot.postMealID)
                snapshot.postWorkoutID = clean(snapshot.postWorkoutID)
                snapshot.postActivityID = clean(snapshot.postActivityID)
                snapshot.postTaskID = clean(snapshot.postTaskID)

                snapshot.postImageURLs =
                    uniqueMediaURLs(snapshot.postImageURLs)

                snapshot.postVideoURLs =
                    uniqueMediaURLs(snapshot.postVideoURLs)

                snapshot.tags =
                    snapshot.tags
                        .map { clean($0) }
                        .filter { !$0.isEmpty && $0.lowercased() != "none" }

                snapshot.responderImageURLs =
                    snapshot.responderImageURLs
                        .map { clean($0) }
                        .filter { !$0.isEmpty && $0.lowercased() != "none" }

                snapshot.postGIFMedia =
                    Dictionary(
                        uniqueKeysWithValues:
                            snapshot.postGIFMedia
                                .map {
                                    (
                                        clean($0.key),
                                        clean($0.value)
                                    )
                                }
                                .filter {
                                    !$0.0.isEmpty && !$0.1.isEmpty
                                }
                    )

                synchronizePostMediaMetadata(&snapshot)

                snapshot.postResponseCount =
                    max(
                        0,
                        snapshot.postResponseCount
                    )

                snapshot.postSavedCount =
                    max(
                        0,
                        snapshot.postSavedCount
                    )

                if var comments = snapshot.comments {
                    comments = comments.map { comment in
                        var cleanedComment = comment
                        cleanedComment.commentID = clean(comment.commentID)
                        cleanedComment.userID = clean(comment.userID)
                        cleanedComment.userName = clean(comment.userName)
                        cleanedComment.userImageURL = clean(comment.userImageURL)
                        cleanedComment.body = clean(comment.body)
                        cleanedComment.createdAt = clean(comment.createdAt)
                        cleanedComment.replyCount = max(0, comment.replyCount)
                        cleanedComment.likeCount = max(0, comment.likeCount)
                        return cleanedComment
                    }
                    .filter { !$0.body.isEmpty }

                    snapshot.comments = comments
                }


                if snapshot.postID.isEmpty {
                    snapshot.postID = content.postID
                } else {
                    content.postID = snapshot.postID
                }


                content.title =
                    snapshot.preferredTitle


                if let imageURL =
                    snapshot.preferredMarkerImageURL
                {
                    content.image =
                        .remote(
                            urlString:
                                imageURL
                        )
                } else {
                    content.image = nil
                }


                content.snapshot =
                    snapshot
            }


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


            if let urlString = content.urlString,
               content.mediaType == .image || content.mediaType == .gif {
                content.image = .remote(urlString: urlString)
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


    private static func uniqueMediaURLs(
        _ values: [String]
    ) -> [String] {

        var seen = Set<String>()

        return values.compactMap { value in
            let cleaned = clean(value)

            guard
                !cleaned.isEmpty,
                cleaned.lowercased() != "none",
                seen.insert(cleaned).inserted
            else {
                return nil
            }

            return cleaned
        }
    }


    private static func synchronizePostMediaMetadata(
        _ snapshot: inout PostNodeSnapshot
    ) {

        let gifCount = snapshot.postGIFMedia.isEmpty ? 0 : 1

        snapshot.postMediaCount =
            snapshot.postImageURLs.count
            + snapshot.postVideoURLs.count
            + gifCount

        if let firstImage = snapshot.postImageURLs.first {
            snapshot.postMainMediaURL = firstImage
            snapshot.postMainMediaType = "image"
            return
        }

        if let firstVideo = snapshot.postVideoURLs.first {
            snapshot.postMainMediaURL = firstVideo
            snapshot.postMainMediaType = "video"
            return
        }

        if !snapshot.postGIFMedia.isEmpty {
            snapshot.postMainMediaURL = preferredGIFURL(snapshot.postGIFMedia) ?? ""
            snapshot.postMainMediaType = "gif"
            return
        }

        snapshot.postMainMediaURL = ""
        snapshot.postMainMediaType = ""
    }


    private static func preferredGIFURL(
        _ metadata: [String: String]
    ) -> String? {

        for key in [
            "url",
            "gifURL",
            "gif_url",
            "originalURL",
            "original_url"
        ] {
            if let value = metadata[key] {
                let cleaned = clean(value)
                if !cleaned.isEmpty && cleaned.lowercased() != "none" {
                    return cleaned
                }
            }
        }

        if let id = metadata["id"] {
            let cleanedID = clean(id)
            if !cleanedID.isEmpty && cleanedID.lowercased() != "none" {
                return "https://media.giphy.com/media/\(cleanedID)/giphy.gif"
            }
        }

        return nil
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
