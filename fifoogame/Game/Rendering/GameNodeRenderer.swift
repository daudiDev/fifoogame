//
//  GameNodeRenderer.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/25/26.
//




import SpriteKit
import UIKit


@MainActor
final class GameNodeRenderer {

    private enum GameNodeVisualMetrics {

        // The GameMapNode world position is the literal tip of the callout
        // pointer. The white capsule floats above that exact coordinate.

        // The avatar now fills the full footprint previously occupied by
        // the image + decorative ring. With the ring removed, the image can
        // be larger without changing the overall callout proportions.
        static let markerImageSize =
            CGSize(
                width: 50,
                height: 50
            )

        static let markerImageCenter =
            GameNodeMarkerChrome.avatarCenter

        static let titleFontSize: CGFloat =
            13

        static let timeFontSize: CGFloat =
            11

        // Post nodes use three compact lines: poster, subject, created-at time.
        static let postPosterFontSize: CGFloat =
            11.5

        static let postSubjectFontSize: CGFloat =
            10.5

        static let postCreatedAtFontSize: CGFloat =
            9.5

        static let captionTextX: CGFloat =
            44

        static let titleCenterY: CGFloat =
            GameNodeMarkerChrome.bodyCenterY + 8

        static let timeCenterY: CGFloat =
            GameNodeMarkerChrome.bodyCenterY - 9

        static let postPosterCenterY: CGFloat =
            GameNodeMarkerChrome.bodyCenterY + 16

        static let postSubjectCenterY: CGFloat =
            GameNodeMarkerChrome.bodyCenterY

        static let postCreatedAtCenterY: CGFloat =
            GameNodeMarkerChrome.bodyCenterY - 16

        // Hard visual width for the title text before an ellipsis is added.
        static let captionMaximumTextWidth: CGFloat =
            126

        static let captionRightPadding: CGFloat =
            16
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

        let resolvedNodes =
            nodes
                .compactMap { gameNode -> (GameMapNode, CGPoint)? in

                    guard
                        gameNode.isEnabled,
                        let worldPoint =
                            GameNodePlacementResolver
                                .worldPoint(
                                    for: gameNode,
                                    graph: roadGraph
                                )
                    else {
                        return nil
                    }

                    return (
                        gameNode,
                        worldPoint.cgPoint
                    )
                }
                .sorted { lhs, rhs in

                    // The visual stacking rule is intentionally horizontal:
                    // when callouts overlap, the node farther to the right
                    // must appear above the node farther to the left.
                    if lhs.1.x != rhs.1.x {
                        return lhs.1.x < rhs.1.x
                    }

                    if lhs.1.y != rhs.1.y {
                        return lhs.1.y < rhs.1.y
                    }

                    return lhs.0.id.rawValue.uuidString
                        < rhs.0.id.rawValue.uuidString
                }

        for (stackIndex, resolved) in
            resolvedNodes.enumerated()
        {
            let gameNode =
                resolved.0

            let worldPoint =
                resolved.1

            let root =
                makeNode(
                    for: gameNode
                )

            root.position =
                worldPoint

            // Leave enough separation that every child belonging to a
            // rightward node (shadow, capsule, image, labels, selection) is
            // above every child belonging to a leftward node.
            root.zPosition =
                CGFloat(stackIndex) * 100

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

        // The old rounded-rectangle halo did not follow the location
        // callout tail and therefore looked visually detached from the
        // marker. Selection remains behavioral only for now; the map
        // callout itself is left unchanged when selected.
        _ = selectedNodeID
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

        let bodyWidth =
            calloutBodyWidth(
                for: gameNode
            )

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
                bodyWidth: bodyWidth,
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
        // Circular avatar inside the shared callout
        // =============================================

        let imageSprite =
            makeMarkerImageNode(
                for: gameNode.content.kind
            )

        root.addChild(
            imageSprite.cropNode
        )

        configureImage(
            for: gameNode,
            sprite: imageSprite.sprite
        )


        // =============================================
        // Title + time inside the shared callout
        // =============================================

        root.addChild(
            makeCaptionNode(
                for: gameNode
            )
        )


        return root
    }
}


// =====================================================
// MARK: - Marker Components
// =====================================================

private extension GameNodeRenderer {

