//
//  UserCircularProgressBar.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/23/26.
//


import SwiftUI

struct UserCircularProgressBar: View {

    let progress: Double

    // MARK: - Configuration

    private let segmentCount = 11

    private let lineWidth: CGFloat = 6

    /// Space between individual segments.
    private let gapDegrees: Double = 8

    private let activeColor = Color.green

    private let inactiveColor = Color(
        red: 0.88,
        green: 0.96,
        blue: 1.0
    )

    // MARK: - Progress

    private var clampedProgress: Double {
        min(max(progress, 0),1)
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

            // Give the percentage its own quiet, high-contrast center so it
            // remains legible over the shared translucent top-row material.
            Circle()
                .fill(
                    Color.black.opacity(0.58)
                )
                .frame(
                    width: 31,
                    height: 31
                )

            // MARK: Percentage

            Text(percentageText)
                .font(
                    .system(
                        size: 14,
                        weight: .bold,
                        design: .default
                    )
                )
                .foregroundStyle(
                    Color.green.opacity(0.98)
                )
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(
                    0.7
                )
                .shadow(
                    color: Color.black.opacity(0.75),
                    radius: 1.5,
                    x: 0,
                    y: 1
                )
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
