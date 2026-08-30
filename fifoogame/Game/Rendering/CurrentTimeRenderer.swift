//
//  CurrentTimeRenderer.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/18/26.
//

import SpriteKit


@MainActor
final class CurrentTimeRenderer {

    // MARK: - Container

    let containerNode =
        SKNode()


    // MARK: - Nodes

    /// Pass 5.60.3: the live-position treatment is intentionally label-only.
    /// No current-time line, dot, halo, or card-boundary marker is rendered.
    private let badgeNode =
        SKShapeNode()

    private let timeLabel =
        SKLabelNode(
            fontNamed:
                "HelveticaNeue-Bold"
        )


    // MARK: - Init

    init() {

        configureNodes()
    }


    // MARK: - Setup

    private func configureNodes() {

        containerNode.name =
            "currentTimeIndicator"

        containerNode.isUserInteractionEnabled =
            false


        let badgeSize =
            CGSize(
                width: 126,
                height: 26
            )

        let badgeRect =
            CGRect(
                x: -badgeSize.width / 2,
                y: -badgeSize.height / 2,
                width: badgeSize.width,
                height: badgeSize.height
            )

        badgeNode.name =
            "currentTimeBadge"

        badgeNode.path =
            CGPath(
                roundedRect: badgeRect,
                cornerWidth: 13,
                cornerHeight: 13,
                transform: nil
            )

        badgeNode.fillColor =
            RouteVisualTheme
                .boundaryStrokeColor
                .withAlphaComponent(0.98)

        badgeNode.strokeColor =
            .white

        badgeNode.lineWidth =
            2

        badgeNode.zPosition =
            200

        badgeNode.isUserInteractionEnabled =
            false


        timeLabel.name =
            "currentTimeLabel"

        timeLabel.fontSize =
            10

        timeLabel.fontColor =
            .white

        timeLabel.horizontalAlignmentMode =
            .center

        timeLabel.verticalAlignmentMode =
            .center

        timeLabel.zPosition =
            201

        timeLabel.isUserInteractionEnabled =
            false


        containerNode.addChild(
            badgeNode
        )

        containerNode.addChild(
            timeLabel
        )
    }


    // MARK: - Render

    /// Places the live-user label at the user's true semantic position:
    ///
    /// - Y is derived directly from the exact current DayTime.
    /// - X is derived directly from the current user progress percentage.
    ///
    /// This deliberately does not use the current route-boundary tile, because
    /// a route stop's scheduled time is not necessarily the current clock time.
    func render(
        time: DayTime,
        progressPercent: Double
    ) {

        let coordinate =
            MapCoordinate(
                time:
                    time,
                progress:
                    MapProgress(
                        progressPercent
                    )
            )

        let point =
            MapCoordinateConverter
                .worldPoint(
                    for:
                        coordinate
                )

        let position =
            CGPoint(
                x: point.x,
                y: point.y
            )

        badgeNode.position =
            position

        timeLabel.position =
            position

        timeLabel.text =
            "ME • NOW • \(time.displayClockString)"
    }
}
