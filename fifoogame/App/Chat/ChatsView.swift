import SwiftUI

//MARK: Important for user chat

struct ChatsView: View {
    @State private var socketManager = SocketManager.shared
    @State private var auth = AuthManager.shared

    var body: some View {
        Group {
            if socketManager.isConversationsLoading && socketManager.conversations.isEmpty {
                ProgressView("Loading chats…")
            } else if socketManager.conversations.isEmpty {
                ContentUnavailableView(
                    "No conversations",
                    systemImage: "bubble.left.and.bubble.right",
                    description: Text("Messages you exchange with friends will appear here.")
                )
            } else {
                List(socketManager.conversations) { conversation in
                    NavigationLink {
                        ConversationMessagesView(conversation: conversation)
                    } label: {
                        conversationRow(conversation)
                    }
                }
                .listStyle(.plain)
                .refreshable {
                    socketManager.requestConversations()
                }
            }
        }
        .navigationTitle("Chats")
        .task {
            socketManager.requestConversations()
        }
    }

    private func conversationRow(_ conversation: SocialConversationSummary) -> some View {
        let currentID = auth.currentUser.flatMap { UUID(uuidString: $0.userID) }
        let partner = conversation.participants.first(where: { $0.userID != currentID })

        return HStack(spacing: 12) {
            SocialAvatarView(
                imageURL: partner?.imageURL,
                name: conversation.title,
                size: 52
            )

            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(conversation.title)
                        .font(.headline)
                        .lineLimit(1)
                    if conversation.isSupport {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(.purple)
                            .font(.caption)
                    }
                    Spacer()
                    if let date = conversation.updatedAt {
                        SocialRelativeTimeText(date: date)
                    }
                }

                Text(conversation.lastMessage?.body ?? "Start a conversation")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 6)
    }
}
