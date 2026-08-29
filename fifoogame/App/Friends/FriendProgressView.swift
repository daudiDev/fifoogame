import SwiftUI

struct FriendProgressView: View {
    let friend: SocialFriend

    private var fraction: Double {
        guard friend.goalTargetPercent > 0 else { return 0 }
        return min(max(friend.progressPercent / friend.goalTargetPercent, 0), 1)
    }

    private var remaining: Double {
        max(0, friend.goalTargetPercent - friend.progressPercent)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                SocialAvatarView(
                    imageURL: friend.imageURL,
                    name: friend.displayName,
                    size: 92
                )

                VStack(spacing: 4) {
                    Text(friend.displayName)
                        .font(.title2.bold())
                    Text("@\(friend.username)")
                        .foregroundStyle(.secondary)
                }

                ZStack {
                    Circle()
                        .stroke(.secondary.opacity(0.16), lineWidth: 16)
                    Circle()
                        .trim(from: 0, to: fraction)
                        .stroke(.green, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    VStack(spacing: 2) {
                        Text("\(Int(friend.progressPercent.rounded()))%")
                            .font(.system(size: 42, weight: .black, design: .rounded))
                        Text("of \(Int(friend.goalTargetPercent.rounded()))% goal")
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 200, height: 200)

                VStack(spacing: 0) {
                    detailRow("Current progress", "\(Int(friend.progressPercent.rounded()))%")
                    Divider()
                    detailRow("Goal target", "\(Int(friend.goalTargetPercent.rounded()))%")
                    Divider()
                    detailRow("Remaining", "\(Int(remaining.rounded()))%")
                    Divider()
                    detailRow("Day", friend.mapDate)
                }
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))

                SocialRelativeTimeText(date: friend.lastActive, prefix: "Last active ")
            }
            .padding(24)
        }
        .navigationTitle("Friend Progress")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func detailRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .monospacedDigit()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}
