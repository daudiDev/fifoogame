//
//  GameNodeRenderer.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/22/26.
//


import SpriteKit
import UIKit


@MainActor
final class GameNodeRenderer {
    
    private enum GameNodeVisualMetrics {

        static let markerRadius: CGFloat =
            28

        static let markerBorderWidth: CGFloat =
            2

        static let selectionRadius: CGFloat =
            35

        static let selectionBorderWidth: CGFloat =
            3

        static let titleFontSize: CGFloat =
            16

        static let titleYOffset: CGFloat =
            -30

        static let symbolPointSize: CGFloat =
            24
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

    /*
     Cache SpriteKit textures rather than repeatedly
     rebuilding them every time nodes are rendered.
     */

    private var textureCache:
        [String: SKTexture] = [:]


    /*
     Remote image downloads are associated with the
     GameNodeID so they can be cancelled if the node
     hierarchy is rebuilt.
     */

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
        
        // Step 7: the scene-level nodeLayer owns the global z-order.
        // Keep this renderer local to its parent so the hierarchy remains:
        // roads < route selection < routes < game nodes.
        containerNode.zPosition =
            0
    }
    


    // =====================================================
    // MARK: - Render
    // =====================================================

    func render(
        nodes:
            [GameMapNode],
        roadGraph:
            RoadGraph
    ) {

        clear()


        for gameNode in nodes {

            guard
                gameNode.isEnabled,

                let worldPoint =
                    GameNodePlacementResolver
                        .worldPoint(
                            for:
                                gameNode,
                            graph:
                                roadGraph
                        )
            else {

                continue
            }


            let root =
                makeNode(
                    for:
                        gameNode
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
        selectedNodeID:
            GameNodeID?
    ) {

        for (
            nodeID,
            root
        ) in renderedNodes {

            let isSelected =
                nodeID ==
                selectedNodeID


            root.childNode(
                withName:
                    "selectionHalo"
            )?
            .isHidden =
                !isSelected
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
        for gameNode:
            GameMapNode
    ) -> SKNode {

        let root =
            SKNode()
        
        root.zPosition = 0

        root.name =
            "game.node.\(gameNode.id.rawValue.uuidString)"


        root.isHidden =
            false


        root.alpha =
            1


        root.userData =
            NSMutableDictionary(
                dictionary: [

                    "gameNodeID":
                        gameNode
                            .id
                            .rawValue
                            .uuidString,

                    "gameNodeKind":
                        gameNode
                            .content
                            .kind
                            .rawValue
                ]
            )


        // =============================================
        // Map-Style Chrome
        // =============================================

        let chrome =
            GameNodeMarkerChrome.make(
                isSelected:
                    false
            )


        chrome.name =
            "markerChrome"


        chrome.zPosition =
            -2


        root.addChild(
            chrome
        )


        // =============================================
        // Selection Halo
        // =============================================

        let halo =
            makeSelectionHalo()


        root.addChild(
            halo
        )


        // =============================================
        // Marker
        // =============================================

        let marker =
            makeMarker()


        root.addChild(
            marker
        )


        // =============================================
        // Image / Symbol
        // =============================================

        configureMarkerContent(
            gameNode:
                gameNode,
            root:
                root,
            marker:
                marker
        )


        // =============================================
        // Title
        // =============================================

        let title =
            makeTitleLabel(
                text:
                    gameNode
                        .content
                        .title
            )


        root.addChild(
            title
        )


        return root
    }
}

// =====================================================
// MARK: - Marker Components
// =====================================================

private extension GameNodeRenderer {

    func makeSelectionHalo()
        -> SKShapeNode {

        let halo =
            SKShapeNode(
                circleOfRadius:
                    GameNodeVisualMetrics
                                   .selectionRadius
            )


        halo.name =
            "selectionHalo"


        halo.fillColor =
            MapVisualTheme
                .roadSelectionHaloColor


        halo.strokeColor =
            MapVisualTheme
                .roadSelectionColor


        halo.lineWidth =
            4


        halo.isHidden =
            true


        halo.zPosition = 1


        return halo
    }


    func makeMarker()
        -> SKShapeNode {

        let marker =
            SKShapeNode(
                circleOfRadius:
                    GameNodeVisualMetrics
                                   .markerRadius
            )


        marker.name =
            "marker"


        marker.fillColor =
            MapVisualTheme
                .nodeFillColor


        marker.strokeColor =
            MapVisualTheme
                .nodeBorderColor


        marker.lineWidth =
                GameNodeVisualMetrics
                    .markerBorderWidth


        marker.zPosition = 2


        return marker
    }


    func makeTitleLabel(
        text:
            String
    ) -> SKLabelNode {

        let title =
            SKLabelNode(
                fontNamed:
                    "HelveticaNeue-Medium"
            )


        title.name =
            "nodeTitle"


        title.text =
            text


        title.fontSize =
            GameNodeVisualMetrics
                   .titleFontSize


        title.fontColor =
            MapVisualTheme
                .nodeLabelColor


        title.horizontalAlignmentMode =
            .center


        title.verticalAlignmentMode =
            .top


        title.position =
            CGPoint(
                    x: 0,
                    y:
                        GameNodeVisualMetrics
                            .titleYOffset
                )


        title.zPosition =
            2


        return title
    }
}

// =====================================================
// MARK: - Marker Content
// =====================================================

private extension GameNodeRenderer {

    func configureMarkerContent(
        gameNode:
            GameMapNode,
        root:
            SKNode,
        marker:
            SKShapeNode
    ) {

        guard let image =
            gameNode.content.image
        else {

            addFallbackSymbol(
                for:
                    gameNode.content.kind,
                to:
                    root
            )


            return
        }


        switch image {

        // =============================================
        // Local Asset
        // =============================================

        case let .asset(
            name
        ):

            if let texture =
                localAssetTexture(
                    named:
                        name
                )
            {

                apply(
                    texture:
                        texture,
                    to:
                        marker
                )

            } else {

                addFallbackSymbol(
                    for:
                        gameNode.content.kind,
                    to:
                        root
                )
            }


        // =============================================
        // SF Symbol
        // =============================================

        case let .systemSymbol(
            name
        ):

            if let texture =
                systemSymbolTexture(
                    named:
                        name
                )
            {

                apply(
                    texture:
                        texture,
                    to:
                        marker
                )

            } else {

                addFallbackSymbol(
                    for:
                        gameNode.content.kind,
                    to:
                        root
                )
            }


        // =============================================
        // Remote Image
        // =============================================

        case let .remote(
            urlString
        ):

            /*
             Immediately show a fallback while the
             remote image downloads.
             */

            addFallbackSymbol(
                for:
                    gameNode.content.kind,
                to:
                    root
            )


            loadRemoteImage(
                urlString:
                    urlString,
                nodeID:
                    gameNode.id,
                root:
                    root,
                marker:
                    marker
            )
        }
    }
}

// =====================================================
// MARK: - Local Asset
// =====================================================

private extension GameNodeRenderer {

    func localAssetTexture(
        named name:
            String
    ) -> SKTexture? {

        let key =
            "asset:\(name)"


        if let cached =
            textureCache[key] {

            return cached
        }


        guard let image =
            UIImage(
                named:
                    name
            )
        else {

            return nil
        }


        let texture =
            SKTexture(
                image:
                    image
            )


        texture.filteringMode =
            .linear


        textureCache[key] =
            texture


        return texture
    }
}

// =====================================================
// MARK: - System Symbol
// =====================================================

private extension GameNodeRenderer {

    func systemSymbolTexture(
        named name:
            String
    ) -> SKTexture? {

        let key =
            "symbol:\(name)"


        if let cached =
            textureCache[key] {

            return cached
        }


        let configuration =
            UIImage.SymbolConfiguration(
                pointSize: GameNodeVisualMetrics
                               .symbolPointSize,
                weight:
                    .semibold
            )


        guard let symbol =
            UIImage(
                systemName:
                    name,
                withConfiguration:
                    configuration
            )
        else {

            return nil
        }


        /*
         Convert the template-style SF Symbol
         into a permanently colored image before
         giving it to SpriteKit.
         */

        let coloredSymbol =
            symbol.withTintColor(
                MapVisualTheme
                    .nodeTextColor,
                renderingMode:
                    .alwaysOriginal
            )


        let texture =
            SKTexture(
                image:
                    coloredSymbol
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
        urlString:
            String,
        nodeID:
            GameNodeID,
        root:
            SKNode,
        marker:
            SKShapeNode
    ) {

        let cacheKey =
            "remote:\(urlString)"


        // =============================================
        // Already cached
        // =============================================

        if let cached =
            textureCache[
                cacheKey
            ]
        {

            apply(
                texture:
                    cached,
                to:
                    marker
            )


            removeFallbackSymbol(
                from:
                    root
            )


            return
        }


        // =============================================
        // Validate URL
        // =============================================

        guard let url =
            URL(
                string:
                    urlString
            )
        else {

            return
        }


        // =============================================
        // Cancel previous task for same node
        // =============================================

        remoteImageTasks[
            nodeID
        ]?
        .cancel()


        // =============================================
        // Start image request
        // =============================================

        let task =
            Task { @MainActor [weak self, weak root, weak marker] in

                guard let self else {

                    return
                }


                defer {

                    self.remoteImageTasks[
                        nodeID
                    ] =
                        nil
                }


                do {

                    let (
                        data,
                        response
                    ) =
                        try await URLSession
                            .shared
                            .data(
                                from:
                                    url
                            )


                    guard
                        !Task.isCancelled
                    else {

                        return
                    }


                    // MARK: HTTP status

                    if let httpResponse =
                        response as?
                            HTTPURLResponse {

                        guard
                            (
                                200...299
                            )
                            .contains(
                                httpResponse
                                    .statusCode
                            )
                        else {

                            return
                        }
                    }


                    // MARK: Decode Image

                    guard let image =
                        UIImage(
                            data:
                                data
                        )
                    else {

                        return
                    }


                    guard
                        !Task.isCancelled
                    else {

                        return
                    }


                    let texture =
                        SKTexture(
                            image:
                                image
                        )


                    texture.filteringMode =
                        .linear


                    // MARK: Cache

                    self.textureCache[
                        cacheKey
                    ] =
                        texture


                    // MARK: Apply

                    guard
                        let root,
                        let marker
                    else {

                        return
                    }


                    self.apply(
                        texture:
                            texture,
                        to:
                            marker
                    )


                    self.removeFallbackSymbol(
                        from:
                            root
                    )


                } catch {

                    /*
                     Keep the fallback symbol if
                     networking fails.
                     */
                }
            }


        remoteImageTasks[
            nodeID
        ] =
            task
    }


    func cancelRemoteImageTasks() {

        for task in
            remoteImageTasks.values {

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
        texture:
            SKTexture,
        to marker:
            SKShapeNode
    ) {

        marker.fillTexture =
            texture


        /*
         fillTexture is blended with fillColor.

         White preserves the texture's original
         colors.
         */

        marker.fillColor =
            .white
    }
}

// =====================================================
// MARK: - Fallback Symbol
// =====================================================

private extension GameNodeRenderer {

    func addFallbackSymbol(
        for kind:
            GameNodeKind,
        to root:
            SKNode
    ) {

        /*
         Prevent duplicates if this function
         happens to be called more than once.
         */

        guard
            root.childNode(
                withName:
                    "fallbackSymbol"
            )
            ==
            nil
        else {

            return
        }


        let symbol =
            SKLabelNode(
                fontNamed:
                    "HelveticaNeue-Bold"
            )


        symbol.name =
            "fallbackSymbol"


        symbol.text =
            fallbackSymbolText(
                for:
                    kind
            )


        symbol.fontSize =
            22


        symbol.fontColor =
            MapVisualTheme
                .nodeTextColor


        symbol.horizontalAlignmentMode =
            .center


        symbol.verticalAlignmentMode =
            .center


        symbol.zPosition =
            2


        root.addChild(
            symbol
        )
    }


    func removeFallbackSymbol(
        from root:
            SKNode
    ) {

        root.childNode(
            withName:
                "fallbackSymbol"
        )?
        .removeFromParent()
    }


    func fallbackSymbolText(
        for kind:
            GameNodeKind
    ) -> String {

        switch kind {

        case .label:

            return "•"


        case .user:

            return "U"


        case .activity:

            return "A"


        case .post:

            return "P"


        case .media:

            return "▶"


        case .hyperlink:

            return "↗"
        }
    }
}
