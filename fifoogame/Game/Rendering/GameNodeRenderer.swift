//
//  GameNodeRenderer.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/24/26.
//



import SpriteKit
import UIKit


@MainActor
final class GameNodeRenderer {

    private enum GameNodeVisualMetrics {

        static let markerRadius: CGFloat =
            28

        static let markerImageRadius: CGFloat =
            25

        static let markerBorderWidth: CGFloat =
            2

        static let selectionRadius: CGFloat =
            35

        static let selectionBorderWidth: CGFloat =
            3

        static let titleFontSize: CGFloat =
            15

        static let timeFontSize: CGFloat =
            12

        // The title and time now live inside one compact map-style
        // caption plate. Keeping the plate just below the marker makes
        // the node readable over roads, route strokes, and land islands.
        static let captionTopYOffset: CGFloat =
            -34

        static let captionHorizontalPadding: CGFloat =
            10

        static let captionVerticalPadding: CGFloat =
            6

        static let captionLineSpacing: CGFloat =
            3

        static let captionMinimumWidth: CGFloat =
            68

        // Hard visual width for a map-node title. Titles wider than this
        // are shortened with an ellipsis before they reach SKLabelNode,
        // so the text can never draw outside the caption plate.
        static let captionMaximumTextWidth: CGFloat =
            120

        static let captionCornerRadius: CGFloat =
            9

        static let captionBorderWidth: CGFloat =
            1

        static let captionShadowOffset =
            CGPoint(
                x: 1.5,
                y: -2
            )
    }


    // =====================================================
    // MARK: - Root
    // =====================================================

    let containerNode =
        SKNode()


    // =====================================================
    // MARK: - Rendered Nodes
    // =====================================================

    private var renderedNodes:
        [GameNodeID: SKNode] = [:]


    // =====================================================
    // MARK: - Image Loading
    // =====================================================

    private var textureCache:
        [String: SKTexture] = [:]

    private var remoteImageTasks:
        [GameNodeID: Task<Void, Never>] = [:]


    // =====================================================
    // MARK: - Init
    // =====================================================

    init() {

        containerNode.name =
            "gameNodeRenderer"

        containerNode.isHidden =
            false

        containerNode.alpha =
            1

        // Scene-level nodeLayer owns the global z-order.
        containerNode.zPosition =
            0
    }


    // =====================================================
    // MARK: - Render
    // =====================================================

    func render(
        nodes: [GameMapNode],
        roadGraph: RoadGraph
    ) {

        clear()

        for gameNode in nodes {

            guard
                gameNode.isEnabled,
                let worldPoint =
                    GameNodePlacementResolver
                        .worldPoint(
                            for: gameNode,
                            graph: roadGraph
                        )
            else {
                continue
            }

            let root =
                makeNode(
                    for: gameNode
                )

            root.position =
                worldPoint.cgPoint

            containerNode.addChild(
                root
            )

            renderedNodes[
                gameNode.id
            ] =
                root
        }
    }


    // =====================================================
    // MARK: - Selection
    // =====================================================

    func renderSelection(
        selectedNodeID: GameNodeID?
    ) {

        for (
            nodeID,
            root
        ) in renderedNodes {

            root.childNode(
                withName: "selectionHalo"
            )?
            .isHidden =
                nodeID != selectedNodeID
        }
    }


    // =====================================================
    // MARK: - Clear
    // =====================================================

    func clear() {

        cancelRemoteImageTasks()

        containerNode
            .removeAllChildren()

        renderedNodes
            .removeAll()
    }


    // =====================================================
    // MARK: - Texture Cache
    // =====================================================

    func purgeTextureCache() {

        textureCache
            .removeAll()
    }
}


// =====================================================
// MARK: - Node Construction
// =====================================================

private extension GameNodeRenderer {

