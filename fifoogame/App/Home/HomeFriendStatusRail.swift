import SwiftUI
import Combine

struct HomeFriendStatusRail: View {
    @State private var socketManager = SocketManager.shared
    @State private var rotationOffset = 0

    let onPathTapped: () -> Void

    private let maximumVisibleFriends = 3
    private let rotationTimer = Timer
        .publish(
            every: 8,
            on: .main,
            in: .common
        )
        .autoconnect()

    private var visibleFriends: [SocialFriend] {
        let friends = socketManager.friends

        guard friends.count > maximumVisibleFriends else {
            return Array(friends.prefix(maximumVisibleFriends))
        }

        let count = friends.count
        let start = rotationOffset % count

        return (0..<maximumVisibleFriends).map { position in
            friends[(start + position) % count]
        }
    }

    var body: some View {
        VStack(spacing: 10) {
            ForEach(visibleFriends) { friend in
                NavigationLink {
                    FriendProfileView(friend: friend)
                } label: {
                    HomeFriendStatusTile(friend: friend)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(
                    "Open \(friend.displayName)'s profile, \(Int(friend.progressPercent.rounded())) percent progress"
                )
            }

            Button(action: onPathTapped) {
                Image(
                    systemName:
                        "point.topleft.down.to.point.bottomright.curvepath"
                )
                .font(
                    .system(
                        size: 19,
                        weight: .bold
                    )
                )
                .foregroundStyle(.primary)
                .frame(
                    width: 44,
                    height: 44
                )
                .background(
                    Circle()
                        .fill(.ultraThinMaterial)
                )
                .overlay {
                    Circle()
                        .stroke(
                            .white.opacity(0.45),
                            lineWidth: 0.6
                        )
                }
                .shadow(
                    color: .black.opacity(0.14),
                    radius: 6,
                    y: 3
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("View today's path")
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 6)
        .task {
            if socketManager.friends.isEmpty {
                socketManager.requestFriends()
            }
        }
        .onReceive(rotationTimer) { _ in
            guard socketManager.friends.count > maximumVisibleFriends else {
                rotationOffset = 0
                return
            }

            withAnimation(
                .easeInOut(duration: 0.35)
            ) {
                rotationOffset =
                    (rotationOffset + 1)
                    % socketManager.friends.count
            }
        }
        .onChange(
            of: socketManager.friends.count
        ) { _, newCount in
            if newCount == 0 {
                rotationOffset = 0
            } else {
                rotationOffset %= newCount
            }
        }
    }
}

private struct HomeFriendStatusTile: View {
    let friend: SocialFriend

    private var shortName: String {
        friend.displayName
            .split(separator: " ")
            .first
            .map(String.init)
            ?? friend.displayName
    }

    private var activityTimeText: String {
        guard let lastActive = friend.lastActive else {
            return "offline"
        }

        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated

        return formatter.localizedString(
            for: lastActive,
            relativeTo: Date()
        )
    }

    var body: some View {
        VStack(spacing: 4) {
            ZStack(
                alignment: .topTrailing
            ) {
                SocialAvatarView(
                    imageURL: friend.imageURL,
                    name: friend.displayName,
                    size: 40
                )

                Text(
                    "\(Int(friend.progressPercent.rounded()))%"
                )
                .font(
                    .system(
                        size: 8,
                        weight: .black,
                        design: .rounded
                    )
                )
                .monospacedDigit()
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(.green)
                )
                .overlay {
                    Capsule()
                        .stroke(
                            .white.opacity(0.9),
                            lineWidth: 1
                        )
                }
                .offset(
                    x: 5,
                    y: -4
                )
            }
            .frame(
                width: 46,
                height: 42
            )

            HStack(spacing: 3) {
                Text(shortName)
                    .font(
                        .system(
                            size: 9,
                            weight: .semibold,
                            design: .rounded
                        )
                    )
                    .foregroundStyle(.white)
                    .shadow(
                        color: .black.opacity(0.85),
                        radius: 2,
                        x: 0,
                        y: 1
                    )

                Text(activityTimeText)
                    .font(
                        .system(
                            size: 8,
                            weight: .medium,
                            design: .rounded
                        )
                    )
                    .foregroundStyle(.white.opacity(0.92))
                    .shadow(
                        color: .black.opacity(0.85),
                        radius: 2,
                        x: 0,
                        y: 1
                    )
            }
            .lineLimit(1)
            .minimumScaleFactor(0.62)
            .frame(
                maxWidth: 72,
                alignment: .center
            )
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 5)
        .contentShape(Rectangle())
    }
}
