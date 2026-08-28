//
//  GameNodePostView.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/24/26.
//



import SwiftUI
import AVKit
import WebKit
import UIKit


// =====================================================
// MARK: - Host App Actions
// =====================================================

enum PostNodeLinkedContent:
    Equatable,
    Sendable {

    case meal(String)
    case workout(String)
    case activity(String)
    case task(String)


    var title: String {

        switch self {

        case .meal:
            return "View Meal Details"

        case .workout:
            return "View Workout Details"

        case .activity:
            return "View Activity Details"

        case .task:
            return "View Task Details"
        }
    }


    var systemImageName: String {

        switch self {

        case .meal:
            return "fork.knife"

        case .workout:
            return "figure.strengthtraining.traditional"

        case .activity:
            return "calendar"

        case .task:
            return "checklist"
        }
    }
}


enum PostNodeViewAction:
    Equatable,
    Sendable {

    case respond
    case save
    case viewPoster
    case viewLinkedContent(PostNodeLinkedContent)
}


// =====================================================
// MARK: - Post Detail View
// =====================================================

/// Read-only Post-node presentation.
///
/// Existing Post nodes intentionally do not open `GameNodeEditorView`.
/// The real social/post feature owns edits. This view presents the map's
/// `PostNodeSnapshot` and exposes navigation/action hooks back to the host app.
struct GameNodePostView: View {

    let node:
        GameMapNode


    let onAction:
        ((PostNodeViewAction, GameMapNode) -> Void)?


    @Environment(\.dismiss)
    private var dismiss


    init(
        node: GameMapNode,
        onAction: ((PostNodeViewAction, GameMapNode) -> Void)? = nil
    ) {

        self.node =
            node

        self.onAction =
            onAction
    }


    var body: some View {

        NavigationStack {

            Group {

                if case let .post(
                    content
                ) = node.content {

                    if let snapshot =
                        content.snapshot
                    {

                        postContent(
                            snapshot
                        )

                    } else {

                        legacyPostContent(
                            content
                        )
                    }

                } else {

                    ContentUnavailableView(
                        "Post Unavailable",
                        systemImage:
                            "exclamationmark.bubble",
                        description:
                            Text(
                                "This map stop does not contain Post content."
                            )
                    )
                }
            }
            .navigationTitle(
                navigationTitle
            )
            .navigationBarTitleDisplayMode(
                .inline
            )
            .toolbar {

                ToolbarItem(
                    placement:
                        .cancellationAction
                ) {

                    Button(
                        "Cancel"
                    ) {

                        dismiss()
                    }
                }
            }
        }
    }
}


// =====================================================
// MARK: - Main Snapshot Content
// =====================================================

private extension GameNodePostView {

    func postContent(
        _ post:
            PostNodeSnapshot
    ) -> some View {

        ScrollView(
            showsIndicators:
                false
        ) {

            VStack(
                spacing:
                    16
            ) {

                posterSection(
                    post
                )


                subjectSection(
                    post
                )


                if hasMainMedia(
                    post
                ) {

                    mediaSection(
                        post
                    )
                }


                let linked =
                    linkedContent(
                        post
                    )

                if !linked.isEmpty {

                    linkedContentSection(
                        linked
                    )
                }


                engagementSection(
                    post
                )


                if !post.tags.isEmpty {

                    tagsSection(
                        post.tags
                    )
                }


                postInfoSection(
                    post
                )
            }
            .padding(
                .horizontal,
                16
            )
            .padding(
                .top,
                12
            )
            .padding(
                .bottom,
                20
            )
        }
        .background(
            Color(
                uiColor:
                    .systemGroupedBackground
            )
        )
        .safeAreaInset(
            edge:
                .bottom,
            spacing:
                0
        ) {

            postActionBar(
                post
            )
        }
    }