    func makeNode(
        for gameNode: GameMapNode
    ) -> SKNode {

        let root =
            SKNode()

        root.name =
            "game.node.\(gameNode.id.rawValue.uuidString)"

        root.zPosition =
            0

        root.userData =
            NSMutableDictionary(
                dictionary: [
                    "gameNodeID":
                        gameNode.id.rawValue.uuidString,
                    "gameNodeKind":
                        gameNode.content.kind.rawValue,
                    "gameNodeTime":
                        gameNode.time.secondsFromMidnight
                ]
            )


        // =============================================
        // Map-style chrome
        // =============================================

        let chrome =
            GameNodeMarkerChrome.make(
                isSelected: false
            )

        chrome.name =
            "markerChrome"

        chrome.zPosition =
            -2

        root.addChild(
            chrome
        )


        // =============================================
        // Selection halo
        // =============================================

        root.addChild(
            makeSelectionHalo()
        )


        // =============================================
        // Circular image marker
        // =============================================

        let imageSprite =
            makeCircularImageNode(
                for: gameNode.content.kind
            )

        root.addChild(
            imageSprite.cropNode
        )

        root.addChild(
            makeMarkerBorder()
        )

        configureImage(
            for: gameNode,
            sprite: imageSprite.sprite
        )


        // =============================================
        // Title + time caption
        // =============================================

        root.addChild(
            makeCaptionNode(
                title: gameNode.content.title,
                time: gameNode.time.displayClockString
            )
        )


        return root
    }
}


// =====================================================
// MARK: - Marker Components
// =====================================================

private extension GameNodeRenderer {

    func makeSelectionHalo() -> SKShapeNode {

        let halo =
            SKShapeNode(
                circleOfRadius:
                    GameNodeVisualMetrics.selectionRadius
            )

        halo.name =
            "selectionHalo"

        halo.fillColor =
            MapVisualTheme.roadSelectionHaloColor

        halo.strokeColor =
            MapVisualTheme.roadSelectionColor

        halo.lineWidth =
            GameNodeVisualMetrics.selectionBorderWidth

        halo.isHidden =
            true

        halo.zPosition =
            1

        return halo
    }


    func makeMarkerBorder() -> SKShapeNode {

        let border =
            SKShapeNode(
                circleOfRadius:
                    GameNodeVisualMetrics.markerRadius
            )

        border.name =
            "markerBorder"

        border.fillColor =
            .clear

        border.strokeColor =
            MapVisualTheme.nodeBorderColor

        border.lineWidth =
            GameNodeVisualMetrics.markerBorderWidth

        border.zPosition =
            4

        return border
    }


    func makeCircularImageNode(
        for kind: GameNodeKind
    ) -> (
        cropNode: SKCropNode,
        sprite: SKSpriteNode
    ) {

        let cropNode =
            SKCropNode()

        cropNode.name =
            "markerImageCrop"

        cropNode.zPosition =
            3

        let mask =
            SKShapeNode(
                circleOfRadius:
                    GameNodeVisualMetrics.markerImageRadius
            )

        mask.fillColor =
            .white

        mask.strokeColor =
            .clear

        cropNode.maskNode =
            mask

        let placeholder =
            placeholderTexture(
                for: kind
            )

        let sprite =
            SKSpriteNode(
                texture: placeholder
            )

        sprite.name =
            "markerImageSprite"

        sprite.anchorPoint =
            CGPoint(
                x: 0.5,
                y: 0.5
            )

        apply(
            texture: placeholder,
            to: sprite
        )

        cropNode.addChild(
            sprite
        )

        return (
            cropNode,
            sprite
        )
    }


