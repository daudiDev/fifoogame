//
//  CurrentTimeRenderer.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/18/26.
//


//
//  CurrentTimeRenderer.swift
//  Fifoo
//

import SpriteKit


@MainActor
final class CurrentTimeRenderer {

    // MARK: - Container

    let containerNode =
        SKNode()


    // MARK: - Nodes

    private let timeLine =
        SKShapeNode()


    private let currentPositionMarker =
        SKShapeNode(
            circleOfRadius:
                18
        )


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


        timeLine.name =
            "currentTimeLine"


        timeLine.strokeColor =
            .systemRed


        timeLine.lineWidth =
            6


        timeLine.glowWidth =
            2


        currentPositionMarker.name =
            "currentTimeMarker"


        currentPositionMarker.fillColor =
            .systemRed


        currentPositionMarker.strokeColor =
            .white


        currentPositionMarker.lineWidth =
            4


        timeLabel.name =
            "currentTimeLabel"


        timeLabel.fontSize =
            28


        timeLabel.fontColor =
            .white


        timeLabel.horizontalAlignmentMode =
            .center


        timeLabel.verticalAlignmentMode =
            .bottom


        containerNode.addChild(
            timeLine
        )


        containerNode.addChild(
            currentPositionMarker
        )


        containerNode.addChild(
            timeLabel
        )
    }


    // MARK: - Render

    func render(
        time:
            DayTime
    ) {

        /*
         We still use 50% as our temporary
         current-progress reference.

         A real current progress value arrives
         later with ProgressScorer.
         */

        let coordinate =
            MapCoordinate(
                time:
                    time,
                progress:
                    MapProgress(50)
            )


        let point =
            MapCoordinateConverter
                .worldPoint(
                    for:
                        coordinate
                )


        // MARK: Current-Time Line

        let path =
            CGMutablePath()


        path.move(
            to:
                CGPoint(
                    x:
                        MapWorldConfiguration
                            .minimumExplorableX,
                    y:
                        point.y
                )
        )


        path.addLine(
            to:
                CGPoint(
                    x:
                        MapWorldConfiguration
                            .maximumExplorableX,
                    y:
                        point.y
                )
        )


        timeLine.path =
            path


        // MARK: Current Progress Reference

        currentPositionMarker.position =
            CGPoint(
                x:
                    point.x,
                y:
                    point.y
            )


        // MARK: Label

        timeLabel.text =
            "NOW • \(time.displayClockString)"


        timeLabel.position =
            CGPoint(
                x:
                    point.x,
                y:
                    point.y + 35
            )
    }
}
