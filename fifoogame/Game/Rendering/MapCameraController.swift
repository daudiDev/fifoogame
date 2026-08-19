//
//  MapCameraController.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/18/26.
//


//
//  MapCameraController.swift
//  Fifoo
//

import SpriteKit
import UIKit


@MainActor
final class MapCameraController:
    NSObject,
    UIGestureRecognizerDelegate {

    // MARK: - Camera

    let cameraNode = SKCameraNode()


    // MARK: - Zoom Configuration

    private let initialCameraScale: CGFloat = 0.42

    private let minimumCameraScale: CGFloat = 0.20

    private let configuredMaximumCameraScale: CGFloat = 0.70


    // MARK: - Center Animation

    private let centerAnimationDuration: TimeInterval = 0.40

    private let centerAnimationKey = "centerOnTime"


    // MARK: - References

    private weak var scene: SKScene?

    private weak var gestureView: SKView?


    // MARK: - Pan Gesture

    private var panGestureRecognizer:
        UIPanGestureRecognizer?

    private var panStartCameraPosition:
        CGPoint = .zero

    private(set) var isPanning =
        false


    // MARK: - Pinch Gesture

    private var pinchGestureRecognizer:
        UIPinchGestureRecognizer?

    private var pinchStartCameraScale:
        CGFloat = 0.42

    private(set) var isPinching =
        false


    // MARK: - Momentum Configuration

    /// Higher = stops faster.
    private let momentumDeceleration:
        CGFloat = 3.0

    /// Don't glide from tiny releases.
    private let minimumMomentumStartSpeed:
        CGFloat = 80

    /// Finish momentum below this speed.
    private let momentumStopSpeed:
        CGFloat = 12

    /// Prevent absurdly large flick velocity.
    private let maximumMomentumSpeed:
        CGFloat = 3500


    // MARK: - Momentum State

    private var momentumVelocity:
        CGPoint = .zero

    private var lastMomentumUpdateTime:
        TimeInterval?

    private(set) var isMomentumActive =
        false


    // MARK: - Setup State

    private var hasInitializedCamera =
        false


    // MARK: - Init

    override init() {

        super.init()

        cameraNode.name =
            "mapCamera"
    }


    // MARK: - Installation

    func install(
        in scene: SKScene,
        view: SKView,
        initialFocusTime: DayTime
    ) {

        self.scene =
            scene


        if cameraNode.parent !== scene {

            cameraNode.removeFromParent()

            scene.addChild(
                cameraNode
            )
        }


        scene.camera =
            cameraNode


        if !hasInitializedCamera {

            hasInitializedCamera =
                true


            cameraNode.setScale(
                initialCameraScale
            )


            cameraNode.position =
                worldPoint(
                    time:
                        initialFocusTime,
                    progress:
                        50
                )
        }


        attachGestures(
            to: view
        )


        constrainCameraScale(
            in: scene,
            view: view
        )


        clampCamera(
            in: scene,
            view: view
        )
    }


    // MARK: - Detach

    func detachGestures(
        from view: SKView
    ) {

        guard
            gestureView === view
        else {
            return
        }


        if let panGestureRecognizer {

            view.removeGestureRecognizer(
                panGestureRecognizer
            )
        }


        if let pinchGestureRecognizer {

            view.removeGestureRecognizer(
                pinchGestureRecognizer
            )
        }


        panGestureRecognizer =
            nil


        pinchGestureRecognizer =
            nil


        gestureView =
            nil


        isPanning =
            false


        isPinching =
            false


        cancelMomentum()
    }
}


// =====================================================
// MARK: - Gesture Installation
// =====================================================

private extension MapCameraController {

    func attachGestures(
        to view: SKView
    ) {

        if
            gestureView === view,
            panGestureRecognizer != nil,
            pinchGestureRecognizer != nil
        {
            return
        }


        // Remove old recognizers if SpriteView
        // supplied a different SKView.

        if let oldView = gestureView {

            if let panGestureRecognizer {

                oldView.removeGestureRecognizer(
                    panGestureRecognizer
                )
            }


            if let pinchGestureRecognizer {

                oldView.removeGestureRecognizer(
                    pinchGestureRecognizer
                )
            }
        }


        // MARK: Pan

        let pan =
            UIPanGestureRecognizer(
                target: self,
                action:
                    #selector(
                        handlePan(_:)
                    )
            )


        pan.minimumNumberOfTouches = 1
        pan.maximumNumberOfTouches = 1

        pan.cancelsTouchesInView = true

        pan.delegate = self


        // MARK: Pinch

        let pinch =
            UIPinchGestureRecognizer(
                target: self,
                action:
                    #selector(
                        handlePinch(_:)
                    )
            )


        pinch.cancelsTouchesInView = true

        pinch.delegate = self


        view.addGestureRecognizer(
            pan
        )


        view.addGestureRecognizer(
            pinch
        )


        gestureView =
            view


        panGestureRecognizer =
            pan


        pinchGestureRecognizer =
            pinch
    }
}


