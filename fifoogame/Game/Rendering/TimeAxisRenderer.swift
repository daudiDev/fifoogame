//
//  TimeAxisRenderer.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/23/26.
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
    }


    private struct RenderedTick {
        let worldY: CGFloat
        let node: SKNode
        let size: CGSize
    }


    private struct LayoutSignature: Equatable {
        let cameraPosition: CGPoint
        let cameraXScale: CGFloat
        let cameraYScale: CGFloat
        let cameraRotation: CGFloat
        let viewBounds: CGRect
        let safeAreaTop: CGFloat
        let safeAreaLeft: CGFloat
        let safeAreaBottom: CGFloat
        let safeAreaRight: CGFloat
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

    /// Space between the left safe-area edge and the label pill.
    private let horizontalInset: CGFloat = 16

    /// Space between a label pill and the safe top/bottom visible edge.
    private let verticalEdgeMargin: CGFloat = 10

    private let fontSize: CGFloat = 32

    private let horizontalPadding: CGFloat = 16
    private let verticalPadding: CGFloat = 8
    private let backgroundCornerRadius: CGFloat = 15

    private let backgroundColor =
        SKColor(
            red: 39/255,
            green: 121/255,
            blue: 245/255,
            alpha: 0.95
        )

    private let backgroundBorderColor =
        SKColor.white.withAlphaComponent(0.20)

    private let backgroundBorderWidth: CGFloat = 1.25

    private let textColor =
        SKColor.white.withAlphaComponent(0.96)


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
                "AvenirNext-DemiBold"

            label.fontSize =
                fontSize

            label.fontColor =
                textColor

            label.horizontalAlignmentMode =
                .center

            label.verticalAlignmentMode =
                .center

            label.position =
                .zero

            label.zPosition =
                1

            label.isUserInteractionEnabled =
                false


            let textSize =
                label.frame.size

            let pillSize =
                CGSize(
                    width:
                        ceil(textSize.width)
                        + (horizontalPadding * 2),
                    height:
                        ceil(textSize.height)
                        + (verticalPadding * 2)
                )


            let background =
                SKShapeNode(
                    rectOf: pillSize,
                    cornerRadius:
                        min(
                            backgroundCornerRadius,
                            pillSize.height * 0.5
                        )
                )

            background.fillColor =
                backgroundColor

            background.strokeColor =
                backgroundBorderColor

            background.lineWidth =
                backgroundBorderWidth

            background.zPosition =
                0

            background.isAntialiased =
                true

            background.isUserInteractionEnabled =
                false


            let tickNode = SKNode()

            tickNode.name =
                "time-axis-\(specification.key)"

            tickNode.isUserInteractionEnabled =
                false

            tickNode.addChild(
                background
            )

            tickNode.addChild(
                label
            )

            container.addChild(
                tickNode
            )


            ticks.append(
                RenderedTick(
                    worldY: worldY,
                    node: tickNode,
                    size: pillSize
                )
            )
        }
    }


    private var tickSpecifications: [TickSpecification] {

        [
            TickSpecification(
                key: "12am",
                text: "12 AM",
                time: .startOfDay
            ),

            TickSpecification(
                key: "6am",
                text: "6 AM",
                time:
                    DayTime(
                        secondsFromMidnight:
                            6 * DayTime.secondsPerHour
                    )
            ),

            TickSpecification(
                key: "12pm",
                text: "12 PM",
                time:
                    DayTime(
                        secondsFromMidnight:
                            12 * DayTime.secondsPerHour
                    )
            ),

            TickSpecification(
                key: "6pm",
                text: "6 PM",
                time:
                    DayTime(
                        secondsFromMidnight:
                            18 * DayTime.secondsPerHour
                    )
            ),

            TickSpecification(
                key: "1159pm",
                text: "11:59 PM",
                time:
                    DayTime(
                        secondsFromMidnight:
                            DayTime.secondsPerDay - 60
                    )
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

        let safeAreaInsets =
            view.safeAreaInsets


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
                    view.bounds,
                safeAreaTop:
                    safeAreaInsets.top,
                safeAreaLeft:
                    safeAreaInsets.left,
                safeAreaBottom:
                    safeAreaInsets.bottom,
                safeAreaRight:
                    safeAreaInsets.right
            )


        guard signature != lastLayoutSignature else {
            return
        }

        lastLayoutSignature =
            signature


        // -------------------------------------------------
        // Viewport bounds in CAMERA-LOCAL coordinates
        // -------------------------------------------------
        //
        // Two vertical ranges are intentionally calculated:
        //
        // 1. The PHYSICAL viewport. This tells us whether a
        //    day-boundary label is genuinely still close to
        //    the screen edge.
        //
        // 2. The SAFE viewport. This is where a complete pill
        //    is allowed to sit without being covered by the
        //    status bar / Dynamic Island / home indicator.
        //
        // The important Step 8.1 behavior is that 12 AM and
        // 11:59 PM are NOT permanently pinned to these edges.
        // They are edge-protected only while their real world
        // positions are still intersecting the physical view.

        let safeLeftViewX =
            view.bounds.minX
            + safeAreaInsets.left
            + horizontalInset

        let safeTopViewY =
            view.bounds.minY
            + safeAreaInsets.top
            + verticalEdgeMargin

        let safeBottomViewY =
            view.bounds.maxY
            - safeAreaInsets.bottom
            - verticalEdgeMargin


        func cameraPoint(
            viewX: CGFloat,
            viewY: CGFloat
        ) -> CGPoint {

            let scenePoint =
                scene.convertPoint(
                    fromView:
                        CGPoint(
                            x: viewX,
                            y: viewY
                        )
                )

            return camera.convert(
                scenePoint,
                from: scene
            )
        }


        let leftCameraPoint =
            cameraPoint(
                viewX: safeLeftViewX,
                viewY: view.bounds.midY
            )

        let safeTopCameraPoint =
            cameraPoint(
                viewX: view.bounds.midX,
                viewY: safeTopViewY
            )

        let safeBottomCameraPoint =
            cameraPoint(
                viewX: view.bounds.midX,
                viewY: safeBottomViewY
            )

        let physicalTopCameraPoint =
            cameraPoint(
                viewX: view.bounds.midX,
                viewY: view.bounds.minY
            )

        let physicalBottomCameraPoint =
            cameraPoint(
                viewX: view.bounds.midX,
                viewY: view.bounds.maxY
            )


        let fixedLeftX =
            leftCameraPoint.x

        let safeMaximumY =
            max(
                safeTopCameraPoint.y,
                safeBottomCameraPoint.y
            )

        let safeMinimumY =
            min(
                safeTopCameraPoint.y,
                safeBottomCameraPoint.y
            )

        let physicalMaximumY =
            max(
                physicalTopCameraPoint.y,
                physicalBottomCameraPoint.y
            )

        let physicalMinimumY =
            min(
                physicalTopCameraPoint.y,
                physicalBottomCameraPoint.y
            )


        // -------------------------------------------------
        // Semantic Y positioning
        // -------------------------------------------------
        //
        // Normal labels NEVER clamp to the top/bottom edge.
        // They move vertically with the map and disappear
        // once their complete pill leaves the safe viewport.
        //
        // Only 12 AM and 11:59 PM receive temporary edge
        // protection, because those semantic positions sit at
        // the actual beginning/end of the map. Even those two
        // labels are hidden as soon as their semantic pill has
        // completely left the physical viewport. This prevents
        // the old sticky-label overlap behavior.

        let semanticAxisX =
            MapCoordinateConverter
                .worldX(
                    forProgress: 0
                )


        for (index, tick) in ticks.enumerated() {

            let worldPoint =
                CGPoint(
                    x: semanticAxisX,
                    y: tick.worldY
                )

            let semanticCameraPoint =
                camera.convert(
                    worldPoint,
                    from: scene
                )


            let halfHeight =
                tick.size.height * 0.5

            let minimumSafeCenterY =
                safeMinimumY
                + halfHeight

            let maximumSafeCenterY =
                safeMaximumY
                - halfHeight


            let isDayBoundaryTick =
                index == 0
                || index == ticks.count - 1


            let semanticMinimumY =
                semanticCameraPoint.y
                - halfHeight

            let semanticMaximumY =
                semanticCameraPoint.y
                + halfHeight


            if isDayBoundaryTick {

                // The boundary pill may be nudged fully inside
                // the safe area, but ONLY while its true pill
                // still intersects the physical screen.

                let intersectsPhysicalViewport =
                    semanticMaximumY >= physicalMinimumY
                    && semanticMinimumY <= physicalMaximumY

                guard intersectsPhysicalViewport else {

                    tick.node.isHidden = true
                    continue
                }


                tick.node.isHidden = false


                let visibleY: CGFloat

                if minimumSafeCenterY <= maximumSafeCenterY {

                    visibleY =
                        min(
                            maximumSafeCenterY,
                            max(
                                minimumSafeCenterY,
                                semanticCameraPoint.y
                            )
                        )

                } else {

                    visibleY =
                        (
                            safeMinimumY
                            + safeMaximumY
                        )
                        * 0.5
                }


                tick.node.position =
                    CGPoint(
                        x:
                            fixedLeftX
                            + (tick.size.width * 0.5),
                        y:
                            visibleY
                    )

                continue
            }


            // Interior labels are never sticky. Keep the full
            // pill visible or hide it entirely at the edge.

            let fullyInsideSafeViewport =
                semanticCameraPoint.y >= minimumSafeCenterY
                && semanticCameraPoint.y <= maximumSafeCenterY


            tick.node.isHidden =
                !fullyInsideSafeViewport


            guard fullyInsideSafeViewport else {
                continue
            }


            tick.node.position =
                CGPoint(
                    x:
                        fixedLeftX
                        + (tick.size.width * 0.5),
                    y:
                        semanticCameraPoint.y
                )
        }
    }
}
