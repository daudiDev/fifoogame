//
//  GameNodeMarkerChrome.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/20/26.
//


import SpriteKit


enum GameNodeMarkerChrome {

    static func make(
        isSelected:
            Bool
    ) -> SKNode {

        let root =
            SKNode()


        // MARK: Shadow

        let shadow =
            SKShapeNode(
                circleOfRadius:
                    20
            )


        shadow.fillColor =
            SKColor(
                red:
                    0,
                green:
                    0,
                blue:
                    0,
                alpha:
                    0.25
            )


        shadow.strokeColor =
            .clear


        shadow.position =
            CGPoint(
                x:
                    1.5,
                y:
                    -3
            )


        root.addChild(
            shadow
        )


        // MARK: Pointer

        let pointerPath =
            CGMutablePath()


        pointerPath.move(
            to:
                CGPoint(
                    x:
                        -7,
                    y:
                        -13
                )
        )


        pointerPath.addLine(
            to:
                CGPoint(
                    x:
                        7,
                    y:
                        -13
                )
        )


        pointerPath.addLine(
            to:
                CGPoint(
                    x:
                        0,
                    y:
                        -24
                )
        )


        pointerPath.closeSubpath()


        let pointer =
            SKShapeNode(
                path:
                    pointerPath
            )


        pointer.fillColor =
            SKColor(
                red:
                    0.94,
                green:
                    0.95,
                blue:
                    0.96,
                alpha:
                    1
            )


        pointer.strokeColor =
            .clear


        root.addChild(
            pointer
        )


        // MARK: Plate

        let plate =
            SKShapeNode(
                circleOfRadius:
                    18
            )


        plate.fillColor =
            SKColor(
                red:
                    0.94,
                green:
                    0.95,
                blue:
                    0.96,
                alpha:
                    1
            )


        plate.strokeColor =
            isSelected
            ?
            MapVisualTheme
                .roadSelectionColor
            :
            SKColor(
                white:
                    1,
                alpha:
                    0.22
            )


        plate.lineWidth =
            isSelected
            ? 3
            : 1


        root.addChild(
            plate
        )


        if isSelected {

            let halo =
                SKShapeNode(
                    circleOfRadius:
                        24
                )


            halo.fillColor =
                .clear


            halo.strokeColor =
                MapVisualTheme
                    .roadSelectionHaloColor


            halo.lineWidth =
                5


            halo.zPosition =
                -2


            root.addChild(
                halo
            )
        }


        return root
    }
}