    func legacyPostContent(
        _ content:
            PostNodeContent
    ) -> some View {

        ScrollView {

            VStack(
                spacing:
                    18
            ) {

                Image(
                    uiImage:
                        GameNodePlaceholderImage.image(
                            for:
                                .post
                        )
                )
                .resizable()
                .scaledToFill()
                .frame(
                    width:
                        96,
                    height:
                        96
                )
                .clipShape(
                    Circle()
                )


                Text(
                    content.title
                )
                .font(
                    .title3
                        .weight(
                            .semibold
                        )
                )
                .multilineTextAlignment(
                    .center
                )


                Text(
                    "This older Post stop does not yet contain a Post profile snapshot. Refresh the stop from the current Post model to show its full details."
                )
                .font(
                    .callout
                )
                .foregroundStyle(
                    .secondary
                )
                .multilineTextAlignment(
                    .center
                )
            }
            .frame(
                maxWidth:
                    .infinity
            )
            .padding(
                28
            )
        }
        .background(
            Color(
                uiColor:
                    .systemGroupedBackground
            )
        )
    }
}


// =====================================================
// MARK: - Poster / Header
// =====================================================

private extension GameNodePostView {

    func posterSection(
        _ post:
            PostNodeSnapshot
    ) -> some View {

        VStack(
            alignment:
                .leading,
            spacing:
                14
        ) {

            HStack(
                alignment:
                    .center,
                spacing:
                    12
            ) {

                Button {

                    onAction?(
                        .viewPoster,
                        node
                    )

                } label: {

                    posterAvatar(
                        post
                    )
                }
                .buttonStyle(
                    .plain
                )


                VStack(
                    alignment:
                        .leading,
                    spacing:
                        4
                ) {

                    Text(
                        displayPosterName(
                            post.posterName
                        )
                    )
                    .font(
                        .system(
                            size:
                                17,
                            weight:
                                .bold,
                            design:
                                .rounded
                        )
                    )


                    HStack(
                        spacing:
                            6
                    ) {

                        if isUsable(
                            post.posterLocation
                        ) {

                            Text(
                                post.posterLocation
                            )
                        }


                        if isUsable(
                            post.posterLocation
                        ) &&
                            isUsable(
                                post.posterRole
                            )
                        {

                            Text(
                                "•"
                            )
                        }


                        if isUsable(
                            post.posterRole
                        ) {

                            Text(
                                post.posterRole
                            )
                        }
                    }
                    .font(
                        .subheadline
                    )
                    .foregroundStyle(
                        .secondary
                    )
                    .lineLimit(
                        1
                    )


                    if isUsable(
                        post.createdAt
                    ) {

                        Text(
                            displayDate(
                                post.createdAt
                            )
                        )
                        .font(
                            .caption
                        )
                        .foregroundStyle(
                            .tertiary
                        )
                    }
                }


                Spacer(
                    minLength:
                        8
                )


                postTypeBadge(
                    post
                )
            }


            if isUsable(
                post.status
            ) {

                HStack(
                    spacing:
                        6
                ) {

                    Circle()
                        .fill(
                            postTypeColor(
                                post
                            )
                        )
                        .frame(
                            width:
                                7,
                            height:
                                7
                        )


                    Text(
                        "Status: \(post.status)"
                    )
                    .font(
                        .caption
                            .weight(
                                .medium
                            )
                    )
                    .foregroundStyle(
                        .secondary
                    )
                }
            }
        }
        .padding(
            16
        )
        .background(
            sectionBackground
        )
    }


    func posterAvatar(
        _ post:
            PostNodeSnapshot
    ) -> some View {

        ZStack {

            Circle()
                .stroke(
                    postTypeColor(
                        post
                    )
                    .opacity(
                        0.35
                    ),
                    lineWidth:
                        2
                )
                .frame(
                    width:
                        60,
                    height:
                        60
                )


            Group {

                if
                    isUsable(
                        post.posterImageURL
                    ),
                    let url =
                        URL(
                            string:
                                post.posterImageURL
                        )
                {

                    AsyncImage(
                        url:
                            url
                    ) { phase in

                        if case let .success(
                            image
                        ) = phase {

                            image
                                .resizable()
                                .scaledToFill()

                        } else {

                            userPlaceholder
                        }
                    }

                } else {

                    userPlaceholder
                }
            }
            .frame(
                width:
                    54,
                height:
                    54
            )
            .clipShape(
                Circle()
            )
        }
    }


