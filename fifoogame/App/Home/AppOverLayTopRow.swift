import SwiftUI

struct AppOverLayTopRow: View {

    private let socketManager =
        SocketManager.shared

    @Binding
    var isShowingUserActionsProgressView: Bool

    @Binding
    var isShowingProgressDataView: Bool

    let onCalendarTapped: () -> Void


    var body: some View {
        HStack(
            alignment: .center,
            spacing: 5
        ) {
            // The calendar title is an actual control so the user can browse
            // another Day Map without hunting for a separate date action.
            Button(
                action:
                    onCalendarTapped
            ) {
                HStack(
                    alignment: .center,
                    spacing: 3
                ) {
                    Image(
                        "calendar_color"
                    )
                    .resizable()
                    .frame(
                        width: 25,
                        height: 25
                    )
                    Spacer()
                    Text(
                        weekdayString(
                            from:
                                socketManager.selectedDayMapDate
                        )
                    )
                    .font(
                        .system(
                            size: 18,
                            weight: .heavy,
                            design: .rounded
                        )
                    )
                    .foregroundStyle(.black)
                    .textCase(.uppercase)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    Text(
                        monthString(
                            from:
                                socketManager.selectedDayMapDate
                        )
                    )
                    .font(
                        .system(
                            size: 18,
                            weight: .heavy,
                            design: .rounded
                        )
                    )
                    .textCase(.uppercase)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                    Text(
                        dayNumber(
                            from:
                                socketManager.selectedDayMapDate
                        )
                    )
                    .font(
                        .system(
                            size: 18,
                            weight: .heavy,
                            design: .rounded
                        )
                    )
                    .foregroundStyle(.black)
                    .textCase(.uppercase)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                    Text(
                        yearString(
                            from:
                                socketManager.selectedDayMapDate
                        )
                    )
                    .font(
                        .system(
                            size: 18,
                            weight: .heavy,
                            design: .rounded
                        )
                    )
                    .foregroundStyle(
                        .black.opacity(0.9)
                    )
                    .textCase(.uppercase)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                "Choose Day Map date"
            )
            Spacer()
            Button {
                withAnimation(
                    .spring()
                ) {
                    isShowingProgressDataView.toggle()
                }
            } label: {
                UserCircularProgressBar(
                    progress:
                        socketManager.userDailyProgress
                )
            }
        }
        .frame(
            maxWidth: .infinity
        )
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(
                cornerRadius: 25
            )
            .fill(.ultraThinMaterial)
        )
    }


    // MARK: - Helpers

    private func monthString(
        from date: Date
    ) -> String {
        let formatter =
            DateFormatter()
        formatter.dateFormat =
            "MMMM"
        return formatter.string(
            from: date
        )
    }


    private func yearString(
        from date: Date
    ) -> String {
        let formatter =
            DateFormatter()
        // Calendar year, not week-based year.
        formatter.dateFormat =
            "yyyy"
        return formatter.string(
            from: date
        )
    }


    private func weekdayString(
        from date: Date
    ) -> String {
        let formatter =
            DateFormatter()
        formatter.dateFormat =
            "EEEE"
        return formatter.string(
            from: date
        )
    }


    private func dayNumber(
        from date: Date
    ) -> String {
        let formatter =
            DateFormatter()
        formatter.dateFormat =
            "d"
        return formatter.string(
            from: date
        ) + ", "
    }
}
