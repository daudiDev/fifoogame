//
//  MapGridRenderer.swift
//  fifoogame
//
//  Rewritten for the tile/card day-map UI.
//

import Foundation
import SpriteKit
import UIKit


@MainActor
final class MapGridRenderer {

    // =====================================================
    // MARK: - Public Container
    // =====================================================

    let containerNode = SKNode()

    /// Short card-to-card route bridges live below every card face. They are
    /// intentionally separate from the legacy RouteLayerRenderer: only the
    /// small gaps between sequential cards are visible, so the board reads as
    /// one stitched route without reintroducing roads.
    private let routeConnectorContainerNode =
        SKNode()


    // =====================================================
    // MARK: - Presentation State
    // =====================================================

    private var renderState:
        DayMapTileRenderState = .empty

    /// Current wall-clock position for visual emphasis only. GameStore /
    /// VirtualMapScene remain authoritative for time and route semantics.
    private var currentDayTime:
        DayTime = .noon

    private static let currentHourStopScale:
        CGFloat = 1.30

    private(set) var visibleWorldRect:
        CGRect = .zero

    private(set) var visibleRegion:
        GridVisibleRegion?


    private struct ViewportSignature:
        Equatable {

        let cameraPosition:
            CGPoint

        let cameraXScale:
            CGFloat

        let cameraYScale:
            CGFloat

        let cameraRotation:
            CGFloat

        let viewBounds:
            CGRect
    }


    private var lastViewportSignature:
        ViewportSignature?


    // =====================================================
    // MARK: - Rendered Cells
    // =====================================================

    private final class RenderedCell {

        let rootNode = SKNode()

        let stackBackTwoNode = SKShapeNode()
        let stackBackOneNode = SKShapeNode()
        let shadowNode = SKShapeNode()
        let cardNode = SKShapeNode()
        let routeTintNode = SKShapeNode()
        let faceBorderNode = SKShapeNode()
        let routeBorderNode = SKShapeNode()
        let routePatternNode = SKSpriteNode()
        let selectionBorderNode = SKShapeNode()

        // Current-user/current-time treatment. The boundary marker identifies
        // the user's exact live route position. The compact marker and time
        // badge provide emphasis without drawing a large border around the card.
        let boundaryHaloNode = SKShapeNode()
        let boundaryNode = SKShapeNode(circleOfRadius: 9.5)
        let boundaryBadgeNode = SKShapeNode()
        let boundaryBadgeLabel = SKLabelNode(fontNamed: "HelveticaNeue-Bold")

        let hiddenLayer = SKNode()
        let revealedLayer = SKNode()

        /// Decorative Pied Piper emblem shown on every face-down / hidden card.
        let hiddenArtworkSpriteNode = SKSpriteNode()

        let artworkCropNode = SKCropNode()
        let artworkSpriteNode = SKSpriteNode()
        let artworkBottomOverlayNode = SKShapeNode()

        let titleLabel = SKLabelNode(fontNamed: "HelveticaNeue-Bold")
        let timeLabel = SKLabelNode(fontNamed: "HelveticaNeue-Medium")
        let routeGlyphLabel = SKLabelNode(fontNamed: "HelveticaNeue-Bold")
        let routeArtworkSpriteNode = SKSpriteNode()

        // Revealed face for an empty stop card.
        let emptyTimeLabel = SKLabelNode(fontNamed: "HelveticaNeue-Bold")
        let emptyArtworkSpriteNode = SKSpriteNode()
        let emptyProgressLabel = SKLabelNode(fontNamed: "HelveticaNeue-Bold")
        let emptyAddStopLabel = SKLabelNode(fontNamed: "HelveticaNeue-Bold")

        let collisionBadgeNode = SKShapeNode(circleOfRadius: 9)
        let collisionLabel = SKLabelNode(fontNamed: "HelveticaNeue-Bold")

        var cellID:
            GridCellID?

        var lastSnapshot:
            DayMapTileSnapshot?


        init() {

            rootNode.isUserInteractionEnabled = false

            stackBackTwoNode.isUserInteractionEnabled = false
            stackBackOneNode.isUserInteractionEnabled = false
            shadowNode.isUserInteractionEnabled = false
            cardNode.isUserInteractionEnabled = false
            routeTintNode.isUserInteractionEnabled = false
            faceBorderNode.isUserInteractionEnabled = false
            routeBorderNode.isUserInteractionEnabled = false
            routePatternNode.isUserInteractionEnabled = false
            selectionBorderNode.isUserInteractionEnabled = false
            boundaryHaloNode.isUserInteractionEnabled = false
            boundaryNode.isUserInteractionEnabled = false
            boundaryBadgeNode.isUserInteractionEnabled = false
            boundaryBadgeLabel.isUserInteractionEnabled = false

            hiddenLayer.isUserInteractionEnabled = false
            revealedLayer.isUserInteractionEnabled = false
            hiddenArtworkSpriteNode.isUserInteractionEnabled = false
            artworkCropNode.isUserInteractionEnabled = false
            artworkSpriteNode.isUserInteractionEnabled = false
            artworkBottomOverlayNode.isUserInteractionEnabled = false
            routeArtworkSpriteNode.isUserInteractionEnabled = false
            emptyTimeLabel.isUserInteractionEnabled = false
            emptyArtworkSpriteNode.isUserInteractionEnabled = false
            emptyProgressLabel.isUserInteractionEnabled = false
            emptyAddStopLabel.isUserInteractionEnabled = false
            collisionBadgeNode.isUserInteractionEnabled = false
            collisionLabel.isUserInteractionEnabled = false

            rootNode.addChild(stackBackTwoNode)
            rootNode.addChild(stackBackOneNode)
            rootNode.addChild(shadowNode)
            rootNode.addChild(cardNode)
            rootNode.addChild(routeTintNode)
            rootNode.addChild(faceBorderNode)
            rootNode.addChild(routeBorderNode)
            rootNode.addChild(routePatternNode)
            rootNode.addChild(selectionBorderNode)
            rootNode.addChild(boundaryHaloNode)
            rootNode.addChild(boundaryNode)
            rootNode.addChild(boundaryBadgeNode)
            rootNode.addChild(boundaryBadgeLabel)

            rootNode.addChild(hiddenLayer)
            rootNode.addChild(revealedLayer)

            hiddenLayer.addChild(hiddenArtworkSpriteNode)

            artworkCropNode.addChild(artworkSpriteNode)
            artworkCropNode.addChild(artworkBottomOverlayNode)
            revealedLayer.addChild(artworkCropNode)
            revealedLayer.addChild(routeArtworkSpriteNode)
            revealedLayer.addChild(titleLabel)
            revealedLayer.addChild(timeLabel)
            revealedLayer.addChild(routeGlyphLabel)
            revealedLayer.addChild(emptyTimeLabel)
            revealedLayer.addChild(emptyArtworkSpriteNode)
            revealedLayer.addChild(emptyProgressLabel)
            revealedLayer.addChild(emptyAddStopLabel)
            revealedLayer.addChild(collisionBadgeNode)
            revealedLayer.addChild(collisionLabel)
        }
    }


    private var renderedCells:
        [GridCellID: RenderedCell] = [:]

    private var recycledCells:
        [RenderedCell] = []

    private let maximumRecycledCellCount = 96


    // =====================================================
    // MARK: - Artwork Loading
    // =====================================================

    private var textureCache:
        [String: SKTexture] = [:]

    private var routePatternTextureCache:
        [String: SKTexture] = [:]