    var userPlaceholder: some View {

        Image(
            uiImage:
                GameNodePlaceholderImage.image(
                    for:
                        .user
                )
        )
        .resizable()
        .scaledToFill()
    }


    func postTypeBadge(
        _ post:
            PostNodeSnapshot
    ) -> some View {

        HStack(
            spacing:
                5
        ) {

            Image(
                systemName:
                    post.postTypeDisplayName == "Request"
                    ? "questionmark.bubble.fill"
                    : "lightbulb.fill"
            )
            .font(
                .caption2
                    .weight(
                        .semibold
                    )
            )


            Text(
                post.postTypeDisplayName
            )
            .font(
                .caption
                    .weight(
                        .semibold
                    )
            )
        }
        .foregroundStyle(
            postTypeColor(
                post
            )
        )
        .padding(
            .horizontal,
            9
        )
        .padding(
            .vertical,
            5
        )
        .background(
            postTypeColor(
                post
            )
            .opacity(
                0.10
            )
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius:
                    9,
                style:
                    .continuous
            )
        )
    }
}


// =====================================================
// MARK: - Subject
// =====================================================

private extension GameNodePostView {

    func subjectSection(
        _ post:
            PostNodeSnapshot
    ) -> some View {

        VStack(
            alignment:
                .leading,
            spacing:
                8
        ) {

            Text(
                "Post"
            )
            .font(
                .caption
                    .weight(
                        .semibold
                    )
            )
            .foregroundStyle(
                .secondary
            )
            .textCase(
                .uppercase
            )


            Text(
                post.preferredTitle
            )
            .font(
                .system(
                    size:
                        17,
                    weight:
                        .medium,
                    design:
                        .rounded
                )
            )
            .frame(
                maxWidth:
                    .infinity,
                alignment:
                    .leading
            )
            .textSelection(
                .enabled
            )
        }
        .padding(
            16
        )
        .background(
            sectionBackground
        )
    }
}


// =====================================================
// MARK: - Main Media
// =====================================================

private extension GameNodePostView {

    func mediaSection(
        _ post:
            PostNodeSnapshot
    ) -> some View {

        VStack(
            alignment:
                .leading,
            spacing:
                10
        ) {

            HStack {

                Text(
                    "Media"
                )
                .font(
                    .headline
                )


                Spacer()


                if post.postMediaCount > 1 {

                    Label(
                        "\(post.postMediaCount)",
                        systemImage:
                            "photo.stack"
                    )
                    .font(
                        .caption
                            .weight(
                                .semibold
                            )
                    )
                    .padding(
                        .horizontal,
                        8
                    )
                    .padding(
                        .vertical,
                        5
                    )
                    .background(
                        Color.black
                            .opacity(
                                0.72
                            )
                    )
                    .foregroundStyle(
                        .white
                    )
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius:
                                8,
                            style:
                                .continuous
                        )
                    )
                }
            }


