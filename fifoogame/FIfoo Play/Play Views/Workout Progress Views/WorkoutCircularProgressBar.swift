//
//  WorkoutCircularProgressBar.swift
//  Learn Canvas
//
//  Created by Daudi Sagala on 8/12/26.
//


import SwiftUI

struct WorkoutCircularProgressBar: View {

        let progress: Double

        // MARK: - Configuration

        private let segmentCount = 11

        private let lineWidth: CGFloat = 6

        /// Space between individual segments.
        private let gapDegrees: Double = 8

        private let activeColor = Color(
            red: 0.08,
            green: 0.67,
            blue: 0.94
        )

        private let inactiveColor = Color(
            red: 0.88,
            green: 0.96,
            blue: 1.0
        )

        // MARK: - Progress

        private var clampedProgress: Double {
            min(
                max(progress, 0),
                1
            )
        }

        private var percentageText: String {
            "\(Int((clampedProgress * 100).rounded()))%"
        }

        /// Converts continuous progress into completed ring segments.
        ///
        /// 64% with 11 segments:
        /// 0.64 × 11 = 7.04
        /// => 7 completed segments.
        private var completedSegments: Int {
            Int(
                (
                    clampedProgress
                    * Double(segmentCount)
                )
                .rounded()
            )
        }

        // MARK: - Body

        var body: some View {

            ZStack {

                // MARK: Segmented circular progress

                ForEach(
                    0..<segmentCount,
                    id: \.self
                ) { index in

                    segment(
                        index: index,
                        isCompleted:
                            index < completedSegments
                    )
                }

                // MARK: Percentage

                Text(percentageText)
                    .font(
                        .system(
                            size: 14,
                            weight: .medium,
                            design: .default
                        )
                    )
                    .foregroundStyle(.primary)
                    .monospacedDigit()
            }
            .frame(
                width: 50,
                height: 50
            )
            .animation(
                .easeInOut(duration: 0.35),
                value: completedSegments
            )
        }

        // MARK: - Segment

        private func segment(
            index: Int,
            isCompleted: Bool
        ) -> some View {

            let sectionDegrees =
                360.0
                / Double(segmentCount)

            let startDegrees =
                Double(index)
                * sectionDegrees
                + gapDegrees / 2

            let endDegrees =
                Double(index + 1)
                * sectionDegrees
                - gapDegrees / 2

            let start =
                startDegrees / 360

            let end =
                endDegrees / 360

            return Circle()
                .trim(
                    from: start,
                    to: end
                )
                .stroke(
                    isCompleted
                        ? activeColor
                        : inactiveColor,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .butt
                    )
                )
                .rotationEffect(
                    .degrees(-90)
                )
        }
    }