    func makeCaptionNode(
        title: String,
        time: String
    ) -> SKNode {

        let root =
            SKNode()

        root.name =
            "nodeCaption"

        root.position =
            CGPoint(
                x: 0,
                y: GameNodeVisualMetrics.captionTopYOffset
            )

        root.zPosition =
            5


        // =============================================
        // Title
        // =============================================

        let titleLabel =
            SKLabelNode(
                fontNamed:
                    "HelveticaNeue-Medium"
            )

        titleLabel.name =
            "nodeTitle"

        titleLabel.fontSize =
            GameNodeVisualMetrics.titleFontSize

        titleLabel.text =
            fittedCaptionTitle(
                title
            )

        titleLabel.fontColor =
            MapVisualTheme.nodeCaptionTitleColor

        titleLabel.horizontalAlignmentMode =
            .center

        titleLabel.verticalAlignmentMode =
            .center

        titleLabel.numberOfLines =
            1

        titleLabel.lineBreakMode =
            .byTruncatingTail

        titleLabel.preferredMaxLayoutWidth =
            GameNodeVisualMetrics.captionMaximumTextWidth


        // =============================================
        // Time
        // =============================================

        let timeLabel =
            SKLabelNode(
                fontNamed:
                    "HelveticaNeue-Medium"
            )

        timeLabel.name =
            "nodeTime"

        timeLabel.text =
            time

        timeLabel.fontSize =
            GameNodeVisualMetrics.timeFontSize

        timeLabel.fontColor =
            MapVisualTheme.nodeCaptionTimeColor

        timeLabel.horizontalAlignmentMode =
            .center

        timeLabel.verticalAlignmentMode =
            .center


        // =============================================
        // Plate sizing
        // =============================================

        let titleHeight =
            max(
                titleLabel.frame.height,
                GameNodeVisualMetrics.titleFontSize
            )

        let timeHeight =
            max(
                timeLabel.frame.height,
                GameNodeVisualMetrics.timeFontSize
            )

        let contentWidth =
            min(
                max(
                    titleLabel.frame.width,
                    timeLabel.frame.width
                ),
                GameNodeVisualMetrics.captionMaximumTextWidth
            )

        let plateWidth =
            max(
                GameNodeVisualMetrics.captionMinimumWidth,
                contentWidth
                + (
                    GameNodeVisualMetrics.captionHorizontalPadding
                    * 2
                )
            )

        let plateHeight =
            GameNodeVisualMetrics.captionVerticalPadding
            + titleHeight
            + GameNodeVisualMetrics.captionLineSpacing
            + timeHeight
            + GameNodeVisualMetrics.captionVerticalPadding

        let plateRect =
            CGRect(
                x: -plateWidth / 2,
                y: -plateHeight,
                width: plateWidth,
                height: plateHeight
            )


        // =============================================
        // Shadow
        // =============================================

        let shadowRect =
            plateRect
                .offsetBy(
                    dx: GameNodeVisualMetrics.captionShadowOffset.x,
                    dy: GameNodeVisualMetrics.captionShadowOffset.y
                )

        let shadow =
            SKShapeNode(
                rect: shadowRect,
                cornerRadius:
                    GameNodeVisualMetrics.captionCornerRadius
            )

        shadow.name =
            "nodeCaptionShadow"

        shadow.fillColor =
            MapVisualTheme.nodeCaptionShadowColor

        shadow.strokeColor =
            .clear

        shadow.zPosition =
            -2

        root.addChild(
            shadow
        )


        // =============================================
        // Rounded background plate
        // =============================================

        let background =
            SKShapeNode(
                rect: plateRect,
                cornerRadius:
                    GameNodeVisualMetrics.captionCornerRadius
            )

        background.name =
            "nodeCaptionBackground"

        background.fillColor =
            MapVisualTheme.nodeCaptionBackgroundColor

        background.strokeColor =
            MapVisualTheme.nodeCaptionBorderColor

        background.lineWidth =
            GameNodeVisualMetrics.captionBorderWidth

        background.zPosition =
            -1

        root.addChild(
            background
        )


        // =============================================
        // Label positions
        // =============================================

        let titleCenterY =
            -GameNodeVisualMetrics.captionVerticalPadding
            - (titleHeight / 2)

        titleLabel.position =
            CGPoint(
                x: 0,
                y: titleCenterY
            )

        let timeCenterY =
            titleCenterY
            - (titleHeight / 2)
            - GameNodeVisualMetrics.captionLineSpacing
            - (timeHeight / 2)

        timeLabel.position =
            CGPoint(
                x: 0,
                y: timeCenterY
            )

        titleLabel.zPosition =
            1

        timeLabel.zPosition =
            1

        root.addChild(
            titleLabel
        )

        root.addChild(
            timeLabel
        )

        return root
    }

}