            postMainMedia(
                post
            )
            .frame(
                maxWidth:
                    .infinity
            )
            .aspectRatio(
                4 / 3,
                contentMode:
                    .fit
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius:
                        14,
                    style:
                        .continuous
                )
            )
            .background(
                Color.black
                    .opacity(
                        0.05
                    )
            )


            HStack(
                spacing:
                    12
            ) {

                if !post.postImageURLs.isEmpty {
                    mediaCountLabel(
                        count:
                            post.postImageURLs.count,
                        title:
                            "Images",
                        systemImage:
                            "photo"
                    )
                }


                if !post.postVideoURLs.isEmpty {
                    mediaCountLabel(
                        count:
                            post.postVideoURLs.count,
                        title:
                            "Videos",
                        systemImage:
                            "video"
                    )
                }


                if !post.postGIFMedia.isEmpty {
                    mediaCountLabel(
                        count:
                            1,
                        title:
                            "GIF",
                        systemImage:
                            "sparkles.rectangle.stack"
                    )
                }
            }
        }
        .padding(
            16
        )
        .background(
            sectionBackground
        )
    }


    @ViewBuilder
    func postMainMedia(
        _ post:
            PostNodeSnapshot
    ) -> some View {

        let type =
            post.postMainMediaType
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )
                .lowercased()

        let url =
            type == "gif"
            ? resolvedGIFURL(post)
            : usableURL(
                post.postMainMediaURL
            )


        switch type {

        case "video":

            if let url {

                PostNodeVideoView(
                    url:
                        url
                )

            } else {

                postMediaPlaceholder(
                    title:
                        "VIDEO"
                )
            }


        case "gif":

            if let url {

                PostNodeGIFView(
                    url:
                        url
                )

            } else {

                postMediaPlaceholder(
                    title:
                        "GIF"
                )
            }


        default:

            if let url {

                AsyncImage(
                    url:
                        url
                ) { phase in

                    switch phase {

                    case .empty:

                        ZStack {

                            postMediaPlaceholder(
                                title:
                                    "IMAGE"
                            )

                            ProgressView()
                        }


                    case let .success(
                        image
                    ):

                        image
                            .resizable()
                            .scaledToFit()


                    case .failure:

                        postMediaPlaceholder(
                            title:
                                "IMAGE"
                        )


                    @unknown default:

                        postMediaPlaceholder(
                            title:
                                "IMAGE"
                        )
                    }
                }

            } else {

                postMediaPlaceholder(
                    title:
                        "MEDIA"
                )
            }
        }
    }


    func postMediaPlaceholder(
        title: String
    ) -> some View {

        ZStack {

            Color(
                uiColor:
                    .secondarySystemGroupedBackground
            )


            VStack(
                spacing:
                    8
            ) {

                Image(
                    uiImage:
                        GameNodePlaceholderImage.image(
                            for:
                                .post
                        )
                )
                .resizable()
                .scaledToFit()
                .frame(
                    width:
                        58,
                    height:
                        58
                )
                .clipShape(
                    Circle()
                )


                Text(
                    title
                )
                .font(
                    .caption
                        .weight(
                            .bold
                        )
                )
                .foregroundStyle(
                    .secondary
                )
            }
        }
    }


    func mediaCountLabel(
        count: Int,
        title: String,
        systemImage: String
    ) -> some View {

        Label(
            "\(count) \(title)",
            systemImage:
                systemImage
        )
        .font(
            .caption
        )
        .foregroundStyle(
            .secondary
        )
    }
}


// =====================================================
// MARK: - Linked Content
// =====================================================

private extension GameNodePostView {

    func linkedContentSection(
        _ content:
            [PostNodeLinkedContent]
    ) -> some View {

        VStack(
            alignment:
                .leading,
            spacing:
                0
        ) {

            Text(
                "Linked Content"
            )
            .font(
                .headline
            )
            .padding(
                .bottom,
                8
            )


            ForEach(
                Array(
                    content.enumerated()
                ),
                id:
                    \.offset
            ) { index, item in

                if index > 0 {
                    Divider()
                }


                Button {

                    onAction?(
                        .viewLinkedContent(
                            item
                        ),
                        node
                    )

                } label: {

                    HStack(
                        spacing:
                            12
                    ) {

                        Image(
                            systemName:
                                item.systemImageName
                        )
                        .frame(
                            width:
                                24
                        )


                        Text(
                            item.title
                        )
                        .fontWeight(
                            .semibold
                        )


                        Spacer()


                        Image(
                            systemName:
                                "chevron.right"
                        )
                        .font(
                            .caption
                                .weight(
                                    .bold
                                )
                        )
                        .foregroundStyle(
                            .tertiary
                        )
                    }
                    .padding(
                        .vertical,
                        12
                    )
                }
                .buttonStyle(
                    .plain
                )
                .foregroundStyle(
                    .primary
                )
            }
        }
        .padding(
            16
        )
        .background(
            sectionBackground
        )
    }