    // The avatar intentionally has no separate backing/border in the
    // live-location callout design. The circular crop itself defines the
    // image edge against the white capsule.


    func makeMarkerImageNode(
        for kind: GameNodeKind
    ) -> (
        cropNode: SKCropNode,
        sprite: SKSpriteNode
    ) {

        let cropNode =
            SKCropNode()

        cropNode.name =
            "markerImageCrop"

        cropNode.position =
            GameNodeVisualMetrics.markerImageCenter

        cropNode.zPosition =
            6

        let mask =
            SKShapeNode(
                circleOfRadius:
                    GameNodeVisualMetrics.markerImageSize.width / 2
            )

        mask.fillColor = .white.withAlphaComponent(1.0)

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


    /// Returns the width of the white capsule for this node. The left edge,
    /// pointer, avatar, and text origin stay fixed; only the right edge grows
    /// with the widest rendered text line, capped at the established maximum.
    func calloutBodyWidth(
        for gameNode: GameMapNode
    ) -> CGFloat {

        let widestTextWidth: CGFloat

        if case let .post(content) = gameNode.content,
           let snapshot = content.snapshot
        {
            let posterWidth =
                captionLineWidth(
                    snapshot.posterName,
                    fontName: "HelveticaNeue-Bold",
                    fontSize: GameNodeVisualMetrics.postPosterFontSize,
                    fallback: "Unknown User"
                )

            let subjectWidth =
                captionLineWidth(
                    snapshot.subject,
                    fontName: "HelveticaNeue-Medium",
                    fontSize: GameNodeVisualMetrics.postSubjectFontSize,
                    fallback: snapshot.preferredTitle
                )

            let createdAtWidth =
                captionLineWidth(
                    displayPostCreatedAt(
                        snapshot.createdAt
                    ),
                    fontName: "HelveticaNeue",
                    fontSize: GameNodeVisualMetrics.postCreatedAtFontSize,
                    fallback: "Time unavailable"
                )

            widestTextWidth =
                max(
                    posterWidth,
                    max(
                        subjectWidth,
                        createdAtWidth
                    )
                )

        } else {
            let titleWidth =
                captionLineWidth(
                    gameNode.content.title,
                    fontName: "HelveticaNeue-Medium",
                    fontSize: GameNodeVisualMetrics.titleFontSize,
                    fallback: "Untitled"
                )

            let timeWidth =
                captionLineWidth(
                    gameNode.time.displayClockString,
                    fontName: "HelveticaNeue",
                    fontSize: GameNodeVisualMetrics.timeFontSize,
                    fallback: ""
                )

            widestTextWidth =
                max(
                    titleWidth,
                    timeWidth
                )
        }

        let requestedRightEdge =
            GameNodeVisualMetrics.captionTextX
            + widestTextWidth
            + GameNodeVisualMetrics.captionRightPadding

        let requestedWidth =
            requestedRightEdge
            - GameNodeMarkerChrome.bodyMinX

        return GameNodeMarkerChrome.clampedBodyWidth(
            requestedWidth
        )
    }


    func captionLineWidth(
        _ rawText: String,
        fontName: String,
        fontSize: CGFloat,
        fallback: String
    ) -> CGFloat {

        let fittedText =
            fittedCaptionText(
                rawText,
                fontName: fontName,
                fontSize: fontSize,
                fallback: fallback
            )

        let font =
            UIFont(
                name: fontName,
                size: fontSize
            )
            ??
            UIFont.systemFont(
                ofSize: fontSize
            )

        return min(
            GameNodeVisualMetrics.captionMaximumTextWidth,
            textWidth(
                fittedText,
                font: font
            )
        )
    }


    /// Builds the text inside the shared white callout. Most node kinds use
    /// the familiar two-line title + map-time presentation. Post nodes are
    /// intentionally social-first and use the post snapshot instead:
    /// poster name, subject, then the post's created-at time.
    func makeCaptionNode(
        for gameNode: GameMapNode
    ) -> SKNode {

        if case let .post(content) = gameNode.content,
           let snapshot = content.snapshot
        {
            return makePostCaptionNode(
                snapshot: snapshot
            )
        }

        return makeStandardCaptionNode(
            title: gameNode.content.title,
            time: gameNode.time.displayClockString
        )
    }


    func makeStandardCaptionNode(
        title: String,
        time: String
    ) -> SKNode {

        let root =
            SKNode()

        root.name =
            "nodeCaption"

        root.zPosition =
            8

        root.addChild(
            makeCaptionLabel(
                name: "nodeTitle",
                text: fittedCaptionText(
                    title,
                    fontName: "HelveticaNeue-Medium",
                    fontSize: GameNodeVisualMetrics.titleFontSize,
                    fallback: "Untitled"
                ),
                fontName: "HelveticaNeue-Medium",
                fontSize: GameNodeVisualMetrics.titleFontSize,
                color: MapVisualTheme.nodeCaptionTitleColor,
                y: GameNodeVisualMetrics.titleCenterY
            )
        )

        root.addChild(
            makeCaptionLabel(
                name: "nodeTime",
                text: time,
                fontName: "HelveticaNeue",
                fontSize: GameNodeVisualMetrics.timeFontSize,
                color: MapVisualTheme.nodeCaptionTimeColor,
                y: GameNodeVisualMetrics.timeCenterY
            )
        )

        return root
    }


    func makePostCaptionNode(
        snapshot: PostNodeSnapshot
    ) -> SKNode {

        let root =
            SKNode()

        root.name =
            "nodeCaption.post"

        root.zPosition =
            8

        let posterName =
            fittedCaptionText(
                snapshot.posterName,
                fontName: "HelveticaNeue-Bold",
                fontSize: GameNodeVisualMetrics.postPosterFontSize,
                fallback: "Unknown User"
            )

        let subject =
            fittedCaptionText(
                snapshot.subject,
                fontName: "HelveticaNeue-Medium",
                fontSize: GameNodeVisualMetrics.postSubjectFontSize,
                fallback: snapshot.preferredTitle
            )

        let createdAt =
            fittedCaptionText(
                displayPostCreatedAt(
                    snapshot.createdAt
                ),
                fontName: "HelveticaNeue",
                fontSize: GameNodeVisualMetrics.postCreatedAtFontSize,
                fallback: "Time unavailable"
            )

        root.addChild(
            makeCaptionLabel(
                name: "postPosterName",
                text: posterName,
                fontName: "HelveticaNeue-Bold",
                fontSize: GameNodeVisualMetrics.postPosterFontSize,
                color: MapVisualTheme.nodeCaptionTitleColor,
                y: GameNodeVisualMetrics.postPosterCenterY
            )
        )

        root.addChild(
            makeCaptionLabel(
                name: "postSubject",
                text: subject,
                fontName: "HelveticaNeue-Medium",
                fontSize: GameNodeVisualMetrics.postSubjectFontSize,
                color: MapVisualTheme.nodeCaptionTitleColor,
                y: GameNodeVisualMetrics.postSubjectCenterY
            )
        )

        root.addChild(
            makeCaptionLabel(
                name: "postCreatedAt",
                text: createdAt,
                fontName: "HelveticaNeue",
                fontSize: GameNodeVisualMetrics.postCreatedAtFontSize,
                color: MapVisualTheme.nodeCaptionTimeColor,
                y: GameNodeVisualMetrics.postCreatedAtCenterY
            )
        )

        return root
    }


    func makeCaptionLabel(
        name: String,
        text: String,
        fontName: String,
        fontSize: CGFloat,
        color: UIColor,
        y: CGFloat
    ) -> SKLabelNode {

        let label =
            SKLabelNode(
                fontNamed: fontName
            )

        label.name =
            name

        label.text =
            text

        label.fontSize =
            fontSize

        label.fontColor =
            color

        label.horizontalAlignmentMode =
            .left

        label.verticalAlignmentMode =
            .center

        label.numberOfLines =
            1

        label.lineBreakMode =
            .byTruncatingTail

        label.preferredMaxLayoutWidth =
            GameNodeVisualMetrics.captionMaximumTextWidth

        label.position =
            CGPoint(
                x: GameNodeVisualMetrics.captionTextX,
                y: y
            )

        return label
    }


    func displayPostCreatedAt(
        _ rawValue: String
    ) -> String {

        let cleaned =
            rawValue.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !cleaned.isEmpty else {
            return "Time unavailable"
        }

        let isoFormatter =
            ISO8601DateFormatter()

        var parsedDate =
            isoFormatter.date(
                from: cleaned
            )

        if parsedDate == nil {
            isoFormatter.formatOptions = [
                .withInternetDateTime,
                .withFractionalSeconds
            ]

            parsedDate =
                isoFormatter.date(
                    from: cleaned
                )
        }

        guard let date = parsedDate else {
            return "Time unavailable"
        }

        let formatter =
            DateFormatter()

        // Post callouts show only the created-at clock time so the
        // third line matches the time-only format used by other node kinds.
        formatter.dateStyle =
            .none

        formatter.timeStyle =
            .short

        return formatter.string(
            from: date
        )
    }
}


// =====================================================
// MARK: - Caption Text Fitting
// =====================================================

private extension GameNodeRenderer {

