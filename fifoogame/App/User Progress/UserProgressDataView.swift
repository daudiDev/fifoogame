import SwiftUI

struct UserProgressDataView: View {
    @Binding var isShowingProgressDataView: Bool
    @State private var socketManager = SocketManager.shared

    private let targetPercent = 100.0

    private var currentPercent: Double {
        socketManager.userDailyProgress * 100
    }

    private var startingPercent: Double {
        socketManager.gameStore.progressState.startingProgress.percent
    }

    private var changePercent: Double {
        currentPercent - startingPercent
    }

    private var remainingPercent: Double {
        max(0, targetPercent - currentPercent)
    }

    private var targetFraction: Double {
        guard targetPercent > 0 else { return 0 }
        return min(max(currentPercent / targetPercent, 0), 1)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Today's Progress")
                            .font(.system(size: 30, weight: .heavy, design: .rounded))
                        Text(socketManager.selectedDayMapDate.formatted(date: .complete, time: .omitted))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button {
                        withAnimation(.spring()) {
                            isShowingProgressDataView = false
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.headline)
                            .frame(width: 38, height: 38)
                            .background(.thinMaterial, in: Circle())
                    }
                    .buttonStyle(.plain)
                }

                ZStack {
                    Circle()
                        .stroke(.secondary.opacity(0.15), lineWidth: 18)
                    Circle()
                        .trim(from: 0, to: targetFraction)
                        .stroke(
                            .green,
                            style: StrokeStyle(lineWidth: 18, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                    VStack(spacing: 4) {
                        Text("\(Int(currentPercent.rounded()))%")
                            .font(.system(size: 48, weight: .black, design: .rounded))
                            .monospacedDigit()
                        Text("of \(Int(targetPercent))% goal")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 220, height: 220)

                VStack(spacing: 0) {
                    progressRow("Current", value: "\(Int(currentPercent.rounded()))%", systemImage: "location.fill")
                    Divider().padding(.leading, 52)
                    progressRow("Starting progress", value: "\(Int(startingPercent.rounded()))%", systemImage: "play.circle")
                    Divider().padding(.leading, 52)
                    progressRow("Daily goal", value: "\(Int(targetPercent))%", systemImage: "target")
                    Divider().padding(.leading, 52)
                    progressRow("Remaining", value: "\(Int(remainingPercent.rounded()))%", systemImage: "flag.checkered")
                    Divider().padding(.leading, 52)
                    progressRow(
                        "Change today",
                        value: String(format: "%@%.0f%%", changePercent >= 0 ? "+" : "", changePercent),
                        systemImage: changePercent >= 0 ? "arrow.up.right" : "arrow.down.right"
                    )
                }
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 22))

                HStack(spacing: 12) {
                    Image(systemName: currentPercent >= targetPercent ? "checkmark.seal.fill" : "figure.walk.motion")
                        .font(.title2)
                        .foregroundStyle(currentPercent >= targetPercent ? .green : .purple)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(currentPercent >= targetPercent ? "Daily target reached" : "Keep moving forward")
                            .font(.headline)
                        Text(currentPercent >= targetPercent
                             ? "You have reached today's 100% progress target."
                             : "You are \(Int(remainingPercent.rounded())) percentage points from today's target.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
            }
            .padding(.horizontal, 22)
            .padding(.top, 60)
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThickMaterial)
        .ignoresSafeArea()
    }

    private func progressRow(_ title: String, value: String, systemImage: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: systemImage)
                .frame(width: 28)
                .foregroundStyle(.purple)
            Text(title)
            Spacer()
            Text(value)
                .fontWeight(.bold)
                .monospacedDigit()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
    }
}