    /// Shared card-back texture. Every hidden tile reuses the same texture
    /// rather than creating a separate texture object per rendered cell.
    private lazy var hiddenCardBackTexture: SKTexture = {

        configuredTexture(
            named: "pied_piper_card_back"
        )
    }()

    private lazy var greenPiedPiperTexture: SKTexture = {

        configuredTexture(
            named: "green_pied_piper"
        )
    }()

    private lazy var orangePiedPiperTexture: SKTexture = {

        configuredTexture(
            named: "orange_pied_piper"
        )
    }()

    private lazy var purplePiedPiperTexture: SKTexture = {

        configuredTexture(
            named: "purple_pied_piper"
        )
    }()


    private lazy var pathDirectionArrowTexture: SKTexture = {

        configuredTexture(
            named: "path_direction_arrow"
        )
    }()

    private func configuredTexture(
        named name: String
    ) -> SKTexture {

        let texture =
            SKTexture(
                imageNamed: name
            )

        texture.filteringMode =
            .linear

        return texture
    }

    private var remoteImageTasks:
        [GridCellID: Task<Void, Never>] = [:]


    // =====================================================
    // MARK: - Geometry
    // =====================================================

    private var tileSize:
        CGFloat {

        GridMapGeometry
            .tileRect(
                for:
                    GridCellID(
                        column: 0,
                        row: 0
                    )
            )
            .width
    }


    private var cardRect:
        CGRect {

        CGRect(
            x: -tileSize / 2,
            y: -tileSize / 2,
            width: tileSize,
            height: tileSize
        )
    }


    private var cornerRadius:
        CGFloat {

        // Pass 5: half the previous radius so the islands feel more like
        // compact cards while retaining a small amount of softness.
        min(
            8.5,
            tileSize * 0.0825
        )
    }


    private var artworkSize:
        CGFloat {

        // Revealed artwork is now full bleed.
        tileSize
    }


    private var artworkCenterY:
        CGFloat {

        0
    }


    private var artworkRect:
        CGRect {

        cardRect
    }


    // =====================================================
    // MARK: - Init
    // =====================================================

    init() {

        containerNode.name =
            "dayMap.tileCards"

        containerNode.isUserInteractionEnabled = false

        routeConnectorContainerNode.name =
            "dayMap.tileRouteConnections"

        routeConnectorContainerNode.isUserInteractionEnabled =
            false

        // Cell roots sit at z=0, but their card faces begin at z=10. Path
        // directional affordances sit below those faces at z=7, so arrows can
        // live in the gutters between cards without competing with the stop
        // content itself. Route-builder preview connectors may still render
        // here as thin planning lines.
        routeConnectorContainerNode.zPosition =
            7

        containerNode.addChild(
            routeConnectorContainerNode
        )
    }


    // =====================================================
    // MARK: - Public State API
    // =====================================================

    func render(
        _ state: DayMapTileRenderState,
        animated: Bool = true
    ) {

        let previous =
            renderState

        renderState =
            state


        for (id, cell) in renderedCells {

            let oldSnapshot =
                previous.snapshot(
                    for: id
                )

            let newSnapshot =
                state.snapshot(
                    for: id
                )

            apply(
                newSnapshot,
                previousSnapshot: oldSnapshot,
                to: cell,
                animated: animated
            )
        }

        renderRouteConnectors()
    }


    /// Updates time-dependent map emphasis without changing any model data.
    /// Real stop cards scheduled during the current clock hour are rendered
    /// 30% larger. The live ME/NOW label is rendered separately by
    /// CurrentTimeRenderer at the exact semantic current time/progress point.
    func renderCurrentTime(
        _ time: DayTime,
        animated: Bool = true
    ) {

        guard currentDayTime != time else {
            return
        }

        let previousHour =
            hourIndex(
                for: currentDayTime
            )

        currentDayTime =
            time

        let newHour =
            hourIndex(
                for: time
            )

        for (_, cell) in renderedCells {

            guard let snapshot = cell.lastSnapshot else {
                continue
            }

            applyCurrentTimeEmphasis(
                snapshot,
                to: cell,
                animated:
                    animated
                    && previousHour != newHour
            )
        }
    }


    func snapshot(
        for id: GridCellID
    ) -> DayMapTileSnapshot {

        renderState.snapshot(
            for: id
        )
    }


    func tileCellID(
        hitByWorldPoint point: CGPoint
    ) -> GridCellID? {

        GridMapGeometry
            .tileCellID(
                hitByWorldPoint: point
            )
    }


    /// The revealed empty-card face intentionally exposes only one semantic
    /// action: the Add Stop label at the bottom of the card. Taps elsewhere
    /// on that empty face remain inert so the label reads like a real control.
    func isAddStopActionHit(
        worldPoint point: CGPoint,
        in cellID: GridCellID
    ) -> Bool {

        let center =
            GridMapGeometry
                .tileCenter(
                    for: cellID
                )

        let local =
            CGPoint(
                x: point.x - center.x,
                y: point.y - center.y
            )

        let actionRect =
            CGRect(
                x: -tileSize * 0.44,
                y: -tileSize * 0.50,
                width: tileSize * 0.88,
                height: tileSize * 0.22
            )

        return actionRect.contains(
            local
        )
    }


    // =====================================================
    // MARK: - Build / Reset
    // =====================================================

    func rebuild() {

        recycleAllRenderedCells()

        routeConnectorContainerNode
            .removeAllChildren()

        visibleWorldRect = .zero
        visibleRegion = nil
        lastViewportSignature = nil
    }


    // =====================================================
    // MARK: - Camera Region Tracking
    // =====================================================

    @discardableResult
    func updateVisibleRegion(
        scene: SKScene,
        view: SKView
    ) -> Bool {

        let camera =
            scene.camera

        let signature =
            ViewportSignature(
                cameraPosition:
                    camera?.position
                    ?? .zero,
                cameraXScale:
                    camera?.xScale
                    ?? 1,
                cameraYScale:
                    camera?.yScale
                    ?? 1,
                cameraRotation:
                    camera?.zRotation
                    ?? 0,
                viewBounds:
                    view.bounds
            )


        guard signature != lastViewportSignature else {
            return false
        }


        lastViewportSignature =
            signature


        let nextWorldRect =
            Self.worldRectVisibleInView(
                scene: scene,
                view: view
            )


        let nextRegion =
            GridMapGeometry
                .visibleRegion(
                    in: nextWorldRect
                )


        let changed =
            nextRegion != visibleRegion


        visibleWorldRect =
            nextWorldRect


        guard changed else {
            return false
        }


        visibleRegion =
            nextRegion


        synchronizeRenderedCells(
            to: nextRegion
        )

        renderRouteConnectors()


        return true
    }


    var visibleCellIDs:
        [GridCellID] {

        visibleRegion?.cellIDs
        ?? []
    }


    var renderedCellCount:
        Int {

        renderedCells.count
    }


    var recycledCellCount:
        Int {

        recycledCells.count
    }
}


// =====================================================
// MARK: - Visible Cell Synchronization
// =====================================================

private extension MapGridRenderer {

    func synchronizeRenderedCells(
        to region: GridVisibleRegion?
    ) {

        guard let region else {

            recycleAllRenderedCells()
            return
        }


        let desiredIDs =
            Set(region.cellIDs)


        for id in Array(renderedCells.keys) {

            guard !desiredIDs.contains(id) else {
                continue
            }

            recycleRenderedCell(id)
        }


        for id in desiredIDs {

            guard renderedCells[id] == nil else {
                continue
            }

            addRenderedCell(id)
        }
    }


