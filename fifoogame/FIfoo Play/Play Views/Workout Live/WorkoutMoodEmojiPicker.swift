//
//  WorkoutMoodEmojiPicker.swift
//  Fifoo Play
//
//  Created by Daudi Sagala on 8/17/26.
//


import SwiftUI


// MARK: - Workout Mood Emoji Picker

struct WorkoutMoodEmojiPicker: View {

    let onSelect:
        (String) -> Void


    private let emojis: [MoodEmoji] = [

        MoodEmoji(
            emoji: "🔥",
            label: "Fired up"
        ),

        MoodEmoji(
            emoji: "💪",
            label: "Strong"
        ),

        MoodEmoji(
            emoji: "😄",
            label: "Great"
        ),

        MoodEmoji(
            emoji: "🙂",
            label: "Good"
        ),

        MoodEmoji(
            emoji: "😐",
            label: "Okay"
        ),

        MoodEmoji(
            emoji: "🥵",
            label: "Exhausted"
        ),

        MoodEmoji(
            emoji: "😤",
            label: "Pushing"
        ),

        MoodEmoji(
            emoji: "😫",
            label: "Struggling"
        ),

        MoodEmoji(
            emoji: "❤️",
            label: "Loving it"
        )
    ]


    private let columns = [

        GridItem(
            .flexible()
        ),

        GridItem(
            .flexible()
        ),

        GridItem(
            .flexible()
        )
    ]


    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 16
        ) {

            VStack(
                alignment: .leading,
                spacing: 3
            ) {

                Text(
                    "How is your workout?"
                )
                .font(
                    .headline
                )

                Text(
                    "Share your mood"
                )
                .font(
                    .caption
                )
                .foregroundStyle(
                    .secondary
                )
            }


            LazyVGrid(
                columns:
                    columns,
                spacing: 16
            ) {

                ForEach(emojis) { mood in

                    Button {

                        onSelect(
                            mood.emoji
                        )

                    } label: {

                        VStack(
                            spacing: 5
                        ) {

                            Text(
                                mood.emoji
                            )
                            .font(
                                .system(
                                    size: 34
                                )
                            )

                            Text(
                                mood.label
                            )
                            .font(
                                .system(
                                    size: 10,
                                    weight: .semibold
                                )
                            )
                            .foregroundStyle(
                                .primary
                            )
                            .lineLimit(1)
                            .minimumScaleFactor(
                                0.7
                            )
                        }
                        .frame(
                            maxWidth:
                                .infinity
                        )
                    }
                    .buttonStyle(
                        .plain
                    )
                }
            }
        }
        .padding(20)
        .frame(
            width: 300
        )
    }
}


// MARK: - Mood Emoji Model

private struct MoodEmoji:
    Identifiable {

    let id = UUID()

    let emoji: String
    let label: String
}
