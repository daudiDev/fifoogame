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

    // MARK: - Body

    var body: some View {

        // MARK: Percentage

        Text(percentageText)
            .font(.custom("Chewy-Regular", size: 32))
            .foregroundStyle(
                Color.green.opacity(0.98)
            )
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(
                0.5
            )
    }
}
