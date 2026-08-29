import SwiftUI

struct PostsView: View {
    @State private var socketManager = SocketManager.shared
    @State private var selectedPost: SocialPost?

    var body: some View {
        Group {
            if socketManager.isPostsLoading && socketManager.postsFeed.isEmpty {
                ProgressView("Loading posts…")
            } else if socketManager.postsFeed.isEmpty {
                ContentUnavailableView(
                    "No posts yet",
                    systemImage: "rectangle.stack",
                    description: Text("Tips, requests and community posts will appear here.")
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(socketManager.postsFeed) { post in
                            postCard(post)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 16)
                }
                .refreshable {
                    socketManager.requestPostsFeed()
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Posts")
        .task {
            socketManager.requestPostsFeed()
        }
        .sheet(item: $selectedPost) { post in
            NavigationStack {
                PostRepliesView(post: post)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Close") { selectedPost = nil }
                        }
                    }
            }
            .presentationDetents([.medium, .large])
        }
    }

    private func postCard(_ post: SocialPost) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                SocialAvatarView(
                    imageURL: post.posterImageURL,
                    name: post.posterName,
                    size: 44
                )
                VStack(alignment: .leading, spacing: 2) {
                    Text(post.posterName)
                        .font(.headline)
                    HStack(spacing: 5) {
                        Text(post.postType)
                        if let date = post.createdAt {
                            Text("•")
                            SocialRelativeTimeText(date: date)
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                Spacer()
            }

            Text(post.subject)
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let imageURL = post.preferredImageURL,
               let url = URL(string: imageURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        mediaPlaceholder
                    default:
                        ZStack {
                            mediaPlaceholder
                            ProgressView()
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 250)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 16))
            } else if !post.videoURLs.isEmpty || (post.mainMediaType ?? "").lowercased() == "video" {
                mediaPlaceholder
                    .overlay {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.white)
                    }
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }

            if !post.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 7) {
                        ForEach(post.tags, id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.caption)
                                .foregroundStyle(.purple)
                                .padding(.horizontal, 9)
                                .padding(.vertical, 5)
                                .background(.purple.opacity(0.08), in: Capsule())
                        }
                    }
                }
            }

            Divider()

            HStack {
                Button {
                    selectedPost = post
                } label: {
                    Label("\(post.replyCount)", systemImage: "bubble.left")
                }
                .buttonStyle(.plain)

                Spacer()

                Button {
                    socketManager.setPostFeedSaved(
                        postID: post.postID,
                        isSaved: !post.isSaved
                    )
                } label: {
                    Label(
                        "\(post.saveCount)",
                        systemImage: post.isSaved ? "bookmark.fill" : "bookmark"
                    )
                }
                .buttonStyle(.plain)
                .foregroundStyle(post.isSaved ? .purple : .primary)
            }
            .font(.subheadline.weight(.semibold))
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 22))
    }

    private var mediaPlaceholder: some View {
        Rectangle()
            .fill(.black.opacity(0.82))
            .overlay {
                Image(systemName: "photo")
                    .font(.largeTitle)
                    .foregroundStyle(.white.opacity(0.8))
            }
    }
}

private struct PostRepliesView: View {
    let post: SocialPost

    @State private var socketManager = SocketManager.shared
    @State private var draft = ""

    var body: some View {
        VStack(spacing: 0) {
            if socketManager.isPostRepliesLoading && socketManager.activePostReplies.isEmpty {
                Spacer()
                ProgressView("Loading replies…")
                Spacer()
            } else if socketManager.activePostReplies.isEmpty {
                Spacer()
                ContentUnavailableView(
                    "No replies yet",
                    systemImage: "bubble.left",
                    description: Text("Be the first to reply.")
                )
                Spacer()
            } else {
                List(socketManager.activePostReplies) { reply in
                    HStack(alignment: .top, spacing: 10) {
                        SocialAvatarView(
                            imageURL: reply.posterImageURL,
                            name: reply.posterName,
                            size: 36
                        )
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(reply.posterName)
                                    .font(.subheadline.bold())
                                Spacer()
                                if let date = reply.createdAt {
                                    SocialRelativeTimeText(date: date)
                                }
                            }
                            Text(reply.body)
                                .font(.body)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(.plain)
            }

            HStack(alignment: .bottom, spacing: 10) {
                TextField("Reply…", text: $draft, axis: .vertical)
                    .lineLimit(1...4)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
                Button {
                    let text = draft
                    draft = ""
                    socketManager.sendPostFeedReply(text)
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.purple)
                }
                .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(12)
            .background(.ultraThinMaterial)
        }
        .navigationTitle("Replies")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            socketManager.openPostReplies(post)
        }
    }
}
