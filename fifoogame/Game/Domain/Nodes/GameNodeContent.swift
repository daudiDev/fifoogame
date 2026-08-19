//
//  GameNodeContent.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/19/26.
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

    case label
    case user
    case activity
    case post
    case media
    case hyperlink
}


extension GameNodeKind {

    var displayName: String {

        switch self {

        case .label:

            return "Label"


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

        case .label:

            return "tag.fill"


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

        case .label:

            return "Add text or a label to the map."


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


    /// SF Symbol.
    ///
    /// Example:
    /// .systemSymbol(
    ///     name: "figure.walk"
    /// )
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

    case label(
        LabelNodeContent
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

        case .label:
            return .label

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

        case let .label(content):
            return content.text

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

        case let .label(content):
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
// MARK: - Label
// =====================================================

struct LabelNodeContent:
    Codable,
    Equatable,
    Sendable {

    var text: String

    var image:
        GameNodeImage? = nil
}

// =====================================================
// MARK: - User
// =====================================================

struct UserNodeContent:
    Codable,
    Equatable,
    Sendable {

    var userID: String

    var displayName: String

    var image:
        GameNodeImage? = nil
}

// =====================================================
// MARK: - Activity
// =====================================================

struct ActivityNodeContent:
    Codable,
    Equatable,
    Sendable {

    var activityID: String

    var title: String

    var description: String?

    var image:
        GameNodeImage? = nil
}

// =====================================================
// MARK: - Post
// =====================================================

struct PostNodeContent:
    Codable,
    Equatable,
    Sendable {

    var postID: String

    var title: String

    var image:
        GameNodeImage? = nil
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

