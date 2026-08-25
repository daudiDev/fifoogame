//
//  GameNodeContent.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/24/26.
//



import Foundation


// =====================================================
// MARK: - Node Kind
// =====================================================

enum GameNodeKind:
    String,
    Codable,
    CaseIterable,
    Sendable {

    case play
    case user
    case activity
    case post
    case media
    case hyperlink
}


extension GameNodeKind {

    var displayName: String {

        switch self {

        case .play:

            return "Play"


        case .user:

            return "User"


        case .activity:

            return "Activity"


        case .post:

            return "Post"


        case .media:

            return "Media"


        case .hyperlink:

            return "Hyperlink"
        }
    }


    var systemImageName: String {

        switch self {

        case .play:

            return "play.fill"


        case .user:

            return "person.crop.circle.fill"


        case .activity:

            return "figure.walk"


        case .post:

            return "bubble.left.and.bubble.right.fill"


        case .media:

            return "photo.on.rectangle.angled"


        case .hyperlink:

            return "link"
        }
    }


    var description: String {

        switch self {

        case .play:

            return "Open the full-screen Play experience."


        case .user:

            return "Place a user on the map."


        case .activity:

            return "Add an activity or action."


        case .post:

            return "Attach a post to the map."


        case .media:

            return "Add an image, video, or GIF."


        case .hyperlink:

            return "Add a link to external content."
        }
    }
}


// =====================================================
// MARK: - Node Image
// =====================================================

enum GameNodeImage:
    Codable,
    Equatable,
    Sendable {

    /// Image stored in Assets.xcassets.
    ///
    /// Example:
    /// .asset(name: "morningWalk")
    case asset(
        name: String
    )


    /// Remote image.
    ///
    /// Example:
    /// .remote(
    ///     urlString: "https://..."
    /// )
    case remote(
        urlString: String
    )


    /// Legacy SF Symbol source retained only so older persisted node data
    /// can still decode. Map markers no longer render SF Symbols; this
    /// case resolves to the node-type placeholder image.
    @available(*, deprecated, message: "Map nodes use asset/remote images. SF Symbols render as type placeholders.")
    case systemSymbol(
        name: String
    )
}

// =====================================================
// MARK: - Node Content
// =====================================================

enum GameNodeContent:
    Codable,
    Equatable,
    Sendable {

    case play(
        PlayNodeContent
    )

    case user(
        UserNodeContent
    )

    case activity(
        ActivityNodeContent
    )

    case post(
        PostNodeContent
    )

    case media(
        MediaNodeContent
    )

    case hyperlink(
        HyperlinkNodeContent
    )


    // MARK: Kind

    var kind: GameNodeKind {

        switch self {

        case .play:
            return .play

        case .user:
            return .user

        case .activity:
            return .activity

        case .post:
            return .post

        case .media:
            return .media

        case .hyperlink:
            return .hyperlink
        }
    }


    // MARK: Title

    var title: String {

        switch self {

        case let .play(content):
            return content.title

        case let .user(content):
            return content.displayName

        case let .activity(content):
            return content.title

        case let .post(content):
            return content.title

        case let .media(content):
            return content.title

        case let .hyperlink(content):
            return content.title
        }
    }


    // MARK: Image

    var image: GameNodeImage? {

        switch self {

        case let .play(content):
            return content.image

        case let .user(content):
            return content.image

        case let .activity(content):
            return content.image

        case let .post(content):
            return content.image

        case let .media(content):
            return content.image

        case let .hyperlink(content):
            return content.image
        }
    }
}

// =====================================================
// MARK: - Play
// =====================================================

struct PlayNodeContent:
    Codable,
    Equatable,
    Sendable {

    /// Display title shown beneath the map marker. Tapping the node itself
    /// never opens an editor; it requests the host PlayView instead.
    var title: String

    var image:
        GameNodeImage? = nil
}

// =====================================================
// MARK: - User
// =====================================================

