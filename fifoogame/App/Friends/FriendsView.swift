import SwiftUI

struct FriendsView: View {
    @State private var socketManager = SocketManager.shared
    @State private var messageFriend: SocialFriend?
    @State private var progressFriend: SocialFriend?

    var body: some View {
        Group {
            if socketManager.isFriendsLoading && socketManager.friends.isEmpty {
                ProgressView("Loading friends…")
            } else if socketManager.friends.isEmpty {
                ContentUnavailableView(
                    "No friends yet",
                    systemImage: "person.2",
                    description: Text("Friends you connect with in Fifoo will appear here.")
                )
            } else {
                List(socketManager.friends) { friend in
                    friendRow(friend)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 7, leading: 14, bottom: 7, trailing: 14))
                }
                .listStyle(.plain)
                .refreshable {
                    socketManager.requestFriends()
                }
            }
        }
        .navigationTitle("Friends")
        .task {
            socketManager.requestFriends()
        }
        .sheet(item: $messageFriend) { friend in
            NavigationStack {
                ConversationMessagesView(friend: friend)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Close") { messageFriend = nil }
                        }
                    }
            }
        }
        .sheet(item: $progressFriend) { friend in
            NavigationStack {
                FriendProgressView(friend: friend)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Close") { progressFriend = nil }
                        }
                    }
            }
            .presentationDetents([.medium, .large])
        }
    }

    private func friendRow(_ friend: SocialFriend) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                SocialAvatarView(
                    imageURL: friend.imageURL,
                    name: friend.displayName,
                    size: 56
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text(friend.displayName)
                        .font(.headline)
                    Text("@\(friend.username)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    SocialRelativeTimeText(date: friend.lastActive, prefix: "Active ")
                }

                Spacer()

                VStack(spacing: 2) {
                    Text("\(Int(friend.progressPercent.rounded()))%")
                        .font(.title3.bold())
                        .foregroundStyle(.green)
                    Text("progress")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            ProgressView(
                value: min(max(friend.progressPercent, 0), friend.goalTargetPercent),
                total: max(friend.goalTargetPercent, 1)
            )
            .tint(.green)

            HStack(spacing: 10) {
                Button {
                    messageFriend = friend
                } label: {
                    Label("Message", systemImage: "bubble.left.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.purple)

                Button {
                    progressFriend = friend
                } label: {
                    Label("Progress", systemImage: "chart.line.uptrend.xyaxis")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20))
    }
}
