//
//  MapGridRenderer.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/18/26.
//

import SpriteKit


@MainActor
final class MapGridRenderer {

    // MARK: - Container

    let containerNode =
        SKNode()


    // MARK: - Init

    init() {

        containerNode.name =
            "coordinateGrid"
    }


    // MARK: - Build

    func rebuild() {

        containerNode.removeAllChildren()

        drawProgressGrid()

        drawTimeGrid()

        drawProgressLabels()

        drawTimeLabels()
    }
}


// MARK: - Progress Grid

private extension MapGridRenderer {

    func drawProgressGrid() {

        /*
         Extended camera/debug range:

            -50 ... 150

         Primary gameplay reference:

              0 ... 100
         */

        for progress in stride(
            from: -50,
            through: 150,
            by: 5
        ) {

            let coordinate =
                MapCoordinate(
                    time:
                        .startOfDay,
                    progress:
                        MapProgress(
                            Double(progress)
                        )
                )


            let point =
                MapCoordinateConverter
                    .worldPoint(
                        for:
                            coordinate
                    )


            let path =
                CGMutablePath()


            path.move(
                to:
                    CGPoint(
                        x:
                            point.x,
                        y:
                            0
                    )
            )


            path.addLine(
                to:
                    CGPoint(
                        x:
                            point.x,
                        y:
                            -MapWorldConfiguration.height
                    )
            )


            let line =
                SKShapeNode(
                    path:
                        path
                )


            line.name =
                "progressGrid-\(progress)"


            let isReferenceBoundary =
                progress == 0
                || progress == 100


            let isMajor =
                progress % 25 == 0


            let isOutsidePrimaryRange =
                progress < 0
                || progress > 100


            if isReferenceBoundary {

                line.strokeColor = MapVisualTheme.referenceBoundaryColor

                line.lineWidth = 6

            } else if isMajor {

                line.strokeColor = MapVisualTheme.majorGridColor

                line.lineWidth = 4

            } else {

                line.strokeColor = MapVisualTheme.minorGridColor
                line.lineWidth = 2
                
            }

            containerNode.addChild(
                line
            )
        }
    }
}


// MARK: - Time Grid

private extension MapGridRenderer {

    func drawTimeGrid() {

        for hour in 0...24 {

            let seconds =
                min(
                    TimeInterval(
                        hour * 3600
                    ),
                    DayTime.secondsPerDay
                )


            let coordinate =
                MapCoordinate(
                    time:
                        DayTime(
                            secondsFromMidnight:
                                seconds
                        ),
                    progress:
                        MapProgress(0)
                )


            let point =
                MapCoordinateConverter
                    .worldPoint(
                        for:
                            coordinate
                    )


            let path =
                CGMutablePath()


            /*
             IMPORTANT:

             Time lines now span the entire
             extended horizontal map.

             Not just 0...100%.
             */

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


            let line =
                SKShapeNode(
                    path:
                        path
                )


            let isMajor =
                hour % 6 == 0


            line.strokeColor =
                SKColor.white
                    .withAlphaComponent(
                        isMajor
                        ? 0.30
                        : 0.08
                    )


            line.lineWidth =
                isMajor
                ? 4
                : 2


            containerNode.addChild(
                line
            )
        }
    }
}


// MARK: - Progress Labels

private extension MapGridRenderer {

    func drawProgressLabels() {

        let values = [

            -50,
            -25,

            0,
            25,
            50,
            75,
            100,

            125,
            150
        ]


        for progress in values {

            let coordinate =
                MapCoordinate(
                    time:
                        .startOfDay,
                    progress:
                        MapProgress(
                            Double(progress)
                        )
                )


            let point =
                MapCoordinateConverter
                    .worldPoint(
                        for:
                            coordinate
                    )


            let label =
                SKLabelNode(
                    fontNamed:
                        "HelveticaNeue-Medium"
                )


            label.text =
                "\(progress)%"


            label.fontSize =
                30

            
            label.fontColor =
                MapVisualTheme.gridLabelColor


            label.position =
                CGPoint(
                    x:
                        point.x,
                    y:
                        -48
                )


            label.horizontalAlignmentMode =
                .center


            label.verticalAlignmentMode =
                .center


            containerNode.addChild(
                label
            )
        }
    }
}


// MARK: - Time Labels

private extension MapGridRenderer {

    func drawTimeLabels() {

        let labeledHours = [

            0,
            6,
            12,
            18,
            24
        ]


        for hour in labeledHours {

            let seconds =
                min(
                    TimeInterval(
                        hour * 3600
                    ),
                    DayTime.secondsPerDay
                )


            let coordinate =
                MapCoordinate(
                    time:
                        DayTime(
                            secondsFromMidnight:
                                seconds
                        ),
                    progress:
                        MapProgress(0)
                )


            let point =
                MapCoordinateConverter
                    .worldPoint(
                        for:
                            coordinate
                    )


            let label =
                SKLabelNode(
                    fontNamed:
                        "HelveticaNeue-Bold"
                )


            label.text =
                timeLabel(
                    for:
                        hour
                )


            label.fontSize =
                30


            label.fontColor =
                SKColor.white
                    .withAlphaComponent(
                        0.90
                    )


            /*
             Keep time labels near the normal
             0% line.

             They are WORLD labels, not HUD
             labels, so they move with the map.
             */

            label.position =
                CGPoint(
                    x:
                        16,
                    y:
                        point.y
                )


            label.horizontalAlignmentMode =
                .left


            label.verticalAlignmentMode =
                .center


            if hour == 0 {

                label.position.y -=
                    38

            } else if hour == 24 {

                label.position.y +=
                    38
            }


            containerNode.addChild(
                label
            )
        }
    }


    func timeLabel(
        for hour:
            Int
    ) -> String {

        switch hour {

        case 0:
            return "12 AM"

        case 6:
            return "6 AM"

        case 12:
            return "12 PM"

        case 18:
            return "6 PM"

        case 24:
            return "11:59 PM"

        default:
            return ""
        }
    }
}