/// Lightweight snapshot of the supplied `UserProfile` model.
///
/// The application's real `UserProfile` remains authoritative. The map keeps
/// a snapshot so the user node editor can present useful profile context
/// without depending on the networking/profile feature layer.
struct UserProfileNodeSnapshot:
    Codable,
    Equatable,
    Sendable {

    var userID: String
    var username: String
    var firstName: String
    var lastName: String
    var phone: String
    var joined: String
    var imageURL: String
    var goal: String
    var lastActive: String
    var inFollowersCount: Int
    var outFollowersCount: Int
    var topTipster: Bool
    var topRequester: Bool
    var topResponder: Bool
    var topContributor: Bool
    var tipsCount: Int
    var responseCount: Int
    var requestCount: Int
    var progress: Double


    var fullName: String {

        [
            firstName,
            lastName
        ]
        .map {
            $0.trimmingCharacters(
                in: .whitespacesAndNewlines
            )
        }
        .filter { !$0.isEmpty }
        .joined(separator: " ")
    }


    var preferredDisplayName: String {

        if !fullName.isEmpty {
            return fullName
        }

        let cleanedUsername =
            username.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        if !cleanedUsername.isEmpty {
            return cleanedUsername
        }

        return userID
    }


    /// Supports either a 0...1 progress value or a 0...100 percentage.
    var progressFraction: Double {

        let nonNegative =
            max(0, progress)

        if nonNegative <= 1 {
            return min(nonNegative, 1)
        }

        return min(nonNegative / 100, 1)
    }


    var progressPercent: Int {

        Int(
            (progressFraction * 100)
                .rounded()
        )
    }
}


struct UserNodeContent:
    Codable,
    Equatable,
    Sendable {

    var userID: String

    var displayName: String

    var image:
        GameNodeImage? = nil

    /// Optional for backward compatibility with user nodes saved before
    /// profile snapshots were added.
    var profile:
        UserProfileNodeSnapshot? = nil
}

// =====================================================
// MARK: - Activity editor summaries
// =====================================================

/// Lightweight map-editor snapshot of a user embedded by SuggestedMeal or
/// Workout. The application's full models remain authoritative.
struct ActivityUserNodeSummary:
    Codable,
    Equatable,
    Sendable {

    var userID: String
    var name: String
    var location: String
    var avatarURL: String
}


/// Lightweight snapshot of the copy metadata shared by SuggestedMeal,
/// Workout, and UserTask.
struct ActivityCopyStatusNodeSummary:
    Codable,
    Equatable,
    Sendable {

    var status: String
    var timestamp: String
}


/// A compact representation of one SuggestedMeal.Meal. Deep recipe,
/// ingredient, and source objects stay in the application model; the editor
/// keeps counts so the Activity Type section can still communicate the
/// structure of the meal.
struct ActivityMealItemNodeSummary:
    Codable,
    Equatable,
    Sendable,
    Identifiable {

    var id: String {
        mealID
    }

    var mealID: String
    var title: String
    var imageURL: String?
    var estimatedTimeMinutes: Int
    var priceRange: String?
    var recipeCount: Int
    var ingredientCount: Int
    var sourceCount: Int
}


/// Snapshot of the top-level SuggestedMeal properties that are useful on the
/// day map. This mirrors the supplied SuggestedMeal model without copying its
/// entire nested Recipe graph into GameMapNode.
struct ActivityMealNodeSummary:
    Codable,
    Equatable,
    Sendable {

    var suggestedMealID: String
    var title: String
    var estimatedTimeMinutes: Int
    var priceRange: String

    // Added after the first Activity editor pass. They are optional so
    // previously persisted map nodes continue to decode.
    var imageURL: String? = nil
    var user: ActivityUserNodeSummary? = nil
    var meals: [ActivityMealItemNodeSummary]? = nil
    var createdAt: String? = nil
    var copyStatus: ActivityCopyStatusNodeSummary? = nil
}


/// Compact Trainer snapshot matching the supplied Trainer model.
struct ActivityTrainerNodeSummary:
    Codable,
    Equatable,
    Sendable {

    var userID: String
    var name: String
    var location: String
    var userImageURL: String
    var userDescription: String
    var conversationID: String
    var onlineStatus: String
    var rating: String
}


/// Compact participant snapshot matching the supplied WorkoutParticipant
/// model.
struct ActivityWorkoutParticipantNodeSummary:
    Codable,
    Equatable,
    Sendable,
    Identifiable {

    var id: String {
        userID
    }

    var userID: String
    var name: String
    var userImage: String
    var userLocation: String
    var userRole: String
    var userBio: String
    var userConversationID: String
    var userStatus: String
    var statusDescription: String
    var nearestActivityTime: String
    var nearestActivityID: String
}


/// Map snapshot of the supplied Workout model. The original
/// `activityWorkoutID` is retained for backward compatibility with the older
/// ActivityWorkout-based node snapshot.
struct ActivityWorkoutNodeSummary:
    Codable,
    Equatable,
    Sendable {

    var activityWorkoutID: String
    var workoutID: String
    var title: String
    var location: String
    var categories: [String]
    var selectedWorkoutTime: String
    var durationInSeconds: Int
    var durationText: String
    var distance: String
    var workoutFormat: String
    var rating: String

    // Additional top-level Workout data from the supplied model.
    var imageURLs: [String]? = nil
    var description: String? = nil
    var trainer: ActivityTrainerNodeSummary? = nil
    var workoutStatus: String? = nil
    var commentsCount: Int? = nil
    var participants: [ActivityWorkoutParticipantNodeSummary]? = nil
    var createdAt: String? = nil
    var user: ActivityUserNodeSummary? = nil
    var copyStatus: ActivityCopyStatusNodeSummary? = nil
}


