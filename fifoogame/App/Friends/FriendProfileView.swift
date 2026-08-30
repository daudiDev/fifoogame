import SwiftUI

struct FriendProfileView: View {
    let friend: SocialFriend

    @State private var isShowingMessages = false
    @State private var isShowingProgress = false

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                VStack(spacing: 10) {
                    SocialAvatarView(
                        imageURL: friend.imageURL,
                        name: friend.displayName,
                        size: 104
                    )

                    Text(friend.displayName)
                        .font(.title2.bold())

                    Text("@\(friend.username)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    SocialRelativeTimeText(
                        date: friend.lastActive,
                        prefix: "Last active "
                    )
                }

                HStack(spacing: 12) {
                    profileMetric(
                        value:
                            "\(Int(friend.progressPercent.rounded()))%",
                        title:
                            "Today"
                    )

                    profileMetric(
                        value:
                            "\(Int(friend.goalTargetPercent.rounded()))%",
                        title:
                            "Goal"
                    )
                }

                ProgressView(
                    value:
                        min(
                            max(friend.progressPercent, 0),
                            max(friend.goalTargetPercent, 1)
                        ),
                    total:
                        max(
                            friend.goalTargetPercent,
                            1
                        )
                )
                .tint(.green)

                HStack(spacing: 12) {
                    Button {
                        isShowingMessages = true
                    } label: {
                        Label(
                            "Message",
                            systemImage: "bubble.left.fill"
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.purple)

                    Button {
                        isShowingProgress = true
                    } label: {
                        Label(
                            "Progress",
                            systemImage: "chart.line.uptrend.xyaxis"
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(24)
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(
            isPresented: $isShowingMessages
        ) {
            NavigationStack {
                ConversationMessagesView(
                    friend: friend
                )
                .toolbar {
                    ToolbarItem(
                        placement: .topBarLeading
                    ) {
                        Button("Close") {
                            isShowingMessages = false
                        }
                    }
                }
            }
        }
        .sheet(
            isPresented: $isShowingProgress
        ) {
            NavigationStack {
                FriendProgressView(
                    friend: friend
                )
                .toolbar {
                    ToolbarItem(
                        placement: .topBarLeading
                    ) {
                        Button("Close") {
                            isShowingProgress = false
                        }
                    }
                }
            }
            .presentationDetents([
                .medium,
                .large
            ])
        }
    }

    private func profileMetric(
        value: String,
        title: String
    ) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(
                    .system(
                        size: 25,
                        weight: .black,
                        design: .rounded
                    )
                )
                .foregroundStyle(.green)
                .monospacedDigit()

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            .thinMaterial,
            in:
                RoundedRectangle(
                    cornerRadius: 18,
                    style: .continuous
                )
        )
    }
}
