//
//  WorkoutLiveOverlay.swift
//  Fifoo Play
//
//  Created by Daudi Sagala on 8/16/26.
//


import SwiftUI


// MARK: - Workout Live Overlay
struct WorkoutLiveOverlay: View {
    let geometry: GeometryProxy
    let messages: [WorkoutLiveMessage]

    @State private var hearts: [FloatingHeart] = []

    var body: some View {

        ZStack {


            HStack(
                alignment: .bottom,
                spacing: 8
            ) {

                // MARK: Messages

                WorkoutLiveMessageStream(
                    messages: messages
                )
                .frame(
                    maxWidth: .infinity,
                    maxHeight: geometry.size.height * 0.35,
                    alignment: .bottomLeading
                )
                .shadow(color: .black.opacity(0.25), radius: 2, x: 1, y: 1)

                // MARK: Hearts

                FloatingHeartsView(
                    hearts: hearts
                )
                .frame(width: 55)
                .frame(
                    maxHeight: geometry.size.height * 0.2,
                    alignment: .bottom
                )
                .shadow(color: .black.opacity(0.25), radius: 2, x: 1, y: 1)
              
            }
            .padding(12)
        }
        .padding(.bottom)
        .clipShape(
            RoundedRectangle(
                cornerRadius: 10,
                style: .continuous
            )
        )

        // The live UI remains visual-only.
        // Buttons and PlayView's swipe gesture continue
        // receiving interaction normally.
        .allowsHitTesting(false)

    }
}


private extension WorkoutLiveOverlay {

    func generateDemoHearts() async {

        while !Task.isCancelled {

            let delay =
                Double.random(
                    in: 0.7...1.7
                )

            do {

                try await Task.sleep(
                    for: .seconds(delay)
                )

            } catch {

                return
            }

            guard !Task.isCancelled else {
                return
            }

            await MainActor.run {

                addHeart()
            }
        }
    }


    func addHeart() {

        let possibleHearts = [
            "❤️",
            "💙",
            "💚",
            "🧡",
            "💜",
            "🔥",
            "💪"
        ]

        let heart = FloatingHeart(

            emoji:
                possibleHearts.randomElement()
                ?? "❤️",

            horizontalOffset:
                CGFloat.random(
                    in: -30...15
                ),

            size:
                CGFloat.random(
                    in: 24...38
                ),

            duration:
                Double.random(
                    in: 2.3...3.6
                )
        )

        hearts.append(heart)


        // Prevent the array from growing forever.

        if hearts.count > 15 {

            hearts.removeFirst(
                hearts.count - 15
            )
        }
    }
}