// =====================================================
// MARK: - Gesture Coordination
// =====================================================

extension MapCameraController {

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith
        otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {

        let containsPanAndPinch =
            (
                gestureRecognizer ===
                panGestureRecognizer
                &&
                otherGestureRecognizer ===
                pinchGestureRecognizer
            )
            ||
            (
                gestureRecognizer ===
                pinchGestureRecognizer
                &&
                otherGestureRecognizer ===
                panGestureRecognizer
            )


        return containsPanAndPinch
    }
}

// =====================================================
// MARK: - Pan
// =====================================================

private extension MapCameraController {

    @objc
    func handlePan(
        _ recognizer:
            UIPanGestureRecognizer
    ) {
        
        guard
            let scene,
            let view =
                gestureView
        else {
            return
        }


        switch recognizer.state {

        case .began:

            cancelMomentum()

            cancelCameraAnimation()


            isPanning =
                true


            panStartCameraPosition =
                cameraNode.position


        case .changed:

            /*
             If a pinch currently owns the camera,
             don't also change camera position from
             the one-finger pan.
             */

            guard !isPinching else {
                return
            }


            let translation =
                recognizer.translation(
                    in: view
                )


            let worldTranslation =
                worldVector(
                    forViewVector:
                        translation,
                    in:
                        scene
                )


            /*
             Translation is measured from the
             beginning of the gesture.

             Therefore every frame is derived
             from ONE stable starting position.
             */

            let proposed =
                CGPoint(
                    x:
                        panStartCameraPosition.x
                        - worldTranslation.x,

                    y:
                        panStartCameraPosition.y
                        - worldTranslation.y
                )


            cameraNode.position =
                clampedCameraPosition(
                    proposed,
                    in:
                        scene,
                    view:
                        view
                )


        case .ended:

            isPanning =
                false


            guard !isPinching else {
                return
            }


            beginMomentum(
                from:
                    recognizer,
                scene:
                    scene,
                view:
                    view
            )


        case .cancelled,
             .failed:

            isPanning =
                false


        default:

            break
        }
    }
}


// =====================================================
// MARK: - Momentum Start
// =====================================================

private extension MapCameraController {

    func beginMomentum(
        from recognizer:
            UIPanGestureRecognizer,
        scene: SKScene,
        view: SKView
    ) {

        /*
         UIKit velocity is SCREEN points/sec.
         */

        let viewVelocity =
            recognizer.velocity(
                in: view
            )


        /*
         Convert that vector into Fifoo
         scene/world units per second.
         */

        let worldFingerVelocity =
            worldVector(
                forViewVector:
                    viewVelocity,
                in:
                    scene
            )


        /*
         Camera moves opposite the finger.
         */

        var cameraVelocity =
            CGPoint(
                x:
                    -worldFingerVelocity.x,

                y:
                    -worldFingerVelocity.y
            )


        let speed =
            hypot(
                cameraVelocity.x,
                cameraVelocity.y
            )


        guard
            speed >=
                minimumMomentumStartSpeed
        else {

            cancelMomentum()

            return
        }


        // Maximum speed clamp.

        if speed >
            maximumMomentumSpeed {

            let factor =
                maximumMomentumSpeed
                / speed


            cameraVelocity.x *=
                factor


            cameraVelocity.y *=
                factor
        }


        momentumVelocity =
            cameraVelocity


        isMomentumActive =
            true


        lastMomentumUpdateTime =
            nil
    }
}

// =====================================================
// MARK: - Momentum Update
// =====================================================

extension MapCameraController {

    func updateMomentum(
        currentTime: TimeInterval
    ) {

        guard
            isMomentumActive,
            let scene,
            let view =
                gestureView
        else {

            return
        }


        guard
            let previousTime =
                lastMomentumUpdateTime
        else {

            lastMomentumUpdateTime =
                currentTime

            return
        }


        let rawDeltaTime =
            currentTime
            - previousTime


        lastMomentumUpdateTime =
            currentTime


        guard
            rawDeltaTime > 0,
            rawDeltaTime < 0.10
        else {

            cancelMomentum()

            return
        }


        let dt =
            CGFloat(
                rawDeltaTime
            )


        /*
         Frame-rate-independent exponential
         velocity decay.
         */

        let decay =
            CGFloat(
                exp(
                    -Double(
                        momentumDeceleration
                        * dt
                    )
                )
            )


        let displacementFactor =
            (
                1 - decay
            )
            / momentumDeceleration


        let proposed =
            CGPoint(
                x:
                    cameraNode.position.x
                    + momentumVelocity.x
                    * displacementFactor,

                y:
                    cameraNode.position.y
                    + momentumVelocity.y
                    * displacementFactor
            )


        let legal =
            clampedCameraPosition(
                proposed,
                in:
                    scene,
                view:
                    view
            )


        let hitXBoundary =
            abs(
                legal.x
                - proposed.x
            )
            > 0.01


        let hitYBoundary =
            abs(
                legal.y
                - proposed.y
            )
            > 0.01


        cameraNode.position =
            legal


        momentumVelocity.x *=
            decay


        momentumVelocity.y *=
            decay


        /*
         If one axis hits a boundary,
         momentum can continue on the other.
         */

        if hitXBoundary {

            momentumVelocity.x =
                0
        }


        if hitYBoundary {

            momentumVelocity.y =
                0
        }


        let remainingSpeed =
            hypot(
                momentumVelocity.x,
                momentumVelocity.y
            )


        if remainingSpeed <
            momentumStopSpeed {

            cancelMomentum()
        }
    }


