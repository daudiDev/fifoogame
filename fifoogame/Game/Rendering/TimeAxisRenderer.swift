//
//  TimeAxisRenderer.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/20/26.
//


import SpriteKit


final class TimeAxisRenderer {

    // MARK: - Nodes

    private let container = SKNode()

    private struct HourLabel {
        let hour: Int
        let worldY: CGFloat
        let node: SKLabelNode
    }

    private var labels: [HourLabel] = []


    // MARK: - Style

    private let horizontalInset: CGFloat = 24
    private let fontSize: CGFloat = 32


    // MARK: - Attach

    func attach(
        to camera: SKCameraNode
    ) {

        guard container.parent == nil else {
            return
        }

        container.name = "time-axis-container"

        // Very high so labels render over roads/routes/nodes.
//        container.zPosition = 100_000 //MARK: may change
        
        container.zPosition =
            MapLayerZ.persistentUI

        camera.addChild(container)

        buildLabels()
    }


    // MARK: - Build

    private func buildLabels() {

        container.removeAllChildren()
        labels.removeAll()

        for hour in 0 ... 23 {

            let dayTime = DayTime(
                secondsFromMidnight:
                    TimeInterval(hour * 3_600)
            )

            let mapCoordinate = MapCoordinate(
                time: dayTime,
                progress: MapProgress(0)
            )

            let worldPoint =
                MapCoordinateConverter
                    .worldPoint(
                        for: mapCoordinate
                    )
                    .cgPoint


            let label = SKLabelNode()

            label.text = hourText(hour)

            label.fontName = "AvenirNext-Medium"
            label.fontSize = fontSize
            label.fontColor = .white.withAlphaComponent(0.8)

            label.horizontalAlignmentMode = .left
            label.verticalAlignmentMode = .center

            label.name = "time-axis-hour-\(hour)"

            /*
             x/y are assigned later.

             Because this label is a CHILD OF THE CAMERA,
             its position is effectively screen-relative.
            */
            label.position = .zero

            container.addChild(label)

            labels.append(
                HourLabel(
                    hour: hour,
                    worldY: worldPoint.y,
                    node: label
                )
            )
        }
    }


    // MARK: - Update

    func update(
        scene: SKScene,
        camera: SKCameraNode,
        view: SKView
    ) {

        // =====================================================
        // Fixed screen X
        // =====================================================
        //
        // Instead of manually calculating camera scale, convert
        // an actual UIKit view coordinate into camera-local
        // coordinates.
        //
        // This handles:
        //
        // - camera zoom
        // - scene scaleMode
        // - scene anchor point
        // - different screen sizes
        //
        // automatically.
        // =====================================================

        let desiredViewPoint =
            CGPoint(
                x: horizontalInset,
                y: view.bounds.midY
            )


        let scenePointAtLeftEdge =
            scene.convertPoint(
                fromView: desiredViewPoint
            )


        let cameraPointAtLeftEdge =
            camera.convert(
                scenePointAtLeftEdge,
                from: scene
            )


        let fixedX =
            cameraPointAtLeftEdge.x


        // =====================================================
        // Update every hour.
        // =====================================================

        for item in labels {

            /*
             Convert the hour's WORLD Y into CAMERA-LOCAL Y.

             This is the key.

             The label itself lives in the camera, so X doesn't
             follow the world.

             But its Y is calculated from its real world
             coordinate, so vertical scrolling still affects it.
            */

            let worldPoint =
                CGPoint(
                    x: 0,
                    y: item.worldY
                )


            let cameraLocalPoint =
                camera.convert(
                    worldPoint,
                    from: scene
                )


            item.node.position =
                CGPoint(
                    x: fixedX,
                    y: cameraLocalPoint.y
                )
        }
    }


    // MARK: - Text

    private func hourText(
        _ hour: Int
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