    func addRenderedCell(
        _ id: GridCellID
    ) {

        let cell =
            recycledCells.popLast()
            ?? makeRenderedCell()


        configure(
            cell,
            for: id
        )


        containerNode.addChild(
            cell.rootNode
        )


        renderedCells[id] =
            cell
    }


    func recycleRenderedCell(
        _ id: GridCellID
    ) {

        guard let cell =
            renderedCells.removeValue(
                forKey: id
            )
        else {
            return
        }


        remoteImageTasks[id]?.cancel()
        remoteImageTasks[id] = nil

        cell.rootNode.removeAllActions()
        cell.rootNode.removeFromParent()
        cell.rootNode.setScale(1)
        cell.rootNode.xScale = 1
        cell.rootNode.yScale = 1

        cell.artworkSpriteNode.texture = nil
        cell.artworkSpriteNode.size = .zero

        cell.cellID = nil
        cell.lastSnapshot = nil


        if recycledCells.count < maximumRecycledCellCount {

            recycledCells.append(cell)
        }
    }


    func recycleAllRenderedCells() {

        for id in Array(renderedCells.keys) {
            recycleRenderedCell(id)
        }
    }
}


// =====================================================
// MARK: - Route Stitching
// =====================================================

private extension MapGridRenderer {

    /// Draws only the tiny piece of route that crosses the gap between two
    /// sequential cards. The line runs center-to-center, but because it sits
    /// below the card faces, the card bodies mask almost all of it. What the
    /// player sees is a short colored bridge that visually stitches the two
    /// route islands together.
    func renderRouteConnectors() {

        routeConnectorContainerNode
            .removeAllChildren()

        guard
            let visibleRegion,
            !renderState.routeConnections.isEmpty
        else {
            return
        }


        let sortedConnections =
            renderState
                .routeConnections
                .sorted { lhs, rhs in

                    if lhs.firstCellID.row != rhs.firstCellID.row {
                        return lhs.firstCellID.row < rhs.firstCellID.row
                    }

                    if lhs.firstCellID.column != rhs.firstCellID.column {
                        return lhs.firstCellID.column < rhs.firstCellID.column
                    }

                    if lhs.secondCellID.row != rhs.secondCellID.row {
                        return lhs.secondCellID.row < rhs.secondCellID.row
                    }

                    return lhs.secondCellID.column < rhs.secondCellID.column
                }


        for connection in sortedConnections {

            guard
                visibleRegion.contains(
                    connection.firstCellID
                )
                || visibleRegion.contains(
                    connection.secondCellID
                )
            else {
                continue
            }

            let firstPoint =
                GridMapGeometry
                    .tileCenter(
                        for: connection.fromCellID
                    )

            let secondPoint =
                GridMapGeometry
                    .tileCenter(
                        for: connection.toCellID
                    )

            let path =
                CGMutablePath()

            path.move(
                to: firstPoint
            )

            path.addLine(
                to: secondPoint
            )

            // Committed user-path states now use directional arrows in the
            // gutters between sequential stops rather than a background band
            // or thin join line.
            if shouldShowActivePathArrow(
                for: connection.style
            ) {

                let arrow =
                    SKSpriteNode(
                        texture:
                            pathDirectionArrowTexture
                    )

                arrow.name =
                    "dayMap.pathDirectionArrow"

                let dx =
                    secondPoint.x - firstPoint.x

                let dy =
                    secondPoint.y - firstPoint.y

                let distance =
                    hypot(dx, dy)

                let gapLength =
                    max(
                        tileSize * 0.18,
                        distance - tileSize * 0.90
                    )

                let arrowSide =
                    min(
                        tileSize * 0.32,
                        max(
                            tileSize * 0.18,
                            gapLength * 1.08
                        )
                    )

                arrow.size =
                    CGSize(
                        width: arrowSide,
                        height: arrowSide
                    )

                arrow.position =
                    CGPoint(
                        x: (firstPoint.x + secondPoint.x) * 0.5,
                        y: (firstPoint.y + secondPoint.y) * 0.5
                    )

                let directionAngle =
                    atan2(dy, dx)

                // The supplied arrow asset points downward at zero rotation.
                arrow.zRotation =
                    directionAngle + (.pi / 2)

                arrow.alpha =
                    0.92

                arrow.isUserInteractionEnabled =
                    false

                arrow.zPosition =
                    1

                routeConnectorContainerNode
                    .addChild(arrow)
            }


            // Preview-path states keep their thin planning connectors.
            if shouldShowPreviewConnector(
                for: connection.style
            ) {

                let halo =
                    SKShapeNode(
                        path: path
                    )

                halo.name =
                    "dayMap.tileRouteConnection.previewHalo"

                halo.strokeColor =
                    connectorHaloColor(
                        for: connection.style
                    )

                halo.lineWidth =
                    connectorWidth(
                        for: connection.style
                    )
                    + 5

                halo.lineCap =
                    .round

                halo.fillColor =
                    .clear

                halo.isAntialiased =
                    true

                halo.isUserInteractionEnabled =
                    false

                halo.zPosition =
                    0


                let bridge =
                    SKShapeNode(
                        path: path
                    )

                bridge.name =
                    "dayMap.tileRouteConnection.previewBridge"

                bridge.strokeColor =
                    connectorColor(
                        for: connection.style
                    )

                bridge.lineWidth =
                    connectorWidth(
                        for: connection.style
                    )

                bridge.lineCap =
                    .round

                bridge.fillColor =
                    .clear

                bridge.isAntialiased =
                    true

                bridge.isUserInteractionEnabled =
                    false

                bridge.zPosition =
                    1


                routeConnectorContainerNode
                    .addChild(halo)

                routeConnectorContainerNode
                    .addChild(bridge)
            }

        }
    }


    func shouldShowActivePathArrow(
        for style: DayMapTileRouteConnectionStyle
    ) -> Bool {

        switch style {

        case .completed,
             .chosen,
             .alternative:
            return true

        case .previewSelected,
             .previewAlternative:
            return false
        }
    }


    func shouldShowPreviewConnector(
        for style: DayMapTileRouteConnectionStyle
    ) -> Bool {

        switch style {

        case .previewSelected,
             .previewAlternative:
            return true

        case .completed,
             .chosen,
             .alternative:
            return false
        }
    }


    func connectorColor(
        for style: DayMapTileRouteConnectionStyle
    ) -> SKColor {

        switch style {

        case .completed:
            return RouteVisualTheme.completedColor

        case .chosen:
            return RouteVisualTheme.chosenColor

        case .alternative:
            return RouteVisualTheme.alternativeColor

        case .previewSelected:
            return RouteVisualTheme.previewSelectedColor

        case .previewAlternative:
            return RouteVisualTheme.previewAlternativeColor
        }
    }


    func connectorHaloColor(
        for style: DayMapTileRouteConnectionStyle
    ) -> SKColor {

        switch style {

        case .completed:
            return RouteVisualTheme
                .completedColor
                .withAlphaComponent(0.16)

        case .chosen:
            return RouteVisualTheme
                .chosenColor
                .withAlphaComponent(0.14)

        case .alternative:
            return RouteVisualTheme
                .alternativeColor
                .withAlphaComponent(0.08)

        case .previewSelected:
            return RouteVisualTheme
                .previewSelectedColor
                .withAlphaComponent(0.18)

        case .previewAlternative:
            return RouteVisualTheme
                .previewAlternativeColor
                .withAlphaComponent(0.08)
        }
    }


    func connectorWidth(
        for style: DayMapTileRouteConnectionStyle
    ) -> CGFloat {

        switch style {

        case .completed:
            return 8

        case .chosen:
            return 7.5

        case .alternative:
            return 4.5

        case .previewSelected:
            return 8

        case .previewAlternative:
            return 4.5
        }
    }
}