    /// SpriteKit's `preferredMaxLayoutWidth` is not a reliable hard width
    /// constraint for a single-line `SKLabelNode`. Measure using the same
    /// UIKit font and shorten before rendering. This is shared by standard
    /// node titles and all three Post callout lines.
    func fittedCaptionText(
        _ rawText: String,
        fontName: String,
        fontSize: CGFloat,
        fallback: String
    ) -> String {

        let cleaned =
            rawText.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        let fallbackCleaned =
            fallback.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        let text =
            cleaned.isEmpty
            ? (fallbackCleaned.isEmpty ? "Untitled" : fallbackCleaned)
            : cleaned

        let font =
            UIFont(
                name: fontName,
                size: fontSize
            )
            ??
            UIFont.systemFont(
                ofSize: fontSize
            )

        let maximumWidth =
            GameNodeVisualMetrics.captionMaximumTextWidth

        guard textWidth(
            text,
            font: font
        ) > maximumWidth else {
            return text
        }

        let ellipsis =
            "…"

        let characters =
            Array(text)

        var lowerBound =
            0

        var upperBound =
            characters.count

        while lowerBound < upperBound {

            let candidateCount =
                (lowerBound + upperBound + 1) / 2

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
                prefix + ellipsis

            if textWidth(
                candidate,
                font: font
            ) <= maximumWidth {
                lowerBound =
                    candidateCount
            } else {
                upperBound =
                    candidateCount - 1
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

        // Post markers are intentionally person-first: when a real Post
        // snapshot exists, the circular image always represents the poster
        // rather than the post's attached media. If the poster has no usable
        // image URL, retain the Post placeholder instead of substituting post
        // media. Legacy Post nodes without a snapshot still fall back to the
        // generic content.image behavior below.
        if case let .post(content) = gameNode.content,
           let snapshot = content.snapshot
        {
            let posterImageURL =
                snapshot.posterImageURL.trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

            guard
                !posterImageURL.isEmpty,
                posterImageURL.lowercased() != "none"
            else {
                return
            }

            loadRemoteImage(
                urlString: posterImageURL,
                nodeID: gameNode.id,
                sprite: sprite
            )

            return
        }

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

        let targetSize =
            GameNodeVisualMetrics.markerImageSize

        guard
            sourceSize.width > 0,
            sourceSize.height > 0
        else {

            sprite.size =
                CGSize(
                    width: targetSize.width,
                    height: targetSize.height
                )

            return
        }

        // Aspect-fill the circular crop without distorting the source image.
        let scale =
            max(
                targetSize.width / sourceSize.width,
                targetSize.height / sourceSize.height
            )

        sprite.size =
            CGSize(
                width: sourceSize.width * scale,
                height: sourceSize.height * scale
            )
    }
}