    func cancelMomentum() {

        momentumVelocity =
            .zero


        lastMomentumUpdateTime =
            nil


        isMomentumActive =
            false
    }
}

// =====================================================
// MARK: - Pinch
// =====================================================

private extension MapCameraController {

    @objc
    func handlePinch(
        _ recognizer:
            UIPinchGestureRecognizer
    ) {

        guard
            let scene,
            let view =
                gestureView
        else {
            return
        }


        switch recognizer.state {

        case .began:

            cancelMomentum()

            cancelCameraAnimation()


            /*
             Pinch now owns the camera.

             Cancel any active pan state so the
             two gestures can't fight.
             */

            isPinching =
                true


            isPanning =
                false


            pinchStartCameraScale =
                cameraNode.xScale


        case .changed:

            applyPinch(
                recognizer,
                scene:
                    scene,
                view:
                    view
            )


        case .ended,
             .cancelled,
             .failed:

            isPinching =
                false


            clampCamera(
                in:
                    scene,
                view:
                    view
            )


        default:

            break
        }
    }


    func applyPinch(
        _ recognizer:
            UIPinchGestureRecognizer,
        scene: SKScene,
        view: SKView
    ) {

        guard
            recognizer.scale > 0,
            recognizer.scale.isFinite
        else {
            return
        }


        let pinchCenter =
            recognizer.location(
                in: view
            )


        let worldBefore =
            scene.convertPoint(
                fromView:
                    pinchCenter
            )


        let proposedScale =
            pinchStartCameraScale
            / recognizer.scale


        cameraNode.setScale(

            clampedCameraScale(
                proposedScale,
                in:
                    scene,
                view:
                    view
            )
        )


        let worldAfter =
            scene.convertPoint(
                fromView:
                    pinchCenter
            )


        cameraNode.position.x +=
            worldBefore.x
            - worldAfter.x


        cameraNode.position.y +=
            worldBefore.y
            - worldAfter.y


        clampCamera(
            in:
                scene,
            view:
                view
        )
    }
}

// =====================================================
// MARK: - Center On Now
// =====================================================

extension MapCameraController {

    func center(
        on time: DayTime,
        in scene: SKScene,
        view: SKView,
        animated: Bool
    ) {

        cancelMomentum()

        cancelCameraAnimation()


        let requested =
            worldPoint(
                time:
                    time,
                progress:
                    50
            )


        let legal =
            clampedCameraPosition(
                requested,
                in:
                    scene,
                view:
                    view
            )


        guard animated else {

            cameraNode.position =
                legal

            return
        }


        let action =
            SKAction.move(
                to:
                    legal,
                duration:
                    centerAnimationDuration
            )


        action.timingMode =
            .easeInEaseOut


        cameraNode.run(
            action,
            withKey:
                centerAnimationKey
        )
    }
}


// =====================================================
// MARK: - Scale
// =====================================================

private extension MapCameraController {

    func constrainCameraScale(
        in scene: SKScene,
        view: SKView
    ) {

        cameraNode.setScale(

            clampedCameraScale(
                cameraNode.xScale,
                in:
                    scene,
                view:
                    view
            )
        )
    }


    func clampedCameraScale(
        _ proposedScale: CGFloat,
        in scene: SKScene,
        view: SKView
    ) -> CGFloat {

        let maximum =
            effectiveMaximumCameraScale(
                in:
                    scene,
                view:
                    view
            )


        let minimum =
            min(
                minimumCameraScale,
                maximum
            )


        return min(
            maximum,
            max(
                minimum,
                proposedScale
            )
        )
    }


