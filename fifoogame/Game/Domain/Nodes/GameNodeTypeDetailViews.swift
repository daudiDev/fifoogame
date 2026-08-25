//
//  GameNodeTypeDetailViews.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/24/26.
//



import SwiftUI
import UIKit


struct GameNodeTypeDetailViews: View {
    var body: some View {
        Text("Hello, World!")
    }
}


// =====================================================
// MARK: - Shared Node Image
// =====================================================

private struct NodeDetailImage: View {

    let kind: GameNodeKind
    let image: GameNodeImage?
    var size: CGFloat = 76


    var body: some View {

        resolvedImage
            .frame(
                width: size,
                height: size
            )
            .clipShape(
                Circle()
            )
            .overlay {

                Circle()
                    .stroke(
                        .white.opacity(0.25),
                        lineWidth: 1.5
                    )
            }
    }


    @ViewBuilder
    private var resolvedImage: some View {

        switch image {

        case let .asset(name):

            if let uiImage = UIImage(
                named: name
            ) {

                Image(
                    uiImage: uiImage
                )
                .resizable()
                .scaledToFill()

            } else {

                placeholder
            }


        case let .remote(urlString):

            if let url = URL(
                string: urlString
            ) {

                AsyncImage(
                    url: url
                ) { phase in

                    switch phase {

                    case .empty:

                        ZStack {
                            placeholder
                            ProgressView()
                                .tint(.white)
                        }

                    case let .success(image):

                        image
                            .resizable()
                            .scaledToFill()

                    case .failure:

                        placeholder

                    @unknown default:

                        placeholder
                    }
                }

            } else {

                placeholder
            }


        case .systemSymbol,
             nil:

            // Legacy system-symbol data intentionally resolves to the
            // node-type raster placeholder instead of rendering an icon.
            placeholder
        }
    }


    private var placeholder: some View {

        Image(
            uiImage:
                GameNodePlaceholderImage.image(
                    for: kind
                )
        )
        .resizable()
        .scaledToFill()
    }
}



// =====================================================
// MARK: - User
// =====================================================

struct UserNodeDetailView: View {

    let content: UserNodeContent

    var body: some View {

        ScrollView {

            VStack(
                alignment: .leading,
                spacing: 18
            ) {

                HStack(
                    spacing: 14
                ) {

                    NodeDetailImage(
                        kind: .user,
                        image: content.image,
                        size: 80
                    )

                    VStack(
                        alignment: .leading,
                        spacing: 4
                    ) {

                        Text(
                            content.profile?.preferredDisplayName
                            ?? content.displayName
                        )
                        .font(.title2)
                        .fontWeight(.semibold)

                        if let username =
                            content.profile?.username,
                           !username.isEmpty {

                            Text(
                                username.hasPrefix("@")
                                ? username
                                : "@\(username)"
                            )
                            .foregroundStyle(.secondary)
                        }
                    }
                }


                if let profile =
                    content.profile {

                    if !profile.goal.isEmpty {
                        Text(profile.goal)
                    }

                    VStack(
                        alignment: .leading,
                        spacing: 8
                    ) {

                        HStack {
                            Text("Progress")
                            Spacer()
                            Text("\(profile.progressPercent)%")
                                .fontWeight(.semibold)
                                .monospacedDigit()
                        }

                        ProgressView(
                            value: profile.progressFraction
                        )
                    }

                    LabeledContent(
                        "Followers",
                        value: "\(profile.inFollowersCount)"
                    )

                    LabeledContent(
                        "Following",
                        value: "\(profile.outFollowersCount)"
                    )

                    if !profile.lastActive.isEmpty {
                        LabeledContent(
                            "Last Active",
                            value: profile.lastActive
                        )
                    }
                }


                Divider()

                Text("User ID")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(
                    content.userID
                )
                .font(.caption.monospaced())
            }
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
            .padding()
        }
    }
}


// =====================================================
// MARK: - Activity
// =====================================================

struct ActivityNodeDetailView: View {

    let content: ActivityNodeContent

    var body: some View {

        ScrollView {

            VStack(
                alignment: .leading,
                spacing: 18
            ) {

                NodeDetailImage(
                    kind: .activity,
                    image: content.image,
                    size: 72
                )

                Text(
                    content.title
                )
                .font(.title2)
                .fontWeight(.bold)

                HStack(spacing: 8) {

                    Text(
                        content.activityTypeDisplayName
                    )
                    .font(.caption)
                    .fontWeight(.semibold)

                    if !content.status.isEmpty {

                        Text("•")
                            .foregroundStyle(.secondary)

                        Text(
                            content.status
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }

                if !content.startTime.isEmpty || !content.endTime.isEmpty {

                    LabeledContent("Time") {

                        Text(
                            [
                                content.startTime,
                                content.endTime
                            ]
                            .filter { !$0.isEmpty }
                            .joined(separator: " – ")
                        )
                    }
                }

                if !content.location.isEmpty {

                    LabeledContent(
                        "Location",
                        value: content.location
                    )
                }

                if let description = content.description {
                    Text(description)
                }

                Divider()

                Text("Activity ID")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(
                    content.activityID
                )
                .font(.caption.monospaced())
            }
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
            .padding()
        }
    }
}


// =====================================================
// MARK: - Post
// =====================================================

struct PostNodeDetailView: View {

    let content: PostNodeContent

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 18
        ) {

            NodeDetailImage(
                kind: .post,
                image: content.image,
                size: 68
            )

            Text(
                content.title
            )
            .font(.title2)
            .fontWeight(.bold)

            Divider()

            Text("Post ID")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(
                content.postID
            )
            .font(.caption.monospaced())

            Spacer()
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .padding()
    }
}


// =====================================================
// MARK: - Hyperlink
// =====================================================

struct HyperlinkNodeDetailView: View {

    let content: HyperlinkNodeContent

    var body: some View {

        VStack(
            spacing: 16
        ) {

            NodeDetailImage(
                kind: .hyperlink,
                image: content.image,
                size: 68
            )

            Text(
                content.title
            )
            .font(.title2)

            Text(
                content.urlString
            )
            .font(.caption.monospaced())
            .foregroundStyle(.secondary)
        }
        .padding()
    }
}


// =====================================================
// MARK: - Media Metadata
// =====================================================

struct MediaNodeMetadataView: View {

    let content: MediaNodeContent

    var body: some View {

        VStack(
            spacing: 16
        ) {

            NodeDetailImage(
                kind: .media,
                image: content.image,
                size: 72
            )

            Text(
                content.title
            )
            .font(.title2)

            Text(
                content.mediaType.rawValue.capitalized
            )
            .foregroundStyle(.secondary)
        }
        .padding()
    }
}