// =====================================================
// MARK: - Caption Text Fitting
// =====================================================

private extension GameNodeRenderer {

    /// SpriteKit's `preferredMaxLayoutWidth` is not a reliable hard width
    /// constraint for a single-line `SKLabelNode`. Measure the title using
    /// the same UIKit font and shorten it before rendering instead.
    ///
    /// This keeps every GameNodeContent title inside the caption plate, even
    /// for unusually long activity, user, post, media, or hyperlink titles.
    func fittedCaptionTitle(
        _ rawTitle: String
    ) -> String {

        let cleaned =
            rawTitle
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

        let title =
            cleaned.isEmpty
            ? "Untitled"
            : cleaned

        let font =
            UIFont(
                name: "HelveticaNeue-Medium",
                size: GameNodeVisualMetrics.titleFontSize
            )
            ??
            UIFont.systemFont(
                ofSize: GameNodeVisualMetrics.titleFontSize,
                weight: .medium
            )

        let maximumWidth =
            GameNodeVisualMetrics.captionMaximumTextWidth

        guard textWidth(
            title,
            font: font
        ) > maximumWidth else {

            return title
        }

        let ellipsis =
            "…"

        let characters =
            Array(
                title
            )

        var lowerBound =
            0

        var upperBound =
            characters.count

        // Find the greatest prefix that still fits once the ellipsis is
        // appended. Binary search avoids repeatedly walking a long title.
        while lowerBound < upperBound {

            let candidateCount =
                (
                    lowerBound
                    + upperBound
                    + 1
                )
                / 2

            let prefix =
                String(
                    characters.prefix(
                        candidateCount
                    )
                )
                .trimmingCharacters(
                    in: .whitespaces
                )

            let candidate =
                prefix
                + ellipsis

            if textWidth(
                candidate,
                font: font
            ) <= maximumWidth {

                lowerBound =
                    candidateCount

            } else {

                upperBound =
                    candidateCount
                    - 1
            }
        }

        let prefix =
            String(
                characters.prefix(
                    lowerBound
                )
            )
            .trimmingCharacters(
                in: .whitespaces
            )

        return prefix.isEmpty
            ? ellipsis
            : prefix + ellipsis
    }


    func textWidth(
        _ text: String,
        font: UIFont
    ) -> CGFloat {

        ceil(
            (
                text as NSString
            )
            .size(
                withAttributes: [
                    .font: font
                ]
            )
            .width
        )
    }
}


// =====================================================
// MARK: - Image Configuration
// =====================================================

private extension GameNodeRenderer {

    func configureImage(
        for gameNode: GameMapNode,
        sprite: SKSpriteNode
    ) {

        // The marker already contains a type-specific raster placeholder.
        // Missing images, invalid images, failed network requests, and old
        // SF-symbol data all intentionally keep that placeholder.

        guard let image =
            gameNode.content.image
        else {
            return
        }

        switch image {

        case let .asset(
            name
        ):

            guard let texture =
                localAssetTexture(
                    named: name
                )
            else {
                return
            }

            apply(
                texture: texture,
                to: sprite
            )


        case let .remote(
            urlString
        ):

            loadRemoteImage(
                urlString: urlString,
                nodeID: gameNode.id,
                sprite: sprite
            )


        case .systemSymbol:

            // Legacy compatibility only. Map nodes no longer render
            // SF Symbols. The type-specific placeholder remains visible.
            return
        }
    }
}


// =====================================================
// MARK: - Placeholder Texture
// =====================================================