    func linkedContent(
        _ post:
            PostNodeSnapshot
    ) -> [PostNodeLinkedContent] {

        var result:
            [PostNodeLinkedContent] = []


        if isUsable(
            post.postWorkoutID
        ) {

            result.append(
                .workout(
                    post.postWorkoutID
                )
            )
        }


        if isUsable(
            post.postMealID
        ) {

            result.append(
                .meal(
                    post.postMealID
                )
            )
        }


        if isUsable(
            post.postActivityID
        ) {

            result.append(
                .activity(
                    post.postActivityID
                )
            )
        }


        if isUsable(
            post.postTaskID
        ) {

            result.append(
                .task(
                    post.postTaskID
                )
            )
        }


        return result
    }
}


// =====================================================
// MARK: - Engagement
// =====================================================

private extension GameNodePostView {

    func engagementSection(
        _ post:
            PostNodeSnapshot
    ) -> some View {

        VStack(
            alignment:
                .leading,
            spacing:
                14
        ) {

            Text(
                "Engagement"
            )
            .font(
                .headline
            )


            HStack(
                spacing:
                    20
            ) {

                Label(
                    responseCountText(
                        post.postResponseCount
                    ),
                    systemImage:
                        "bubble.left"
                )


                Spacer()


                Label(
                    "\(post.postSavedCount) Saved",
                    systemImage:
                        post.isSaved
                        ? "bookmark.fill"
                        : "bookmark"
                )
                .foregroundStyle(
                    post.isSaved
                    ? Color.blue
                    : Color.secondary
                )
            }
            .font(
                .subheadline
                    .weight(
                        .semibold
                    )
            )


            if !post.responderImageURLs.isEmpty {

                VStack(
                    alignment:
                        .leading,
                    spacing:
                        8
                ) {

                    Text(
                        "Recent Responders"
                    )
                    .font(
                        .caption
                            .weight(
                                .semibold
                            )
                    )
                    .foregroundStyle(
                        .secondary
                    )


                    HStack(
                        spacing:
                            -8
                    ) {

                        ForEach(
                            Array(
                                post.responderImageURLs
                                    .prefix(
                                        8
                                    )
                                    .enumerated()
                            ),
                            id:
                                \.offset
                        ) { _, urlString in

                            responderAvatar(
                                urlString
                            )
                        }
                    }
                }
            }


            if isUsable(
                post.savedPostStatus
            ) {

                LabeledContent(
                    "Your Save Status",
                    value:
                        post.savedPostStatus
                )
                .font(
                    .subheadline
                )
            }
        }
        .padding(
            16
        )
        .background(
            sectionBackground
        )
    }


    func responderAvatar(
        _ urlString:
            String
    ) -> some View {

        Group {

            if let url =
                usableURL(
                    urlString
                )
            {

                AsyncImage(
                    url:
                        url
                ) { phase in

                    if case let .success(
                        image
                    ) = phase {

                        image
                            .resizable()
                            .scaledToFill()

                    } else {

                        userPlaceholder
                    }
                }

            } else {

                userPlaceholder
            }
        }
        .frame(
            width:
                34,
            height:
                34
        )
        .clipShape(
            Circle()
        )
        .overlay {

            Circle()
                .stroke(
                    Color(
                        uiColor:
                            .systemBackground
                    ),
                    lineWidth:
                        2
                )
        }
    }
}


// =====================================================
// MARK: - Tags / Info
// =====================================================

private extension GameNodePostView {

