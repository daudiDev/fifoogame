//
//  FloatingHeartsView.swift
//  Fifoo Play
//
//  Created by Daudi Sagala on 8/16/26.
//

import SwiftUI

struct WorkoutLiveReaction:
    Identifiable,
    Codable,
    Equatable {

    let id: UUID

    let emoji: String

    let createdAt: Date


    init(
        id: UUID = UUID(),
        emoji: String,
        createdAt: Date = .now
    ) {

        self.id =
            id

        self.emoji =
            emoji

        self.createdAt =
            createdAt
    }
}

// MARK: - Floating Heart Model
struct FloatingHeart: Identifiable, Equatable {

    let id = UUID()

    let emoji: String

    let horizontalOffset: CGFloat
    let size: CGFloat
    let duration: Double

    var isAnimating: Bool = false
}


// MARK: - Floating Hearts View
struct FloatingHeartsView: View {

    let hearts: [FloatingHeart]

    var body: some View {

        ZStack(
            alignment: .bottom
        ) {

            ForEach(hearts) { heart in

                FloatingHeartView(
                    heart: heart
                )
            }
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )

        // Keeps hearts from rendering outside
        // the live-reaction area.
        .clipped()

        // MARK: Soft Fade-Out At Top

        .mask {

            LinearGradient(
                stops: [

                    // Completely invisible at the very top
                    .init(
                        color: .clear,
                        location: 0.00
                    ),

                    // Begin appearing gradually
                    .init(
                        color: .white.opacity(0.25),
                        location: 0.10
                    ),

                    .init(
                        color: .white.opacity(0.65),
                        location: 0.20
                    ),

                    // Fully visible through the remainder
                    .init(
                        color: .white,
                        location: 0.32
                    ),

                    .init(
                        color: .white,
                        location: 1.00
                    )
                ],

                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}


// MARK: - Floating Heart
struct FloatingHeartView: View {

    let heart: FloatingHeart

    @State private var animate = false

    var body: some View {

        Text(heart.emoji)
            .font(
                .system(
                    size: heart.size
                )
            )

            // MARK: Movement

            .offset(
                x:
                    animate
                    ? heart.horizontalOffset
                    : 0,

                y:
                    animate
                    ? -220
                    : 0
            )

            // MARK: Scale

            .scaleEffect(
                animate
                ? 1.15
                : 0.7
            )

            // Keep it mostly visible during its travel.
            // The FloatingHeartsView mask handles the
            // smooth fade as it reaches the top.
            .opacity(
                animate
                ? 0.85
                : 1
            )

            .onAppear {

                withAnimation(
                    .easeOut(
                        duration: heart.duration
                    )
                ) {

                    animate = true
                }
            }
    }
}