// =====================================================
// MARK: - Cell Construction
// =====================================================

private extension MapGridRenderer {

    private func makeRenderedCell() -> RenderedCell {

        let cell =
            RenderedCell()


        let cardPath =
            CGPath(
                roundedRect: cardRect,
                cornerWidth: cornerRadius,
                cornerHeight: cornerRadius,
                transform: nil
            )


        let shadowPath =
            CGPath(
                roundedRect:
                    cardRect.offsetBy(
                        dx: 0,
                        dy: -5
                    ),
                cornerWidth: cornerRadius,
                cornerHeight: cornerRadius,
                transform: nil
            )


        // A multi-node point is represented as a physical stack rather than
        // a badge. Only the exposed lower/right edges of these back cards are
        // visible behind the front face. Visibility is configured per snapshot.
        for (node, offset, z) in [
            (cell.stackBackTwoNode, CGPoint(x: 7, y: -7), CGFloat(2)),
            (cell.stackBackOneNode, CGPoint(x: 4, y: -4), CGFloat(3))
        ] {

            node.path = cardPath
            node.position = offset
            node.fillColor = MapVisualTheme.tileRevealedFillColor
            node.strokeColor = SKColor.white.withAlphaComponent(0.22)
            node.lineWidth = 1.1
            node.zPosition = z
            node.isHidden = true
        }


        cell.shadowNode.path =
            shadowPath

        cell.shadowNode.fillColor =
            MapVisualTheme.tileShadowColor

        cell.shadowNode.strokeColor =
            .clear

        cell.shadowNode.zPosition =
            0


        cell.cardNode.path =
            cardPath

        cell.cardNode.lineWidth =
            0

        cell.cardNode.strokeColor =
            .clear

        cell.cardNode.zPosition =
            10


        // The old inset/inner border is intentionally gone. This one outer
        // perimeter is drawn above the full-bleed image so the media reaches
        // the island edge without an inset frame.
        cell.faceBorderNode.path =
            cardPath

        cell.faceBorderNode.fillColor =
            .clear

        cell.faceBorderNode.lineWidth =
            1.35

        cell.faceBorderNode.zPosition =
            18


        cell.routeTintNode.path =
            cardPath

        cell.routeTintNode.fillColor =
            .clear

        cell.routeTintNode.strokeColor =
            .clear

        cell.routeTintNode.zPosition =
            11


        let routeRect =
            cardRect.insetBy(
                dx: -2.5,
                dy: -2.5
            )

        cell.routeBorderNode.path =
            CGPath(
                roundedRect: routeRect,
                cornerWidth: cornerRadius + 2.5,
                cornerHeight: cornerRadius + 2.5,
                transform: nil
            )

        cell.routeBorderNode.fillColor =
            .clear

        cell.routeBorderNode.zPosition =
            20

        cell.routePatternNode.size =
            routeRect.size

        cell.routePatternNode.position =
            .zero

        cell.routePatternNode.zPosition =
            21

        cell.routePatternNode.isHidden =
            true


        let selectionRect =
            cardRect.insetBy(
                dx: -4,
                dy: -4
            )

        cell.selectionBorderNode.path =
            CGPath(
                roundedRect: selectionRect,
                cornerWidth: cornerRadius + 4,
                cornerHeight: cornerRadius + 4,
                transform: nil
            )

        cell.selectionBorderNode.fillColor =
            .clear

        cell.selectionBorderNode.strokeColor =
            MapVisualTheme.tileSelectionColor

        cell.selectionBorderNode.lineWidth =
            2.25

        cell.selectionBorderNode.glowWidth =
            2.5

        cell.selectionBorderNode.zPosition =
            25


        let currentBoundaryHaloRect =
            cardRect.insetBy(
                dx: -6,
                dy: -6
            )

        cell.boundaryHaloNode.path =
            CGPath(
                roundedRect: currentBoundaryHaloRect,
                cornerWidth: cornerRadius + 6,
                cornerHeight: cornerRadius + 6,
                transform: nil
            )

        cell.boundaryHaloNode.fillColor =
            .clear

        cell.boundaryHaloNode.strokeColor =
            RouteVisualTheme.boundaryStrokeColor
                .withAlphaComponent(0.96)

        cell.boundaryHaloNode.lineWidth =
            4.5

        cell.boundaryHaloNode.glowWidth =
            8

        cell.boundaryHaloNode.zPosition =
            28


        cell.boundaryNode.fillColor =
            RouteVisualTheme.boundaryFillColor

        cell.boundaryNode.strokeColor =
            RouteVisualTheme.boundaryStrokeColor

        cell.boundaryNode.lineWidth =
            4

        cell.boundaryNode.glowWidth =
            3

        cell.boundaryNode.position =
            CGPoint(
                x: tileSize / 2 - 8,
                y: tileSize / 2 - 8
            )

        cell.boundaryNode.zPosition =
            31


        let boundaryBadgeSize =
            CGSize(
                width: min(122, tileSize * 1.62),
                height: 24
            )

        let boundaryBadgeRect =
            CGRect(
                x: -boundaryBadgeSize.width / 2,
                y: -boundaryBadgeSize.height / 2,
                width: boundaryBadgeSize.width,
                height: boundaryBadgeSize.height
            )

        cell.boundaryBadgeNode.path =
            CGPath(
                roundedRect: boundaryBadgeRect,
                cornerWidth: 12,
                cornerHeight: 12,
                transform: nil
            )

        cell.boundaryBadgeNode.fillColor =
            RouteVisualTheme.boundaryStrokeColor
                .withAlphaComponent(0.98)

        cell.boundaryBadgeNode.strokeColor =
            .white

        cell.boundaryBadgeNode.lineWidth =
            2

        cell.boundaryBadgeNode.position =
            CGPoint(
                x: 0,
                y: tileSize / 2 + 18
            )

        cell.boundaryBadgeNode.zPosition =
            32


        configureLabel(
            cell.boundaryBadgeLabel,
            fontSize: 9.5,
            color: .white
        )

        cell.boundaryBadgeLabel.horizontalAlignmentMode =
            .center

        cell.boundaryBadgeLabel.verticalAlignmentMode =
            .center

        cell.boundaryBadgeLabel.position =
            cell.boundaryBadgeNode.position

        cell.boundaryBadgeLabel.zPosition =
            33


        // Face-down cards use the Pied Piper silhouette as their single
        // visual mark. The source asset has a transparent background;
        // SpriteKit tints the silhouette so it stays subtle against the
        // dark card back and works at every zoom level.
        cell.hiddenArtworkSpriteNode.texture =
            hiddenCardBackTexture

        cell.hiddenArtworkSpriteNode.size =
            CGSize(
                width: tileSize * 0.72,
                height: tileSize * 0.72
            )

        cell.hiddenArtworkSpriteNode.position =
            .zero

        cell.hiddenArtworkSpriteNode.color =
            .white

        cell.hiddenArtworkSpriteNode.colorBlendFactor =
            1

        cell.hiddenArtworkSpriteNode.alpha =
            0.32

        cell.hiddenArtworkSpriteNode.zPosition =
            1


        let artworkPath =
            CGPath(
                roundedRect: artworkRect,
                cornerWidth: cornerRadius,
                cornerHeight: cornerRadius,
                transform: nil
            )

        let artworkMask =
            SKShapeNode(
                path: artworkPath
            )

        artworkMask.fillColor =
            .white

        artworkMask.strokeColor =
            .clear

        cell.artworkCropNode.maskNode =
            artworkMask

        cell.artworkCropNode.position =
            CGPoint(
                x: 0,
                y: artworkCenterY
            )

        cell.artworkCropNode.zPosition =
            0

        cell.artworkSpriteNode.position =
            .zero

        cell.artworkSpriteNode.zPosition =
            0


        // Pass 5.1 keeps the revealed face intentionally minimal: the
        // artwork is fully visible except for one bottom readability overlay
        // containing only the node title and time. Node-kind and route-status
        // text are communicated visually elsewhere and are not rendered.
        let bottomOverlayHeight =
            max(38, tileSize * 0.34)

        cell.artworkBottomOverlayNode.path =
            CGPath(
                rect:
                    CGRect(
                        x: -tileSize / 2,
                        y: -tileSize / 2,
                        width: tileSize,
                        height: bottomOverlayHeight
                    ),
                transform: nil
            )

        cell.artworkBottomOverlayNode.fillColor =
            SKColor.black.withAlphaComponent(0.58)

        cell.artworkBottomOverlayNode.strokeColor =
            .clear

        cell.artworkBottomOverlayNode.zPosition =
            1


        configureLabel(
            cell.titleLabel,
            fontSize: 11.25,
            color:
                MapVisualTheme
                    .tilePrimaryTextColor
        )

        cell.titleLabel.position =
            CGPoint(
                x: 0,
                y: -tileSize * 0.275
            )


        configureLabel(
            cell.timeLabel,
            fontSize: 7.4,
            color:
                MapVisualTheme
                    .tileSecondaryTextColor
        )

        cell.timeLabel.horizontalAlignmentMode =
            .left

        cell.timeLabel.position =
            CGPoint(
                x: -tileSize / 2 + 9,
                y: -tileSize / 2 + 10
            )


        configureLabel(
            cell.routeGlyphLabel,
            fontSize: 17,
            color:
                MapVisualTheme
                    .tileRouteGlyphColor
        )

        cell.routeGlyphLabel.text =
            "◆"

        cell.routeGlyphLabel.position =
            CGPoint(
                x: 0,
                y: 0
            )

        cell.routeGlyphLabel.zPosition =
            16

        cell.routeArtworkSpriteNode.size =
            CGSize(
                width: tileSize * 0.42,
                height: tileSize * 0.42
            )

        cell.routeArtworkSpriteNode.position =
            CGPoint(
                x: 0,
                y: 1
            )

        cell.routeArtworkSpriteNode.alpha =
            0.92

        cell.routeArtworkSpriteNode.zPosition =
            3


        // Revealed empty-stop face: time -> neutral Pied Piper -> potential
        // progress delta -> Add Stop action.
        configureLabel(
            cell.emptyTimeLabel,
            fontSize: 9.6,
            color: MapVisualTheme.tilePrimaryTextColor
        )

        cell.emptyTimeLabel.position =
            CGPoint(
                x: 0,
                y: tileSize * 0.37
            )

        cell.emptyTimeLabel.zPosition =
            4

        cell.emptyArtworkSpriteNode.texture =
            hiddenCardBackTexture

        cell.emptyArtworkSpriteNode.size =
            CGSize(
                width: tileSize * 0.42,
                height: tileSize * 0.42
            )

        cell.emptyArtworkSpriteNode.position =
            CGPoint(
                x: 0,
                y: tileSize * 0.08
            )

        cell.emptyArtworkSpriteNode.color =
            .white

        cell.emptyArtworkSpriteNode.colorBlendFactor =
            1

        cell.emptyArtworkSpriteNode.alpha =
            0.78

        cell.emptyArtworkSpriteNode.zPosition =
            3

        configureLabel(
            cell.emptyProgressLabel,
            fontSize: 12.0,
            color: MapVisualTheme.tilePrimaryTextColor
        )

        cell.emptyProgressLabel.position =
            CGPoint(
                x: 0,
                y: -tileSize * 0.20
            )

        cell.emptyProgressLabel.zPosition =
            4

        configureLabel(
            cell.emptyAddStopLabel,
            fontSize: 10.5,
            color: MapVisualTheme.tilePrimaryTextColor
        )

        cell.emptyAddStopLabel.text =
            "Add Stop"

        cell.emptyAddStopLabel.position =
            CGPoint(
                x: 0,
                y: -tileSize * 0.39
            )

        cell.emptyAddStopLabel.zPosition =
            4


        // Pass 5 replaces the old +N collision badge with physical card
        // stacking, so these legacy nodes stay permanently hidden.
        cell.collisionBadgeNode.isHidden = true
        cell.collisionLabel.isHidden = true

        cell.titleLabel.zPosition = 3
        cell.timeLabel.zPosition = 3
        cell.routeGlyphLabel.zPosition = 3

        cell.hiddenLayer.zPosition =
            15

        cell.revealedLayer.zPosition =
            15


        return cell
    }