    func tagsSection(
        _ tags:
            [String]
    ) -> some View {

        VStack(
            alignment:
                .leading,
            spacing:
                10
        ) {

            Text(
                "Tags"
            )
            .font(
                .headline
            )


            LazyVGrid(
                columns: [
                    GridItem(
                        .adaptive(
                            minimum:
                                90
                        ),
                        spacing:
                            8
                    )
                ],
                alignment:
                    .leading,
                spacing:
                    8
            ) {

                ForEach(
                    tags,
                    id:
                        \.self
                ) { tag in

                    Text(
                        tag.hasPrefix("#")
                        ? tag
                        : "#\(tag)"
                    )
                    .font(
                        .caption
                            .weight(
                                .semibold
                            )
                    )
                    .foregroundStyle(
                        .secondary
                    )
                    .padding(
                        .horizontal,
                        9
                    )
                    .padding(
                        .vertical,
                        6
                    )
                    .background(
                        Color.secondary
                            .opacity(
                                0.10
                            )
                    )
                    .clipShape(
                        Capsule()
                    )
                }
            }
        }
        .padding(
            16
        )
        .background(
            sectionBackground
        )
    }


    func postInfoSection(
        _ post:
            PostNodeSnapshot
    ) -> some View {

        VStack(
            alignment:
                .leading,
            spacing:
                10
        ) {

            Text(
                "Post Info"
            )
            .font(
                .headline
            )


            LabeledContent(
                "Type",
                value:
                    post.postTypeDisplayName
            )


            if isUsable(
                post.status
            ) {

                LabeledContent(
                    "Status",
                    value:
                        post.status
                )
            }


            if isUsable(
                post.createdAt
            ) {

                LabeledContent(
                    "Created",
                    value:
                        displayDate(
                            post.createdAt
                        )
                )
            }


            LabeledContent(
                "Media",
                value:
                    "\(max(0, post.postMediaCount))"
            )
        }
        .font(
            .subheadline
        )
        .padding(
            16
        )
        .background(
            sectionBackground
        )
    }
}


// =====================================================
// MARK: - Bottom Actions
// =====================================================

private extension GameNodePostView {

    func postActionBar(
        _ post:
            PostNodeSnapshot
    ) -> some View {

        HStack(
            spacing:
                12
        ) {

            Button {

                onAction?(
                    .respond,
                    node
                )

            } label: {

                Label(
                    "Respond",
                    systemImage:
                        "arrowshape.turn.up.left"
                )
                .fontWeight(
                    .semibold
                )
                .frame(
                    maxWidth:
                        .infinity
                )
                .padding(
                    .vertical,
                    12
                )
            }
            .buttonStyle(
                .borderedProminent
            )
            .tint(
                postTypeColor(
                    post
                )
            )


            Button {

                onAction?(
                    .save,
                    node
                )

            } label: {

                Label(
                    post.isSaved
                    ? "Saved"
                    : "Save",
                    systemImage:
                        post.isSaved
                        ? "bookmark.fill"
                        : "bookmark"
                )
                .fontWeight(
                    .semibold
                )
                .frame(
                    maxWidth:
                        .infinity
                )
                .padding(
                    .vertical,
                    12
                )
            }
            .buttonStyle(
                .bordered
            )
        }
        .padding(
            .horizontal,
            16
        )
        .padding(
            .vertical,
            10
        )
        .background(
            .bar
        )
    }
}


// =====================================================
// MARK: - Helpers
// =====================================================

private extension GameNodePostView {

    var navigationTitle: String {

        guard
            case let .post(
                content
            ) = node.content,
            let snapshot =
                content.snapshot
        else {

            return "Post Details"
        }

        return "\(snapshot.postTypeDisplayName) Details"
    }


    var sectionBackground: some ShapeStyle {

        Color(
            uiColor:
                .secondarySystemGroupedBackground
        )
    }


    func postTypeColor(
        _ post:
            PostNodeSnapshot
    ) -> Color {

        post.postTypeDisplayName == "Request"
        ? Color.green
        : Color.purple
    }


    func displayPosterName(
        _ value:
            String
    ) -> String {

        isUsable(
            value
        )
        ? value
        : "Member Acct. Deleted"
    }


    func responseCountText(
        _ count:
            Int
    ) -> String {

        switch count {

        case 1:
            return "1 Response"

        default:
            return "\(max(0, count)) Responses"
        }
    }