/// Map snapshot of the supplied UserTask model. `activityTaskID` is retained
/// for backward compatibility with the older ActivityTask-based snapshot.
struct ActivityTaskNodeSummary:
    Codable,
    Equatable,
    Sendable {

    var activityTaskID: String
    var taskID: String
    var title: String
    var description: String

    var imageURLs: [String]? = nil
    var videoURLs: [String]? = nil
    var copyStatus: ActivityCopyStatusNodeSummary? = nil
}


// =====================================================
// MARK: - Activity
// =====================================================

struct ActivityNodeContent:
    Codable,
    Equatable,
    Sendable {

    enum ActivityType:
        String,
        Codable,
        CaseIterable,
        Sendable {

        case meal
        case workout
        case task

        var displayName: String {

            rawValue.capitalized
        }
    }


    var activityID: String

    var title: String

    /// Mirrors `Activity.date` when the node is created from an Activity.
    /// Kept as a String because the application Activity model owns the
    /// authoritative date format.
    var date: String

    /// Mirrors `Activity.startTime`.
    /// The editor keeps this synchronized with `GameMapNode.time` whenever
    /// the activity is not locked to a road intersection.
    var startTime: String

    /// Mirrors `Activity.endTime`.
    var endTime: String

    var location: String

    var description: String?

    /// Activity is always one of meal / workout / task.
    /// Stored as String to stay compatible with the application's Activity
    /// model while `resolvedActivityType` provides a safe editor enum.
    var activityType: String

    /// Mirrors the application's Activity.status value.
    var status: String

    /// Exactly one of these is normally populated according to activityType.
    /// They intentionally contain only the subset shown by the map editor.
    var meal: ActivityMealNodeSummary?
    var workout: ActivityWorkoutNodeSummary?
    var task: ActivityTaskNodeSummary?

    var image:
        GameNodeImage? = nil


    init(
        activityID: String,
        title: String,
        date: String = "",
        startTime: String = "",
        endTime: String = "",
        location: String = "",
        description: String? = nil,
        activityType: String = ActivityType.task.rawValue,
        status: String = "Not Started",
        meal: ActivityMealNodeSummary? = nil,
        workout: ActivityWorkoutNodeSummary? = nil,
        task: ActivityTaskNodeSummary? = nil,
        image: GameNodeImage? = nil
    ) {

        self.activityID =
            activityID

        self.title =
            title

        self.date =
            date

        self.startTime =
            startTime

        self.endTime =
            endTime

        self.location =
            location

        self.description =
            description

        self.activityType =
            activityType

        self.status =
            status

        self.meal =
            meal

        self.workout =
            workout

        self.task =
            task

        self.image =
            image
    }


    var resolvedActivityType:
        ActivityType {

        ActivityType(
            rawValue:
                activityType
                    .trimmingCharacters(
                        in:
                            .whitespacesAndNewlines
                    )
                    .lowercased()
        )
        ?? .task
    }


    var activityTypeDisplayName:
        String {

        resolvedActivityType
            .displayName
    }
}


extension ActivityNodeContent {

    /// Convenience initializer for the top-level Activity fields supplied by
    /// the application model. A non-empty mainImageURL automatically becomes
    /// the node's remote marker image; an empty URL falls back to the
    /// Activity-specific placeholder image.
    init(
        activityID: String,
        title: String,
        date: String,
        startTime: String,
        endTime: String,
        location: String,
        description: String,
        mainImageURL: String,
        activityType: String,
        status: String,
        meal: ActivityMealNodeSummary? = nil,
        workout: ActivityWorkoutNodeSummary? = nil,
        task: ActivityTaskNodeSummary? = nil
    ) {

        let cleanedImageURL =
            mainImageURL
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )

        self.init(
            activityID:
                activityID,
            title:
                title,
            date:
                date,
            startTime:
                startTime,
            endTime:
                endTime,
            location:
                location,
            description:
                description.isEmpty
                ? nil
                : description,
            activityType:
                activityType,
            status:
                status,
            meal:
                meal,
            workout:
                workout,
            task:
                task,
            image:
                cleanedImageURL.isEmpty
                ? nil
                : .remote(
                    urlString:
                        cleanedImageURL
                )
        )
    }
}