    func configureLabel(
        _ label: SKLabelNode,
        fontSize: CGFloat,
        color: SKColor
    ) {

        label.fontSize = fontSize
        label.fontColor = color
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.numberOfLines = 1
    }
}


// =====================================================
// MARK: - Cell Configuration / State
// =====================================================

private extension MapGridRenderer {

    private func configure(
        _ cell: RenderedCell,
        for id: GridCellID
    ) {

        cell.cellID =
            id

        cell.rootNode.name =
            "dayMap.tile.\(id.column).\(id.row)"

        cell.rootNode.position =
            GridMapGeometry
                .tileCenter(
                    for: id
                )

        cell.rootNode.setScale(1)
        cell.rootNode.xScale = 1
        cell.rootNode.yScale = 1


        let snapshot =
            renderState.snapshot(
                for: id
            )


        apply(
            snapshot,
            previousSnapshot: nil,
            to: cell,
            animated: false
        )
    }


    private func apply(
        _ snapshot: DayMapTileSnapshot,
        previousSnapshot: DayMapTileSnapshot?,
        to cell: RenderedCell,
        animated: Bool
    ) {

        let revealChanged =
            previousSnapshot?.revealState
            != nil
            &&
            previousSnapshot?.revealState
            != snapshot.revealState


        cell.rootNode.removeAction(
            forKey: "tileFlip"
        )


        guard
            animated,
            revealChanged,
            let previousSnapshot
        else {

            applyVisuals(
                snapshot,
                previousSnapshot: previousSnapshot,
                to: cell
            )

            cell.lastSnapshot =
                snapshot

            applyCurrentTimeEmphasis(
                snapshot,
                to: cell,
                animated: false
            )

            return
        }


        // A true two-face card flip: preserve the old face while the card
        // collapses, swap content at the midpoint, then expand the new face.
        // This avoids the old implementation briefly showing the revealed
        // face before the flip had actually reached its edge.
        applyVisuals(
            previousSnapshot,
            previousSnapshot: nil,
            to: cell
        )

        cell.lastSnapshot =
            previousSnapshot

        applyCurrentTimeEmphasis(
            previousSnapshot,
            to: cell,
            animated: false
        )

        let targetScale =
            visualScale(
                for: snapshot
            )


        let midpointSwap =
            SKAction.run { [weak self, weak cell] in

                guard
                    let self,
                    let cell,
                    cell.cellID == snapshot.id,
                    self.renderState.snapshot(
                        for: snapshot.id
                    ) == snapshot
                else {
                    return
                }

                self.applyVisuals(
                    snapshot,
                    previousSnapshot: previousSnapshot,
                    to: cell
                )

                cell.lastSnapshot =
                    snapshot

                self.applyCurrentTimeDecorations(
                    snapshot,
                    to: cell
                )
            }


        cell.rootNode.yScale =
            targetScale

        cell.rootNode.run(
            .sequence([
                .scaleX(
                    to: 0.035,
                    duration: 0.11
                ),
                midpointSwap,
                .scaleX(
                    to: targetScale,
                    duration: 0.14
                )
            ]),
            withKey: "tileFlip"
        )
    }