private extension GameNodeRenderer {

    func placeholderTexture(
        for kind: GameNodeKind
    ) -> SKTexture {

        let key =
            "placeholder:\(kind.rawValue)"

        if let cached =
            textureCache[key] {

            return cached
        }

        let image =
            GameNodePlaceholderImage.image(
                for: kind
            )

        let texture =
            SKTexture(
                image: image
            )

        texture.filteringMode =
            .linear

        textureCache[key] =
            texture

        return texture
    }
}


// =====================================================
// MARK: - Local Asset
// =====================================================

private extension GameNodeRenderer {

    func localAssetTexture(
        named name: String
    ) -> SKTexture? {

        let trimmed =
            name.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !trimmed.isEmpty else {
            return nil
        }

        let key =
            "asset:\(trimmed)"

        if let cached =
            textureCache[key] {

            return cached
        }

        guard let image =
            UIImage(
                named: trimmed
            )
        else {
            return nil
        }

        let texture =
            SKTexture(
                image: image
            )

        texture.filteringMode =
            .linear

        textureCache[key] =
            texture

        return texture
    }
}


// =====================================================
// MARK: - Remote Image Loading
// =====================================================

private extension GameNodeRenderer {

    func loadRemoteImage(
        urlString: String,
        nodeID: GameNodeID,
        sprite: SKSpriteNode
    ) {

        let trimmed =
            urlString.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        let cacheKey =
            "remote:\(trimmed)"

        if let cached =
            textureCache[cacheKey] {

            apply(
                texture: cached,
                to: sprite
            )

            return
        }

        guard
            let url = URL(
                string: trimmed
            ),
            let scheme = url.scheme?.lowercased(),
            scheme == "http" || scheme == "https"
        else {
            return
        }

        remoteImageTasks[nodeID]?
            .cancel()

        let task =
            Task { @MainActor [weak self, weak sprite] in

                guard let self else {
                    return
                }

                defer {
                    self.remoteImageTasks[nodeID] = nil
                }

                do {

                    let (
                        data,
                        response
                    ) =
                        try await URLSession.shared.data(
                            from: url
                        )

                    guard !Task.isCancelled else {
                        return
                    }

                    if let httpResponse =
                        response as? HTTPURLResponse {

                        guard
                            (200...299).contains(
                                httpResponse.statusCode
                            )
                        else {
                            return
                        }
                    }

                    guard let image =
                        UIImage(
                            data: data
                        )
                    else {
                        return
                    }

                    let texture =
                        SKTexture(
                            image: image
                        )

                    texture.filteringMode =
                        .linear

                    self.textureCache[cacheKey] =
                        texture

                    guard
                        !Task.isCancelled,
                        let sprite
                    else {
                        return
                    }

                    self.apply(
                        texture: texture,
                        to: sprite
                    )

                } catch {
                    // Keep the type-specific placeholder image.
                }
            }

        remoteImageTasks[nodeID] =
            task
    }


    func cancelRemoteImageTasks() {

        for task in remoteImageTasks.values {
            task.cancel()
        }

        remoteImageTasks
            .removeAll()
    }
}


// =====================================================
// MARK: - Texture Application
// =====================================================

private extension GameNodeRenderer {

    func apply(
        texture: SKTexture,
        to sprite: SKSpriteNode
    ) {

        sprite.texture =
            texture

        let sourceSize =
            texture.size()

        let diameter =
            GameNodeVisualMetrics.markerImageRadius
            * 2

        guard
            sourceSize.width > 0,
            sourceSize.height > 0
        else {

            sprite.size =
                CGSize(
                    width: diameter,
                    height: diameter
                )

            return
        }

        // Aspect-fill the circular crop without distorting the source image.
        let scale =
            max(
                diameter / sourceSize.width,
                diameter / sourceSize.height
            )

        sprite.size =
            CGSize(
                width: sourceSize.width * scale,
                height: sourceSize.height * scale
            )
    }
}