// =====================================================
// MARK: - Backward-compatible Activity Codable
// =====================================================

extension ActivityNodeContent {

    private enum CodingKeys:
        String,
        CodingKey {

        case activityID
        case title
        case date
        case startTime
        case endTime
        case location
        case description
        case activityType
        case status
        case meal
        case workout
        case task
        case image
    }


    init(
        from decoder: Decoder
    ) throws {

        let container =
            try decoder.container(
                keyedBy:
                    CodingKeys.self
            )

        activityID =
            try container.decode(
                String.self,
                forKey:
                    .activityID
            )

        title =
            try container.decode(
                String.self,
                forKey:
                    .title
            )

        date =
            try container.decodeIfPresent(
                String.self,
                forKey:
                    .date
            )
            ?? ""

        startTime =
            try container.decodeIfPresent(
                String.self,
                forKey:
                    .startTime
            )
            ?? ""

        endTime =
            try container.decodeIfPresent(
                String.self,
                forKey:
                    .endTime
            )
            ?? ""

        location =
            try container.decodeIfPresent(
                String.self,
                forKey:
                    .location
            )
            ?? ""

        description =
            try container.decodeIfPresent(
                String.self,
                forKey:
                    .description
            )

        activityType =
            try container.decodeIfPresent(
                String.self,
                forKey:
                    .activityType
            )
            ?? ActivityType.task.rawValue

        status =
            try container.decodeIfPresent(
                String.self,
                forKey:
                    .status
            )
            ?? "Not Started"

        meal =
            try container.decodeIfPresent(
                ActivityMealNodeSummary.self,
                forKey:
                    .meal
            )

        workout =
            try container.decodeIfPresent(
                ActivityWorkoutNodeSummary.self,
                forKey:
                    .workout
            )

        task =
            try container.decodeIfPresent(
                ActivityTaskNodeSummary.self,
                forKey:
                    .task
            )

        image =
            try container.decodeIfPresent(
                GameNodeImage.self,
                forKey:
                    .image
            )
    }


    func encode(
        to encoder: Encoder
    ) throws {

        var container =
            encoder.container(
                keyedBy:
                    CodingKeys.self
            )

        try container.encode(
            activityID,
            forKey:
                .activityID
        )

        try container.encode(
            title,
            forKey:
                .title
        )

        try container.encode(
            date,
            forKey:
                .date
        )

        try container.encode(
            startTime,
            forKey:
                .startTime
        )

        try container.encode(
            endTime,
            forKey:
                .endTime
        )

        try container.encode(
            location,
            forKey:
                .location
        )

        try container.encodeIfPresent(
            description,
            forKey:
                .description
        )

        try container.encode(
            activityType,
            forKey:
                .activityType
        )

        try container.encode(
            status,
            forKey:
                .status
        )

        try container.encodeIfPresent(
            meal,
            forKey:
                .meal
        )

        try container.encodeIfPresent(
            workout,
            forKey:
                .workout
        )

        try container.encodeIfPresent(
            task,
            forKey:
                .task
        )

        try container.encodeIfPresent(
            image,
            forKey:
                .image
        )
    }
}


// =====================================================
// MARK: - Post
// =====================================================