    private func applyVisuals(
        _ snapshot: DayMapTileSnapshot,
        previousSnapshot: DayMapTileSnapshot?,
        to cell: RenderedCell
    ) {

        let revealed =
            snapshot.revealState == .revealed


        cell.hiddenLayer.isHidden =
            revealed

        cell.revealedLayer.isHidden =
            !revealed

        // Pass 5.8: a concealed card that already contains stop content but
        // does not belong to completed/chosen/alternate path state uses the
        // purple Pied Piper. Truly empty face-down cards keep the neutral back.
        let isHiddenUnroutedContentStop =
            !revealed
            && snapshot.hasNode
            && snapshot.routeState == .none
            && snapshot.previewState == .none

        cell.hiddenArtworkSpriteNode.texture =
            isHiddenUnroutedContentStop
            ? purplePiedPiperTexture
            : hiddenCardBackTexture

        // Colored Piper assets already contain their intended RGB values.
        // Preserve purple on undiscovered content stops; neutral empty backs
        // keep the subtle white tint used by the ordinary card back.
        cell.hiddenArtworkSpriteNode.colorBlendFactor =
            isHiddenUnroutedContentStop
            ? 0
            : 1

        cell.hiddenArtworkSpriteNode.alpha =
            isHiddenUnroutedContentStop
            ? 0.88
            : 0.32


        if revealed {

            cell.cardNode.fillColor =
                MapVisualTheme.tileRevealedFillColor

            cell.faceBorderNode.strokeColor =
                MapVisualTheme.tileRevealedBorderColor

        } else {

            cell.cardNode.fillColor =
                MapVisualTheme.tileHiddenFillColor

            cell.faceBorderNode.strokeColor =
                MapVisualTheme.tileHiddenBorderColor
        }


        // Pass 5.17: committed path cards are intentionally borderless so we
        // can evaluate the cleaner card + arrow visual hierarchy. Preview
        // states keep their temporary planning borders.
        let isBorderlessCommittedPathCard =
            snapshot.previewState == .none
            && snapshot.routeState != .none

        cell.faceBorderNode.isHidden =
            isBorderlessCommittedPathCard


        // Multiple GameNodes at one time/progress point are now a visible
        // deck. Two nodes expose one back edge; three or more expose two.
        // No numeric badge is needed because the stack itself communicates it.
        let stackedNodeCount =
            snapshot.nodePreviews.count

        cell.stackBackOneNode.isHidden =
            stackedNodeCount < 2

        cell.stackBackTwoNode.isHidden =
            stackedNodeCount < 3

        let stackFillColor =
            revealed
            ? MapVisualTheme.tileRevealedFillColor
            : MapVisualTheme.tileHiddenFillColor

        let stackStrokeColor =
            revealed
            ? MapVisualTheme.tileRevealedBorderColor
            : MapVisualTheme.tileHiddenBorderColor

        cell.stackBackOneNode.fillColor = stackFillColor
        cell.stackBackTwoNode.fillColor = stackFillColor
        cell.stackBackOneNode.strokeColor =
            isBorderlessCommittedPathCard
            ? .clear
            : stackStrokeColor
        cell.stackBackTwoNode.strokeColor =
            isBorderlessCommittedPathCard
            ? .clear
            : stackStrokeColor


        if let node =
            snapshot.primaryNodePreview {

            cell.emptyTimeLabel.isHidden = true
            cell.emptyArtworkSpriteNode.isHidden = true
            cell.emptyProgressLabel.isHidden = true
            cell.emptyAddStopLabel.isHidden = true

            cell.titleLabel.isHidden = false
            cell.timeLabel.isHidden = false

            cell.titleLabel.fontSize =
                11.25

            cell.titleLabel.position =
                CGPoint(
                    x: 0,
                    y: -tileSize * 0.275
                )

            cell.titleLabel.text =
                fitted(
                    node.title,
                    maximumCharacters: 15
                )

            cell.timeLabel.text =
                node.time.displayClockString

            cell.routeGlyphLabel.isHidden =
                true

            cell.routeArtworkSpriteNode.isHidden =
                true
            cell.routeArtworkSpriteNode.texture = nil

            if revealed {

                cell.artworkCropNode.isHidden =
                    false

                applyArtwork(
                    node,
                    previousNode:
                        previousSnapshot?
                            .primaryNodePreview,
                    to: cell
                )

            } else {

                cancelArtworkTask(
                    for: cell
                )

                cell.artworkCropNode.isHidden =
                    true

            }

        } else {

            cancelArtworkTask(
                for: cell
            )

            cell.artworkCropNode.isHidden =
                true

            // Empty revealed cards now have a full stop-discovery face rather
            // than a route-state glyph. The original neutral Pied Piper image
            // is used for every empty stop, including empty cells on a path.
            cell.titleLabel.text =
                ""
            cell.titleLabel.isHidden =
                true

            cell.timeLabel.text =
                ""
            cell.timeLabel.isHidden =
                true

            cell.routeArtworkSpriteNode.isHidden =
                true
            cell.routeArtworkSpriteNode.texture =
                nil

            cell.routeGlyphLabel.isHidden =
                true

            let emptyFaceVisible =
                revealed

            cell.emptyTimeLabel.isHidden =
                !emptyFaceVisible
            cell.emptyArtworkSpriteNode.isHidden =
                !emptyFaceVisible
            cell.emptyProgressLabel.isHidden =
                !emptyFaceVisible
            cell.emptyAddStopLabel.isHidden =
                !emptyFaceVisible

            if emptyFaceVisible {

                let coordinate =
                    GridMapGeometry
                        .mapCoordinateAtTileCenter(
                            for: snapshot.id
                        )

                cell.emptyTimeLabel.text =
                    coordinate.time.displayClockString

                cell.emptyArtworkSpriteNode.texture =
                    hiddenCardBackTexture

                let delta =
                    snapshot.potentialProgressDeltaPercent
                    ?? 0

                cell.emptyProgressLabel.text =
                    progressDeltaText(
                        delta
                    )

                cell.emptyProgressLabel.fontColor =
                    progressDeltaColor(
                        delta
                    )

                cell.emptyAddStopLabel.text =
                    "Add Stop"
            }
        }


        // Legacy count badge stays retired; stackBackOne/Two provide the
        // multiple-card affordance instead.
        cell.collisionBadgeNode.isHidden = true
        cell.collisionLabel.isHidden = true
        cell.collisionLabel.text = ""


        applyRouteStyle(
            snapshot,
            to: cell
        )


        cell.selectionBorderNode.isHidden =
            !snapshot.isSelected
            || isBorderlessCommittedPathCard

        cell.shadowNode.alpha =
            snapshot.isSelected
            ? 0.98
            : 1

        applyCurrentTimeDecorations(
            snapshot,
            to: cell
        )
    }


    private func applyCurrentTimeEmphasis(
        _ snapshot: DayMapTileSnapshot,
        to cell: RenderedCell,
        animated: Bool
    ) {

        applyCurrentTimeDecorations(
            snapshot,
            to: cell
        )

        let targetScale =
            visualScale(
                for: snapshot
            )

        cell.rootNode.zPosition =
            snapshot.isCurrentRouteBoundary
            ? 90
            : (targetScale > 1 ? 70 : 0)

        cell.rootNode.removeAction(
            forKey: "currentHourScale"
        )

        if animated {

            cell.rootNode.run(
                .scale(
                    to: targetScale,
                    duration: 0.22
                ),
                withKey: "currentHourScale"
            )

        } else {

            cell.rootNode.setScale(
                targetScale
            )
        }
    }