    func effectiveMaximumCameraScale(
        in scene: SKScene,
        view: SKView
    ) -> CGFloat {

        let visible =
            visibleWorldSize(
                in:
                    scene,
                view:
                    view
            )


        guard
            visible.width > 0,
            visible.height > 0
        else {

            return configuredMaximumCameraScale
        }


        let currentScale =
            max(
                cameraNode.xScale,
                0.0001
            )


        let maximumForWidth =
            currentScale
            * (
                MapWorldConfiguration
                    .explorableWorldWidth
                / visible.width
            )


        let maximumForHeight =
            currentScale
            * (
                MapWorldConfiguration.height
                / visible.height
            )


        return max(
            0.01,

            min(
                configuredMaximumCameraScale,

                min(
                    maximumForWidth,
                    maximumForHeight
                )
            )
        )
    }
}


// =====================================================
// MARK: - Camera Bounds
// =====================================================

extension MapCameraController {

    func clampCamera(
        in scene: SKScene,
        view: SKView
    ) {

        cameraNode.position =
            clampedCameraPosition(
                cameraNode.position,
                in:
                    scene,
                view:
                    view
            )
    }
}


private extension MapCameraController {

    func clampedCameraPosition(
        _ proposed: CGPoint,
        in scene: SKScene,
        view: SKView
    ) -> CGPoint {

        let visible =
            visibleWorldSize(
                in:
                    scene,
                view:
                    view
            )


        return CGPoint(

            x:
                clampedCameraX(
                    proposed.x,
                    visibleWidth:
                        visible.width
                ),

            y:
                clampedCameraY(
                    proposed.y,
                    visibleHeight:
                        visible.height
                )
        )
    }


    func clampedCameraX(
        _ proposedX: CGFloat,
        visibleWidth: CGFloat
    ) -> CGFloat {

        let minimumX =
            MapWorldConfiguration
                .minimumExplorableX


        let maximumX =
            MapWorldConfiguration
                .maximumExplorableX


        let worldWidth =
            MapWorldConfiguration
                .explorableWorldWidth


        guard visibleWidth > 0 else {

            return proposedX
        }


        guard visibleWidth < worldWidth else {

            return MapWorldConfiguration
                .explorableWorldCenterX
        }


        let half =
            visibleWidth / 2


        return min(
            maximumX - half,

            max(
                minimumX + half,
                proposedX
            )
        )
    }


    func clampedCameraY(
        _ proposedY: CGFloat,
        visibleHeight: CGFloat
    ) -> CGFloat {

        let worldHeight =
            MapWorldConfiguration.height


        guard visibleHeight > 0 else {

            return proposedY
        }


        guard visibleHeight < worldHeight else {

            return -worldHeight / 2
        }


        let half =
            visibleHeight / 2


        let highest =
            -half


        let lowest =
            -worldHeight
            + half


        return min(
            highest,

            max(
                lowest,
                proposedY
            )
        )
    }
}


// =====================================================
// MARK: - Coordinate Helpers
// =====================================================

private extension MapCameraController {

    /*
     Converts a VECTOR from view coordinates
     into a world-space vector.

     Because we're subtracting two converted
     points, camera position itself cancels out.
     */

    func worldVector(
        forViewVector vector: CGPoint,
        in scene: SKScene
    ) -> CGPoint {

        let origin =
            scene.convertPoint(
                fromView:
                    .zero
            )


        let translated =
            scene.convertPoint(
                fromView:
                    CGPoint(
                        x:
                            vector.x,
                        y:
                            vector.y
                    )
            )


        return CGPoint(
            x:
                translated.x
                - origin.x,

            y:
                translated.y
                - origin.y
        )
    }


    func visibleWorldSize(
        in scene: SKScene,
        view: SKView
    ) -> CGSize {

        let left =
            scene.convertPoint(
                fromView:
                    CGPoint(
                        x:
                            view.bounds.minX,
                        y:
                            view.bounds.midY
                    )
            )


        let right =
            scene.convertPoint(
                fromView:
                    CGPoint(
                        x:
                            view.bounds.maxX,
                        y:
                            view.bounds.midY
                    )
            )


        let top =
            scene.convertPoint(
                fromView:
                    CGPoint(
                        x:
                            view.bounds.midX,
                        y:
                            view.bounds.minY
                    )
            )


        let bottom =
            scene.convertPoint(
                fromView:
                    CGPoint(
                        x:
                            view.bounds.midX,
                        y:
                            view.bounds.maxY
                    )
            )


        return CGSize(

            width:
                abs(
                    right.x
                    - left.x
                ),

            height:
                abs(
                    bottom.y
                    - top.y
                )
        )
    }


    func worldPoint(
        time: DayTime,
        progress: Double
    ) -> CGPoint {

        MapCoordinateConverter
            .worldPoint(
                for:
                    MapCoordinate(
                        time:
                            time,

                        progress:
                            MapProgress(
                                progress
                            )
                    )
            )
            .cgPoint
    }


    func cancelCameraAnimation() {

        cameraNode.removeAction(
            forKey:
                centerAnimationKey
        )
    }
}