    func hasMainMedia(
        _ post:
            PostNodeSnapshot
    ) -> Bool {

        guard post.postMediaCount > 0 else {
            return false
        }

        let type =
            post.postMainMediaType
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
                .lowercased()

        if type == "gif" {
            return resolvedGIFURL(post) != nil
        }

        return usableURL(
            post.postMainMediaURL
        ) != nil
    }


    func resolvedGIFURL(
        _ post:
            PostNodeSnapshot
    ) -> URL? {

        if let main =
            usableURL(
                post.postMainMediaURL
            )
        {
            return main
        }


        for key in [
            "url",
            "gifURL",
            "gif_url",
            "originalURL",
            "original_url"
        ] {

            if
                let value = post.postGIFMedia[key],
                let url = usableURL(value)
            {
                return url
            }
        }


        if
            let id = post.postGIFMedia["id"]?
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                ),
            !id.isEmpty,
            id.lowercased() != "none"
        {

            return URL(
                string:
                    "https://media.giphy.com/media/\(id)/giphy.gif"
            )
        }


        return nil
    }


    func isUsable(
        _ value:
            String
    ) -> Bool {

        let cleaned =
            value
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )

        return !cleaned.isEmpty &&
            cleaned.lowercased() != "none"
    }


    func usableURL(
        _ value:
            String
    ) -> URL? {

        guard isUsable(
            value
        ) else {

            return nil
        }

        if value.hasPrefix(
            "/"
        ) {

            return URL(
                fileURLWithPath:
                    value
            )
        }

        return URL(
            string:
                value
        )
    }


    func displayDate(
        _ value:
            String
    ) -> String {

        let iso =
            ISO8601DateFormatter()

        if let date =
            iso.date(
                from:
                    value
            )
        {

            let formatter =
                DateFormatter()

            formatter.dateStyle =
                .medium

            formatter.timeStyle =
                .short

            return formatter.string(
                from:
                    date
            )
        }

        return value
    }
}


// =====================================================
// MARK: - Video
// =====================================================

private struct PostNodeVideoView: View {

    let url:
        URL


    @State
    private var player:
        AVPlayer


    init(
        url: URL
    ) {

        self.url =
            url

        _player =
            State(
                initialValue:
                    AVPlayer(
                        url:
                            url
                    )
            )
    }


    var body: some View {

        VideoPlayer(
            player:
                player
        )
        .onDisappear {

            player.pause()
        }
    }
}


// =====================================================
// MARK: - GIF
// =====================================================

private struct PostNodeGIFView:
    UIViewRepresentable {

    let url:
        URL


    func makeUIView(
        context: Context
    ) -> WKWebView {

        let configuration =
            WKWebViewConfiguration()

        configuration.defaultWebpagePreferences.allowsContentJavaScript =
            false


        let webView =
            WKWebView(
                frame:
                    .zero,
                configuration:
                    configuration
            )

        webView.isOpaque =
            false

        webView.backgroundColor =
            .clear

        webView.scrollView.isScrollEnabled =
            false

        webView.scrollView.bounces =
            false

        webView.isUserInteractionEnabled =
            false

        return webView
    }


    func updateUIView(
        _ webView: WKWebView,
        context: Context
    ) {

        let escaped =
            url.absoluteString
                .replacingOccurrences(
                    of:
                        "&",
                    with:
                        "&amp;"
                )
                .replacingOccurrences(
                    of:
                        "\"",
                    with:
                        "&quot;"
                )


        let html =
            """
            <html>
            <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
            <style>
            html, body {
                margin: 0;
                padding: 0;
                width: 100%;
                height: 100%;
                overflow: hidden;
                background: transparent;
            }
            img {
                width: 100%;
                height: 100%;
                object-fit: contain;
                display: block;
            }
            </style>
            </head>
            <body>
            <img src="\(escaped)" />
            </body>
            </html>
            """

        webView.loadHTMLString(
            html,
            baseURL:
                nil
        )
    }
}