    private func applyCurrentTimeDecorations(
        _ snapshot: DayMapTileSnapshot,
        to cell: RenderedCell
    ) {

        // Pass 5.60.3: all per-tile current-position decoration is disabled.
        // CurrentTimeRenderer owns the single live label so it can sit at the
        // exact semantic current time instead of inheriting a route tile's Y.
        cell.boundaryHaloNode.isHidden =
            true

        cell.boundaryNode.isHidden =
            true

        cell.boundaryBadgeNode.isHidden =
            true

        cell.boundaryBadgeLabel.isHidden =
            true

        cell.boundaryBadgeLabel.text =
            nil
    }


    private func visualScale(
        for snapshot: DayMapTileSnapshot
    ) -> CGFloat {

        guard snapshot.hasNode else {
            return 1
        }

        let currentHour =
            hourIndex(
                for: currentDayTime
            )

        let containsCurrentHourStop =
            snapshot.nodePreviews.contains { preview in
                hourIndex(
                    for: preview.time
                ) == currentHour
            }

        return containsCurrentHourStop
            ? Self.currentHourStopScale
            : 1
    }


    private func hourIndex(
        for time: DayTime
    ) -> Int {

        min(
            23,
            max(
                0,
                Int(
                    time.secondsFromMidnight
                    / DayTime.secondsPerHour
                )
            )
        )
    }


    private func applyRouteStyle(
        _ snapshot: DayMapTileSnapshot,
        to cell: RenderedCell
    ) {

        cell.routeBorderNode.isHidden = false
        cell.routeBorderNode.glowWidth = 0
        cell.routePatternNode.isHidden = true
        cell.routePatternNode.texture = nil
        cell.routePatternNode.alpha = 1

        cell.routeTintNode.isHidden = false
        cell.routeTintNode.fillColor = .clear

        cell.routeGlyphLabel.fontColor =
            MapVisualTheme.tileRouteGlyphColor


        switch snapshot.previewState {

        case .selected:

            cell.routeBorderNode.strokeColor =
                RouteVisualTheme.previewSelectedColor

            cell.routeBorderNode.lineWidth = 3.5
            cell.routeBorderNode.glowWidth = 1.25

            cell.routeTintNode.fillColor =
                RouteVisualTheme
                    .previewSelectedColor
                    .withAlphaComponent(0.055)

            cell.routeGlyphLabel.fontColor =
                RouteVisualTheme.previewSelectedColor
                    .withAlphaComponent(0.82)

            return


        case .alternative:

            applyStripedRouteBorder(
                to: cell,
                primary: RouteVisualTheme.alternativeColor,
                secondary: .white,
                cacheKey: "preview-alternative",
                alpha: 0.70,
                borderWidth: 5.0
            )

            cell.routeTintNode.fillColor =
                RouteVisualTheme
                    .alternativeColor
                    .withAlphaComponent(0.018)

            cell.routeGlyphLabel.fontColor =
                RouteVisualTheme.alternativeColor
                    .withAlphaComponent(0.82)

            return


        case .none:
            break
        }


        switch snapshot.routeState {

        case .none:

            cell.routeBorderNode.isHidden = true
            cell.routePatternNode.isHidden = true
            cell.routeTintNode.isHidden = true

        case .completed:

            // Pass 5.17: completed path cards have no persistent perimeter.
            cell.routeBorderNode.isHidden = true
            cell.routePatternNode.isHidden = true

            cell.routeTintNode.fillColor =
                RouteVisualTheme
                    .completedColor
                    .withAlphaComponent(0.045)

            cell.routeGlyphLabel.fontColor =
                RouteVisualTheme.completedColor
                    .withAlphaComponent(0.88)


        case .chosen:

            // Pass 5.17: chosen path cards have no persistent perimeter.
            cell.routeBorderNode.isHidden = true
            cell.routePatternNode.isHidden = true

            cell.routeTintNode.fillColor =
                RouteVisualTheme
                    .chosenColor
                    .withAlphaComponent(0.025)

            cell.routeGlyphLabel.fontColor =
                RouteVisualTheme.chosenColor
                    .withAlphaComponent(0.92)


        case .alternative:

            // Pass 5.17: selected/focused alternate path cards also have no
            // persistent perimeter. The orange Piper artwork, tint, and path
            // arrows continue to carry the alternate-state identity.
            cell.routeBorderNode.isHidden = true
            cell.routePatternNode.isHidden = true

            cell.routeTintNode.fillColor =
                RouteVisualTheme
                    .alternativeColor
                    .withAlphaComponent(0.020)

            cell.routeGlyphLabel.fontColor =
                RouteVisualTheme.alternativeColor
                    .withAlphaComponent(0.94)
        }
    }


    private func applyStripedRouteBorder(
        to cell: RenderedCell,
        primary: SKColor,
        secondary: SKColor,
        cacheKey: String,
        alpha: CGFloat,
        borderWidth: CGFloat
    ) {

        cell.routeBorderNode.isHidden = true
        cell.routePatternNode.isHidden = false
        cell.routePatternNode.alpha = alpha
        cell.routePatternNode.texture =
            stripedRouteBorderTexture(
                primary: primary,
                secondary: secondary,
                cacheKey: cacheKey,
                borderWidth: borderWidth
            )
    }

    func emptyRouteCardTexture(
        for snapshot: DayMapTileSnapshot
    ) -> SKTexture? {

        guard !snapshot.hasNode else {
            return nil
        }

        switch snapshot.routeState {

        case .completed,
             .chosen:
            return greenPiedPiperTexture

        case .alternative:
            return orangePiedPiperTexture

        case .none:
            return nil
        }
    }



    func stripedRouteBorderTexture(
        primary: SKColor,
        secondary: SKColor,
        cacheKey: String,
        borderWidth: CGFloat
    ) -> SKTexture {

        let textureKey =
            "tile-route-stripes:\(cacheKey):\(Int(tileSize * 100)):\(Int(cornerRadius * 100)):\(Int(borderWidth * 100))"

        if let cached = routePatternTextureCache[textureKey] {
            return cached
        }

        let size =
            CGSize(
                width: tileSize + 5,
                height: tileSize + 5
            )

        let rendererFormat =
            UIGraphicsImageRendererFormat.default()

        rendererFormat.opaque = false
        rendererFormat.scale = 2

        let renderer =
            UIGraphicsImageRenderer(
                size: size,
                format: rendererFormat
            )

        let image = renderer.image { context in

            let bounds =
                CGRect(
                    origin: .zero,
                    size: size
                )

            let outerRect =
                bounds.insetBy(
                    dx: 1.5,
                    dy: 1.5
                )

            let outer =
                UIBezierPath(
                    roundedRect: outerRect,
                    cornerRadius: cornerRadius + 2.5
                )

            let inner =
                UIBezierPath(
                    roundedRect:
                        outerRect.insetBy(
                            dx: borderWidth,
                            dy: borderWidth
                        ),
                    cornerRadius:
                        max(
                            1,
                            cornerRadius - 1.5
                        )
                )

            let ring = UIBezierPath()
            ring.append(outer)
            ring.append(inner)
            ring.usesEvenOddFillRule = true

            context.cgContext.addPath(ring.cgPath)
            context.cgContext.clip(using: .evenOdd)

            secondary.setFill()
            context.cgContext.fill(bounds)

            // Diagonal alternating bands read as stripes at both the normal
            // and zoomed-out map scales from the device screenshots.
            let stripeWidth: CGFloat = 7
            var x = -size.height

            primary.setFill()

            while x < size.width + size.height {

                let stripe = UIBezierPath()

                stripe.move(
                    to: CGPoint(
                        x: x,
                        y: 0
                    )
                )

                stripe.addLine(
                    to: CGPoint(
                        x: x + stripeWidth,
                        y: 0
                    )
                )

                stripe.addLine(
                    to: CGPoint(
                        x: x + stripeWidth + size.height,
                        y: size.height
                    )
                )

                stripe.addLine(
                    to: CGPoint(
                        x: x + size.height,
                        y: size.height
                    )
                )

                stripe.close()
                stripe.fill()

                x += stripeWidth * 2
            }
        }

        let texture = SKTexture(image: image)
        texture.filteringMode = .linear

        routePatternTextureCache[textureKey] = texture
        return texture
    }


