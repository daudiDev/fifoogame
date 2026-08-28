//
//  GameNodeMarkerChrome.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/25/26.
//


import SpriteKit

/// Draws the map-callout portion of a game node.
///
/// The visual design intentionally matches a live-location callout:
/// a white rounded capsule with a soft shadow and a triangular pointer.
/// `CGPoint.zero` is the *tip* of that pointer, so the node's semantic
/// time/progress coordinate remains exact even though the callout grows
/// above and mostly to the right of the coordinate.
///
/// The capsule no longer has a single fixed width. Its left edge, avatar,
/// pointer, and text origin stay anchored in the same places while only the
/// right edge expands to fit the node's visible text, up to `maximumBodyWidth`.
enum GameNodeMarkerChrome {

    // =====================================================
    // MARK: - Shared Layout
    // =====================================================

    static let minimumBodyWidth: CGFloat =
        112

    static let maximumBodyWidth: CGFloat =
        206

    static let bodyHeight: CGFloat =
        58

    /// Keep the left edge fixed so the pointer and avatar do not move when
    /// the capsule becomes shorter or wider.
    static let bodyMinX: CGFloat =
        -20

    static let bodyCenterY: CGFloat =
        41

    static let avatarCenter =
        CGPoint(
            x: 10,
            y: bodyCenterY
        )

    static let bodyCornerRadius: CGFloat =
        bodyHeight / 2

    static func clampedBodyWidth(
        _ requestedWidth: CGFloat
    ) -> CGFloat {

        min(
            maximumBodyWidth,
            max(
                minimumBodyWidth,
                requestedWidth
            )
        )
    }

    static func bodyRect(
        width requestedWidth: CGFloat
    ) -> CGRect {

        let width =
            clampedBodyWidth(
                requestedWidth
            )

        return CGRect(
            x: bodyMinX,
            y: bodyCenterY - bodyHeight / 2,
            width: width,
            height: bodyHeight
        )
    }

    static func bodyCenter(
        width requestedWidth: CGFloat
    ) -> CGPoint {

        let rect =
            bodyRect(
                width: requestedWidth
            )

        return CGPoint(
            x: rect.midX,
            y: rect.midY
        )
    }

    private static let tailLeftX: CGFloat =
        -10

    private static let tailRightX: CGFloat =
        18

    /// The tail joins inside the capsule so it reads as one continuous
    /// location callout, while its sharp tip stays exactly at CGPoint.zero.
    private static var tailJoinY: CGFloat {
        bodyCenterY - bodyHeight / 2 + 10
    }

    private static let shadowOffset =
        CGPoint(
            x: 1.5,
            y: -2.5
        )


    // =====================================================
    // MARK: - Construction
    // =====================================================

    static func make(
        bodyWidth requestedBodyWidth: CGFloat,
        isSelected: Bool
    ) -> SKNode {

        let bodyRect =
            bodyRect(
                width: requestedBodyWidth
            )

        let root =
            SKNode()

        root.name =
            "locationCalloutChrome"

        // MARK: Shadow tail
        let tailShadow =
            SKShapeNode(
                path: makeTailPath(
                    offset: shadowOffset
                )
            )

        tailShadow.fillColor =
            MapVisualTheme.nodeCaptionShadowColor

        tailShadow.strokeColor =
            .clear

        tailShadow.zPosition =
            -3

        root.addChild(
            tailShadow
        )

        // MARK: Shadow capsule
        let shadowRect =
            bodyRect
                .offsetBy(
                    dx: shadowOffset.x,
                    dy: shadowOffset.y
                )

        let bodyShadow =
            SKShapeNode(
                rect: shadowRect,
                cornerRadius: bodyCornerRadius
            )

        bodyShadow.fillColor =
            MapVisualTheme.nodeCaptionShadowColor

        bodyShadow.strokeColor =
            .clear

        bodyShadow.zPosition =
            -2

        root.addChild(
            bodyShadow
        )

        // MARK: Main capsule
        let body =
            SKShapeNode(
                rect: bodyRect,
                cornerRadius: bodyCornerRadius
            )

        body.name =
            "locationCalloutBody"

        body.fillColor =
            MapVisualTheme.nodeCaptionBackgroundColor

        body.strokeColor =
            isSelected
            ? MapVisualTheme.roadSelectionColor
            : MapVisualTheme.nodeCaptionBorderColor

        body.lineWidth =
            isSelected ? 2 : 1

        body.zPosition =
            1

        root.addChild(
            body
        )

        // MARK: Pointer tail
        // Draw this after / above the capsule so its base covers the lower
        // capsule outline and reads as one continuous white shape.
        let tail =
            SKShapeNode(
                path: makeTailPath()
            )

        tail.name =
            "locationCalloutTail"

        tail.fillColor =
            MapVisualTheme.nodeCaptionBackgroundColor

        tail.strokeColor =
            .clear

        tail.zPosition =
            2

        root.addChild(
            tail
        )

        return root
    }


    // =====================================================
    // MARK: - Tail
    // =====================================================

    /// Speech-bubble/location pointer with its sharp tip exactly at (0, 0).
    private static func makeTailPath(
        offset: CGPoint = .zero
    ) -> CGPath {

        let path =
            CGMutablePath()

        path.move(
            to: CGPoint(
                x: tailLeftX + offset.x,
                y: tailJoinY + offset.y
            )
        )

        path.addLine(
            to: CGPoint(
                x: tailRightX + offset.x,
                y: tailJoinY + offset.y
            )
        )

        path.addLine(
            to: CGPoint(
                x: offset.x,
                y: offset.y
            )
        )

        path.closeSubpath()

        return path
    }
}