/// Read-only snapshot of the application's `Post` model.
///
/// The social/post feature remains authoritative. The map keeps this snapshot
/// so tapping a Post node can present a complete, useful detail experience
/// without coupling the map package to SocketClient, Giphy, or the post feed.
struct PostNodeSnapshot:
    Codable,
    Equatable,
    Sendable {

    var postID: String
    var postType: String
    var subject: String
    var postMainMediaURL: String
    var postMainMediaType: String
    var postMediaCount: Int
    var postImageURLs: [String]
    var postVideoURLs: [String]
    var postGIFMedia: [String: String]
    var posterID: String
    var posterName: String
    var posterImageURL: String
    var posterLocation: String
    var posterRole: String
    var posterConversationID: String
    var createdAt: String
    var status: String
    var tags: [String]
    var responderImageURLs: [String]
    var postResponseCount: Int
    var postSavedCount: Int
    var savedPostStatus: String
    var postMealID: String
    var postWorkoutID: String
    var postActivityID: String
    var postTaskID: String


    init(
        postID: String,
        postType: String,
        subject: String,
        postMainMediaURL: String,
        postMainMediaType: String,
        postMediaCount: Int,
        postImageURLs: [String],
        postVideoURLs: [String],
        postGIFMedia: [String: String],
        posterID: String,
        posterName: String,
        posterImageURL: String,
        posterLocation: String,
        posterRole: String,
        posterConversationID: String,
        createdAt: String,
        status: String,
        tags: [String],
        responderImageURLs: [String],
        postResponseCount: Int,
        postSavedCount: Int,
        savedPostStatus: String,
        postMealID: String,
        postWorkoutID: String,
        postActivityID: String,
        postTaskID: String
    ) {

        self.postID = postID
        self.postType = postType
        self.subject = subject
        self.postMainMediaURL = postMainMediaURL
        self.postMainMediaType = postMainMediaType
        self.postMediaCount = postMediaCount
        self.postImageURLs = postImageURLs
        self.postVideoURLs = postVideoURLs
        self.postGIFMedia = postGIFMedia
        self.posterID = posterID
        self.posterName = posterName
        self.posterImageURL = posterImageURL
        self.posterLocation = posterLocation
        self.posterRole = posterRole
        self.posterConversationID = posterConversationID
        self.createdAt = createdAt
        self.status = status
        self.tags = tags
        self.responderImageURLs = responderImageURLs
        self.postResponseCount = postResponseCount
        self.postSavedCount = postSavedCount
        self.savedPostStatus = savedPostStatus
        self.postMealID = postMealID
        self.postWorkoutID = postWorkoutID
        self.postActivityID = postActivityID
        self.postTaskID = postTaskID
    }


    /// Handles both the singular values used by the existing feed (Tip /
    /// Request) and plural API values (Tips / Requests).
    var postTypeDisplayName: String {

        let cleaned =
            postType
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

        let lowered = cleaned.lowercased()

        if lowered.contains("request") {
            return "Request"
        }

        if lowered.contains("tip") {
            return "Tip"
        }

        return cleaned.isEmpty
            ? "Post"
            : cleaned
    }


    var preferredTitle: String {

        let cleanedSubject =
            subject
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

        if !cleanedSubject.isEmpty &&
            cleanedSubject.lowercased() != "none"
        {
            return cleanedSubject
        }

        return "\(postTypeDisplayName) Post"
    }


    /// Best still image for the circular map marker. Videos are never used
    /// directly as marker imagery.
    var preferredMarkerImageURL: String? {

        func usable(_ value: String) -> String? {

            let cleaned =
                value
                    .trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )

            guard
                !cleaned.isEmpty,
                cleaned.lowercased() != "none"
            else {
                return nil
            }

            return cleaned
        }

        let mediaType =
            postMainMediaType
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
                .lowercased()

        if mediaType == "image" || mediaType == "gif" {
            if let main = usable(postMainMediaURL) {
                return main
            }
        }

        if let firstImage =
            postImageURLs
                .compactMap(usable)
                .first
        {
            return firstImage
        }

        return usable(posterImageURL)
    }


    var isSaved: Bool {

        let lowered =
            savedPostStatus
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
                .lowercased()

        return !lowered.isEmpty &&
            lowered != "none" &&
            lowered != "canceled" &&
            lowered != "cancelled"
    }
}


struct PostNodeContent:
    Codable,
    Equatable,
    Sendable {

    var postID: String

    var title: String

    var image:
        GameNodeImage? = nil

    /// Present when this node was created from a real Post model. Older map
    /// nodes remain decodable because this value is optional.
    var snapshot:
        PostNodeSnapshot? = nil


    init(
        postID: String,
        title: String,
        image: GameNodeImage? = nil,
        snapshot: PostNodeSnapshot? = nil
    ) {

        self.postID = postID
        self.title = title
        self.image = image
        self.snapshot = snapshot
    }


    init(
        snapshot: PostNodeSnapshot
    ) {

        self.postID =
            snapshot.postID

        self.title =
            snapshot.preferredTitle

        self.snapshot =
            snapshot

        if let imageURL =
            snapshot.preferredMarkerImageURL
        {
            self.image =
                .remote(
                    urlString:
                        imageURL
                )
        } else {
            self.image = nil
        }
    }
}

// =====================================================
// MARK: - Media
// =====================================================

struct MediaNodeContent:
    Codable,
    Equatable,
    Sendable {

    enum MediaType:
        String,
        Codable,
        Sendable {

        case image
        case video
        case gif
    }


    var mediaID: String

    var title: String

    var mediaType:
        MediaType

    /// Actual image/video/GIF content.
    var urlString:
        String?

    /// Thumbnail / marker image used
    /// to visually represent the node.
    var image:
        GameNodeImage? = nil
}

// =====================================================
// MARK: - Hyperlink
// =====================================================

struct HyperlinkNodeContent:
    Codable,
    Equatable,
    Sendable {

    var title: String

    var urlString: String

    var image:
        GameNodeImage? = nil
}