    func progressDeltaText(
        _ value: Double
    ) -> String {

        let roundedToTenth =
            (value * 10).rounded() / 10

        let absolute =
            abs(roundedToTenth)

        let numberText: String

        if abs(absolute.rounded() - absolute) < 0.001 {
            numberText = String(Int(absolute.rounded()))
        } else {
            numberText = String(format: "%.1f", absolute)
        }

        if roundedToTenth > 0 {
            return "+\(numberText)%"
        }

        if roundedToTenth < 0 {
            return "−\(numberText)%"
        }

        return "0%"
    }


    func progressDeltaColor(
        _ value: Double
    ) -> SKColor {

        if value > 0.05 {
            return RouteVisualTheme.completedColor
        }

        if value < -0.05 {
            return SKColor.systemRed
        }

        return MapVisualTheme.tileSecondaryTextColor
    }


    func fitted(
        _ text: String,
        maximumCharacters: Int
    ) -> String {

        let cleaned =
            text
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )


        guard cleaned.count > maximumCharacters else {
            return cleaned
        }


        let end =
            cleaned.index(
                cleaned.startIndex,
                offsetBy:
                    max(
                        1,
                        maximumCharacters - 1
                    )
            )


        return String(
            cleaned[..<end]
        )
        + "…"
    }
}


// =====================================================
// MARK: - Revealed Card Artwork
// =====================================================

private extension MapGridRenderer {

    private func applyArtwork(
        _ node: DayMapTileNodePreview,
        previousNode: DayMapTileNodePreview?,
        to cell: RenderedCell
    ) {

        guard let cellID = cell.cellID else {
            return
        }

        let sourceChanged =
            previousNode?.artworkSource
            != node.artworkSource
            || previousNode?.nodeID
            != node.nodeID

        if !sourceChanged,
           cell.artworkSpriteNode.texture != nil
        {
            return
        }

        remoteImageTasks[cellID]?.cancel()
        remoteImageTasks[cellID] = nil

        // Always establish an immediate type-specific texture. Asset or
        // network artwork replaces it only after it has been validated.
        apply(
            texture:
                placeholderTexture(
                    for: node.kind
                ),
            to: cell.artworkSpriteNode
        )


        switch node.artworkSource {

        case let .placeholder(kind):

            apply(
                texture:
                    placeholderTexture(
                        for: kind
                    ),
                to: cell.artworkSpriteNode
            )


        case let .asset(name):

            guard let texture =
                localAssetTexture(
                    named: name
                )
            else {
                return
            }

            apply(
                texture: texture,
                to: cell.artworkSpriteNode
            )


        case let .remote(urlString):

            loadRemoteArtwork(
                urlString: urlString,
                cellID: cellID,
                nodeID: node.nodeID,
                sprite: cell.artworkSpriteNode
            )
        }
    }


    private func cancelArtworkTask(
        for cell: RenderedCell
    ) {

        guard let cellID = cell.cellID else {
            return
        }

        remoteImageTasks[cellID]?.cancel()
        remoteImageTasks[cellID] = nil
    }


    func placeholderTexture(
        for kind: GameNodeKind
    ) -> SKTexture {

        let cacheKey =
            "tile-placeholder:\(kind.rawValue)"

        if let cached = textureCache[cacheKey] {
            return cached
        }

        let texture =
            SKTexture(
                image:
                    GameNodePlaceholderImage.image(
                        for: kind,
                        size: 160
                    )
            )

        texture.filteringMode =
            .linear

        textureCache[cacheKey] =
            texture

        return texture
    }


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

        let cacheKey =
            "tile-asset:\(trimmed)"

        if let cached = textureCache[cacheKey] {
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

        textureCache[cacheKey] =
            texture

        return texture
    }


    func loadRemoteArtwork(
        urlString: String,
        cellID: GridCellID,
        nodeID: GameNodeID,
        sprite: SKSpriteNode
    ) {

        let trimmed =
            urlString.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        let cacheKey =
            "tile-remote:\(trimmed)"

        if let cached = textureCache[cacheKey] {

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

        remoteImageTasks[cellID]?.cancel()

        let task =
            Task { @MainActor [weak self, weak sprite] in

                guard let self else {
                    return
                }

                defer {
                    self.remoteImageTasks[cellID] = nil
                }

                do {

                    let (data, response) =
                        try await URLSession.shared.data(
                            from: url
                        )

                    guard !Task.isCancelled else {
                        return
                    }

                    if let httpResponse =
                        response as? HTTPURLResponse
                    {
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
                        let sprite,
                        let renderedCell =
                            self.renderedCells[cellID],
                        renderedCell.artworkSpriteNode === sprite,
                        renderedCell.lastSnapshot?
                            .primaryNodeID == nodeID
                    else {
                        return
                    }

                    self.apply(
                        texture: texture,
                        to: sprite
                    )

                } catch {
                    // The type-specific placeholder intentionally remains.
                }
            }

        remoteImageTasks[cellID] =
            task
    }


    func apply(
        texture: SKTexture,
        to sprite: SKSpriteNode
    ) {

        sprite.texture =
            texture

        let sourceSize =
            texture.size()

        guard
            sourceSize.width > 0,
            sourceSize.height > 0
        else {

            sprite.size =
                CGSize(
                    width: artworkSize,
                    height: artworkSize
                )

            return
        }

        // Aspect-fill the rounded-square crop without distorting source media.
        let scale =
            max(
                artworkSize / sourceSize.width,
                artworkSize / sourceSize.height
            )

        sprite.size =
            CGSize(
                width: sourceSize.width * scale,
                height: sourceSize.height * scale
            )
    }
}


// =====================================================
// MARK: - Visible World Rect
// =====================================================

private extension MapGridRenderer {

    static func worldRectVisibleInView(
        scene: SKScene,
        view: SKView
    ) -> CGRect {

        let bounds =
            view.bounds


        let points = [
            CGPoint(x: bounds.minX, y: bounds.minY),
            CGPoint(x: bounds.maxX, y: bounds.minY),
            CGPoint(x: bounds.minX, y: bounds.maxY),
            CGPoint(x: bounds.maxX, y: bounds.maxY)
        ]
        .map {
            scene.convertPoint(
                fromView: $0
            )
        }


        guard
            let first = points.first
        else {
            return .zero
        }


        var minX = first.x
        var maxX = first.x
        var minY = first.y
        var maxY = first.y


        for point in points.dropFirst() {

            minX = min(minX, point.x)
            maxX = max(maxX, point.x)
            minY = min(minY, point.y)
            maxY = max(maxY, point.y)
        }


        return CGRect(
            x: minX,
            y: minY,
            width: maxX - minX,
            height: maxY - minY
        )
    }
}
