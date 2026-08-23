//
//  TimeAxisRenderer.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/22/26.
//


import SpriteKit


@MainActor
final class TimeAxisRenderer {

    // =====================================================
    // MARK: - Tick Model
    // =====================================================

    private struct TickSpecification {

        let key: String
        let text: String
        let time: DayTime
        let verticalAlignment: SKLabelVerticalAlignmentMode
    }


    private struct RenderedTick {

        let worldY: CGFloat
        let node: SKLabelNode
    }


    private struct LayoutSignature: Equatable {

        let cameraPosition: CGPoint
        let cameraXScale: CGFloat
        let cameraYScale: CGFloat
        let cameraRotation: CGFloat
        let viewBounds: CGRect
    }


    // =====================================================
    // MARK: - Nodes / State
    // =====================================================

    private let container = SKNode()

    private var ticks: [RenderedTick] = []

    private var lastLayoutSignature: LayoutSignature?


    // =====================================================
    // MARK: - Style
    // =====================================================

    private let horizontalInset: CGFloat = 24
    private let fontSize: CGFloat = 40


    // =====================================================
    // MARK: - Attach
    // =====================================================

    func attach(
        to camera: SKCameraNode
    ) {

        if container.parent !== camera {

            container.removeFromParent()

            container.name =
                "time-axis-container"

            container.zPosition =
                MapLayerZ.persistentUI

            container.isUserInteractionEnabled =
                false

            camera.addChild(
                container
            )
        }


        if ticks.isEmpty {
            buildLabels()
        }


        invalidateLayout()
    }


    // =====================================================
    // MARK: - Layout Invalidating
    // =====================================================

    func invalidateLayout() {

        lastLayoutSignature = nil
    }


    // =====================================================
    // MARK: - Build
    // =====================================================

    private func buildLabels() {

        container.removeAllChildren()
        ticks.removeAll(
            keepingCapacity: true
        )


        for specification in tickSpecifications {

            let worldY =
                MapCoordinateConverter
                    .worldY(
                        for: specification.time
                    )


            let label = SKLabelNode()

            label.text =
                specification.text

            label.fontName =
                "AvenirNext-Medium"

            label.fontSize =
                fontSize

            label.fontColor =
                .white
                .withAlphaComponent(0.82)

            label.horizontalAlignmentMode =
                .left

            label.verticalAlignmentMode =
                specification.verticalAlignment

            label.name =
                "time-axis-\(specification.key)"

            label.position =
                .zero

            label.isUserInteractionEnabled =
                false


            container.addChild(
                label
            )


            ticks.append(
                RenderedTick(
                    worldY: worldY,
                    node: label
                )
            )
        }
    }


    /// Only the five semantic labels requested for the Fifoo day axis are
    /// created. The earlier renderer created 24 label nodes even though 19
    /// of them contained empty strings.
    ///
    /// The final label is anchored to the exact end-of-day boundary but is
    /// named "11:59 PM" to retain the existing product wording.
    private var tickSpecifications: [TickSpecification] {

        [
            TickSpecification(
                key: "12am",
                text: "12 AM",
                time: .startOfDay,
                verticalAlignment: .top
            ),

            TickSpecification(
                key: "6am",
                text: "6 AM",
                time:
                    DayTime(
                        secondsFromMidnight:
                            6 * DayTime.secondsPerHour
                    ),
                verticalAlignment: .center
            ),

            TickSpecification(
                key: "12pm",
                text: "12 PM",
                time:
                    DayTime(
                        secondsFromMidnight:
                            12 * DayTime.secondsPerHour
                    ),
                verticalAlignment: .center
            ),

            TickSpecification(
                key: "6pm",
                text: "6 PM",
                time:
                    DayTime(
                        secondsFromMidnight:
                            18 * DayTime.secondsPerHour
                    ),
                verticalAlignment: .center
            ),

            TickSpecification(
                key: "1159pm",
                text: "11:59 PM",
                time: .endOfDay,
                verticalAlignment: .bottom
            )
        ]
    }


    // =====================================================
    // MARK: - Update
    // =====================================================

    func update(
        scene: SKScene,
        camera: SKCameraNode,
        view: SKView
    ) {

        let signature =
            LayoutSignature(
                cameraPosition:
                    camera.position,
                cameraXScale:
                    camera.xScale,
                cameraYScale:
                    camera.yScale,
                cameraRotation:
                    camera.zRotation,
                viewBounds:
                    view.bounds
            )


        // Most SpriteKit frames occur while the camera is stationary. Avoid
        // repeating coordinate conversions when nothing that can affect the
        // overlay layout has changed.
        guard signature != lastLayoutSignature else {
            return
        }


        lastLayoutSignature =
            signature


        // -------------------------------------------------
        // Fixed screen X
        // -------------------------------------------------

        let desiredViewPoint =
            CGPoint(
                x:
                    view.bounds.minX
                    + horizontalInset,
                y:
                    view.bounds.midY
            )


        let scenePointAtLeftInset =
            scene.convertPoint(
                fromView: desiredViewPoint
            )


        let cameraPointAtLeftInset =
            camera.convert(
                scenePointAtLeftInset,
                from: scene
            )


        let fixedX =
            cameraPointAtLeftInset.x


        // -------------------------------------------------
        // World-derived Y
        // -------------------------------------------------

        let semanticAxisX =
            MapCoordinateConverter
                .worldX(
                    forProgress: 0
                )


        for tick in ticks {

            let worldPoint =
                CGPoint(
                    x: semanticAxisX,
                    y: tick.worldY
                )


            let cameraLocalPoint =
                camera.convert(
                    worldPoint,
                    from: scene
                )


            tick.node.position =
                CGPoint(
                    x: fixedX,
                    y: cameraLocalPoint.y
                )
        }
    }
}
