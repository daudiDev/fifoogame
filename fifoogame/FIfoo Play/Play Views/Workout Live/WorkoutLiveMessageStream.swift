//
//  WorkoutLiveMessageStream.swift
//  Fifoo Play
//
//  Created by Daudi Sagala on 8/16/26.
//
 import SwiftUI


// MARK: - Live Message Stream
struct WorkoutLiveMessageStream: View {

    let messages: [WorkoutLiveMessage]

    private let maximumVisibleMessages = 5

    private var visibleMessages: [WorkoutLiveMessage] {
        Array(
            messages.suffix(maximumVisibleMessages)
        )
    }

    var body: some View {

        GeometryReader { geometry in

            ZStack(
                alignment: .bottomLeading
            ) {

                ForEach(
                    Array(visibleMessages.enumerated()),
                    id: \.element.id
                ) { index, message in

                    let reverseIndex =
                        visibleMessages.count - 1 - index

                    WorkoutLiveAnimatedMessageRow(
                        message: message,
                        position: reverseIndex,
                        availableHeight: geometry.size.height
                    )
                    .id(message.id)
                }
            }
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: .bottomLeading
            )
            .clipped()

            .mask {

                LinearGradient(
                    stops: [

                        .init(
                            color: .clear,
                            location: 0
                        ),

                        .init(
                            color: .white,
                            location: 0.18
                        ),

                        .init(
                            color: .white,
                            location: 1
                        )
                    ],

                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            
        }
    }
}

// MARK: - Live Message Row

struct WorkoutLiveMessageRow: View {

    let message: WorkoutLiveMessage

    var body: some View {

        HStack(
            alignment: .top,
            spacing: 8
        ) {

            profileImage

            VStack(
                alignment: .leading,
                spacing: 2
            ) {

                Text(message.username)
                    .font(
                        .system(
                            size: 14,
                            weight: .bold
                        )
                    )
                    .foregroundStyle(
                        .white.opacity(0.9)
                    )

                Text(message.message)
                    .font(
                        .system(
                            size: 16,
                            weight: .semibold
                        )
                    )
                    .foregroundStyle(.white)
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )
            }
            .shadow(color: .black.opacity(0.25), radius: 2, x: 0, y: 1)

            Spacer(
                minLength: 0
            )
        }
    }


    // MARK: Profile Image

    @ViewBuilder
    private var profileImage: some View {

        if let url = message.profileImageURL {

            AsyncImage(url: url) { phase in

                switch phase {

                case .success(let image):

                    image
                        .resizable()
                        .scaledToFill()

                default:

                    placeholderAvatar
                }
            }
            .frame(
                width: 35,
                height: 35
            )
            .clipShape(Circle())

        } else {

            placeholderAvatar
        }
    }


    private var placeholderAvatar: some View {

        Image(
            systemName: "person.crop.circle.fill"
        )
        .resizable()
        .scaledToFit()
        .foregroundStyle(
            .white.opacity(0.8)
        )
        .frame(
            width: 30,
            height: 30
        )
    }
}


// MARK: - Animated Live Message Row

struct WorkoutLiveAnimatedMessageRow: View {

    let message: WorkoutLiveMessage

    /// 0 = newest / bottom message
    /// 1 = one above newest
    /// etc.
    let position: Int

    let availableHeight: CGFloat

    @State private var hasAppeared = false


    private let rowSpacing: CGFloat = 54


    var body: some View {

        WorkoutLiveMessageRow(
            message: message
        )
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )

        // MARK: Vertical Position

        .offset(
            y: verticalOffset
        )

        // MARK: Fade Older Messages

        .opacity(
            messageOpacity
        )

        // MARK: Slight Scale

        .scaleEffect(
            messageScale,
            anchor: .leading
        )

        // MARK: New Message Entrance

        .onAppear {

            hasAppeared = false

            withAnimation(
                .spring(
                    response: 0.48,
                    dampingFraction: 0.84
                )
            ) {

                hasAppeared = true
            }
        }

        // MARK: Move Existing Messages Up

        .animation(
            .spring(
                response: 0.48,
                dampingFraction: 0.84
            ),
            value: position
        )
    }


    // MARK: - Position

    private var verticalOffset: CGFloat {

        if !hasAppeared {

            // Start BELOW the visible message area.

            return 70
        }

        // Newest message = bottom.
        // Older messages move upward.

        return -CGFloat(position) * rowSpacing
    }


    // MARK: - Opacity

    private var messageOpacity: Double {

        guard hasAppeared else {
            return 0
        }

        switch position {

        case 0:
            return 1.0

        case 1:
            return 1.0

        case 2:
            return 0.9

        case 3:
            return 0.65

        case 4:
            return 0.25

        default:
            return 0
        }
    }


    // MARK: - Scale

    private var messageScale: CGFloat {

        switch position {

        case 0:
            return 1.0

        case 1:
            return 0.98

        case 2:
            return 0.96

        default:
            return 0.94
        }
    }
}
