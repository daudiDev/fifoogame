//
//  MapGridRenderer.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/22/26.
//

import SpriteKit


@MainActor
final class MapGridRenderer {

    // =====================================================
    // MARK: - Container / Layers
    // =====================================================

    let containerNode = SKNode()

    private let islandShadowLayer = SKNode()
    private let islandLayer = SKNode()
    private let roadMarkingLayer = SKNode()


    // =====================================================
    // MARK: - Visible Region State
    // =====================================================

    private(set) var visibleWorldRect: CGRect = .zero
    private(set) var visibleRegion: GridVisibleRegion?


    private struct ViewportSignature: Equatable {

        let cameraPosition: CGPoint
        let cameraXScale: CGFloat
        let cameraYScale: CGFloat
        let cameraRotation: CGFloat
        let viewBounds: CGRect
    }


    private var lastViewportSignature: ViewportSignature?


    // =====================================================
    // MARK: - Rendered Cell State
    // =====================================================

    private final class RenderedCell {

        let shadowNode: SKShapeNode
        let islandNode: SKNode
        let roadMarkingNode: SKNode
        let bottomBoundaryNode: SKShapeNode

        init(
            shadowNode: SKShapeNode,
            islandNode: SKNode,
            roadMarkingNode: SKNode,
            bottomBoundaryNode: SKShapeNode
        ) {

            self.shadowNode = shadowNode
            self.islandNode = islandNode
            self.roadMarkingNode = roadMarkingNode
            self.bottomBoundaryNode = bottomBoundaryNode
        }
    }


    private var renderedCells: [GridCellID: RenderedCell] = [:]

    /// Cells are removed from the world when they leave the buffered region,
    /// but their SpriteKit nodes are retained here for reuse on the next pan.
    /// This prevents repeated SKShapeNode/CGPath allocation during long map
    /// navigation sessions.
    private var recycledCells: [RenderedCell] = []

    private let maximumRecycledCellCount = 96


    // =====================================================
    // MARK: - Cached Local Geometry
    // =====================================================

    /// All grid cells have identical geometry. Paths are therefore created
    /// once in local cell space and each rendered cell is positioned at its
    /// deterministic world-space street intersection.
    private lazy var cachedIslandPath: CGPath =
        makeLocalIslandPath()

    private lazy var cachedShadowPath: CGPath =
        makeLocalShadowPath()

    private lazy var cachedPrimaryRoadMarkingPath: CGPath =
        makeLocalPrimaryRoadMarkingPath()

    private lazy var cachedBottomBoundaryPath: CGPath =
        makeLocalBottomBoundaryPath()


    // =====================================================
    // MARK: - Init
    // =====================================================

    init() {

        containerNode.name =
            "cartesianGridMap"

        containerNode.isUserInteractionEnabled =
            false

        configureLayerHierarchy()
    }


    // =====================================================
    // MARK: - Build / Reset
    // =====================================================

    /// Clears currently rendered cells while preserving reusable nodes and
    /// cached immutable geometry.
    func rebuild() {

        recycleAllRenderedCells()

        visibleWorldRect = .zero
        visibleRegion = nil
        lastViewportSignature = nil
    }


    // =====================================================
    // MARK: - Camera Region Tracking
    // =====================================================

    /// Recalculates which deterministic grid cells are needed around the
    /// current camera and synchronizes SpriteKit content only if the camera
    /// transform or view bounds changed.
    ///
    /// - Returns: `true` only when the actual buffered cell range changed.
    @discardableResult
    func updateVisibleRegion(
        scene: SKScene,
        view: SKView
    ) -> Bool {

        let camera = scene.camera

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


        // A stationary camera is by far the common case. Skip all view-to-
        // scene corner conversions when nothing affecting visibility moved.
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


        let regionChanged =
            nextRegion != visibleRegion


        visibleWorldRect =
            nextWorldRect


        guard regionChanged else {
            return false
        }


        visibleRegion =
            nextRegion


        synchronizeRenderedCells(
            to: nextRegion
        )


        return true
    }


    // =====================================================
    // MARK: - Diagnostics / Convenience
    // =====================================================

    var visibleCellIDs: [GridCellID] {

        visibleRegion?.cellIDs
        ?? []
    }


    var renderedCellCount: Int {
        renderedCells.count
    }


    var recycledCellCount: Int {
        recycledCells.count
    }
}


// =====================================================
// MARK: - Layer Hierarchy
// =====================================================

private extension MapGridRenderer {

    func configureLayerHierarchy() {

        containerNode.removeAllChildren()


        islandShadowLayer.name =
            "cartesianGridMap.islandShadows"

        islandLayer.name =
            "cartesianGridMap.islands"

        roadMarkingLayer.name =
            "cartesianGridMap.roadMarkings"


        islandShadowLayer.zPosition = 0
        islandLayer.zPosition = 10
        roadMarkingLayer.zPosition = 20


        islandShadowLayer.isUserInteractionEnabled = false
        islandLayer.isUserInteractionEnabled = false
        roadMarkingLayer.isUserInteractionEnabled = false


        containerNode.addChild(
            islandShadowLayer
        )

        containerNode.addChild(
            islandLayer
        )

        containerNode.addChild(
            roadMarkingLayer
        )
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
            Set(
                region.cellIDs
            )


        // First recycle cells outside the new buffered camera range. Their
        // nodes can then immediately be reused for cells entering opposite
        // edges during the same pan update.
        for id in Array(renderedCells.keys) {

            guard !desiredIDs.contains(id) else {
                continue
            }

            recycleRenderedCell(
                id
            )
        }


        // Add only newly required cells. Existing visible nodes remain where
        // they are, which keeps panning stable and allocation-light.
        for id in desiredIDs {

            guard renderedCells[id] == nil else {
                continue
            }

            addRenderedCell(
                id
            )
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


        islandShadowLayer.addChild(
            cell.shadowNode
        )

        islandLayer.addChild(
            cell.islandNode
        )

        roadMarkingLayer.addChild(
            cell.roadMarkingNode
        )


        renderedCells[id] =
            cell
    }


   private func configure(
        _ cell: RenderedCell,
        for id: GridCellID
    ) {

        let origin =
            GridMapGeometry
                .cellOrigin(
                    for: id
                )


        cell.shadowNode.position =
            origin

        cell.islandNode.position =
            origin

        cell.roadMarkingNode.position =
            origin


        cell.shadowNode.name =
            "gridIslandShadow.\(id.column).\(id.row)"

        cell.islandNode.name =
            "gridIsland.\(id.column).\(id.row)"

        cell.roadMarkingNode.name =
            "gridRoadMarkings.\(id.column).\(id.row)"


        // The final rendered row also owns the lower 24:00 street boundary.
        cell.bottomBoundaryNode.isHidden =
            id.row
            != GridMapConfiguration.maximumDayRow
    }


    func recycleRenderedCell(
        _ id: GridCellID
    ) {

        guard
            let cell =
                renderedCells
                    .removeValue(
                        forKey: id
                    )
        else {
            return
        }


        cell.shadowNode.removeFromParent()
        cell.islandNode.removeFromParent()
        cell.roadMarkingNode.removeFromParent()


        guard
            recycledCells.count
            < maximumRecycledCellCount
        else {
            return
        }


        recycledCells.append(
            cell
        )
    }


    func recycleAllRenderedCells() {

        for id in Array(renderedCells.keys) {
            recycleRenderedCell(id)
        }
    }
}


// =====================================================
// MARK: - Reusable Cell Creation
// =====================================================

private extension MapGridRenderer {

   private func makeRenderedCell() -> RenderedCell {

        let shadowNode =
            SKShapeNode(
                path: cachedShadowPath
            )

        shadowNode.fillColor =
            MapVisualTheme.islandShadowColor

        shadowNode.strokeColor =
            .clear

        shadowNode.lineWidth =
            0

        shadowNode.isAntialiased =
            true

        shadowNode.isUserInteractionEnabled =
            false


        // -------------------------------------------------
        // Island fill + thin border
        // -------------------------------------------------

        let islandRoot = SKNode()
        islandRoot.isUserInteractionEnabled = false


        let fillNode =
            SKShapeNode(
                path: cachedIslandPath
            )

        fillNode.fillColor =
            MapVisualTheme.islandFillColor

        fillNode.strokeColor =
            .clear

        fillNode.lineWidth =
            0

        fillNode.isAntialiased =
            true

        fillNode.isUserInteractionEnabled =
            false


        let borderNode =
            SKShapeNode(
                path: cachedIslandPath
            )

        borderNode.fillColor =
            .clear

        borderNode.strokeColor =
            MapVisualTheme.islandBorderColor

        borderNode.lineWidth =
            GridMapConfiguration.islandBorderWidthWorld

        borderNode.lineJoin =
            .round

        borderNode.isAntialiased =
            true

        borderNode.isUserInteractionEnabled =
            false


        islandRoot.addChild(
            fillNode
        )

        islandRoot.addChild(
            borderNode
        )


        // -------------------------------------------------
        // Road markings
        // -------------------------------------------------

        let markingRoot = SKNode()
        markingRoot.isUserInteractionEnabled = false


        let primaryMarkings =
            makeDashShapeNode(
                path: cachedPrimaryRoadMarkingPath
            )


        let bottomBoundary =
            makeDashShapeNode(
                path: cachedBottomBoundaryPath
            )

        bottomBoundary.isHidden =
            true


        markingRoot.addChild(
            primaryMarkings
        )

        markingRoot.addChild(
            bottomBoundary
        )


        return RenderedCell(
            shadowNode: shadowNode,
            islandNode: islandRoot,
            roadMarkingNode: markingRoot,
            bottomBoundaryNode: bottomBoundary
        )
    }
}


// =====================================================
// MARK: - Cached Local Geometry
// =====================================================

private extension MapGridRenderer {

    var localIslandRect: CGRect {

        let halfRoad =
            GridMapConfiguration
                .roadHalfWidthWorld

        let islandSize =
            GridMapConfiguration
                .islandSizeWorld


        return CGRect(
            x: halfRoad,
            y:
                -halfRoad
                - islandSize,
            width: islandSize,
            height: islandSize
        )
    }


    func makeLocalIslandPath() -> CGPath {

        CGPath(
            roundedRect: localIslandRect,
            cornerWidth:
                GridMapConfiguration
                    .islandCornerRadiusWorld,
            cornerHeight:
                GridMapConfiguration
                    .islandCornerRadiusWorld,
            transform: nil
        )
    }


    func makeLocalShadowPath() -> CGPath {

        let shadowRect =
            localIslandRect
                .offsetBy(
                    dx:
                        GridMapConfiguration
                            .islandShadowOffsetXWorld,
                    dy:
                        -GridMapConfiguration
                            .islandShadowOffsetYWorld
                )


        return CGPath(
            roundedRect: shadowRect,
            cornerWidth:
                GridMapConfiguration
                    .islandCornerRadiusWorld,
            cornerHeight:
                GridMapConfiguration
                    .islandCornerRadiusWorld,
            transform: nil
        )
    }


    /// Top + left road sections owned by every cell.
    func makeLocalPrimaryRoadMarkingPath() -> CGPath {

        let pitch =
            GridMapConfiguration
                .cellPitchWorld


        let path =
            CGMutablePath()


        appendHorizontalDashes(
            to: path,
            fromX: 0,
            toX: pitch,
            y: 0
        )


        appendVerticalDashes(
            to: path,
            x: 0,
            fromY: 0,
            toY: -pitch
        )


        return path
    }


    /// Only cells in the final day row reveal this path.
    func makeLocalBottomBoundaryPath() -> CGPath {

        let pitch =
            GridMapConfiguration
                .cellPitchWorld


        let path =
            CGMutablePath()


        appendHorizontalDashes(
            to: path,
            fromX: 0,
            toX: pitch,
            y: -pitch
        )


        return path
    }
}


// =====================================================
// MARK: - Road Marking Path Helpers
// =====================================================

private extension MapGridRenderer {

    func makeDashShapeNode(
        path: CGPath
    ) -> SKShapeNode {

        let node =
            SKShapeNode(
                path: path
            )


        node.fillColor =
            .clear

        node.strokeColor =
            MapVisualTheme.roadDashColor
        

        node.lineWidth =
            GridMapConfiguration.roadDashLineWidthWorld

        node.lineCap =
            .round

        node.lineJoin =
            .round

        node.isAntialiased =
            true

        node.isUserInteractionEnabled =
            false


        return node
    }


    func appendHorizontalDashes(
        to path: CGMutablePath,
        fromX startX: CGFloat,
        toX endX: CGFloat,
        y: CGFloat
    ) {

        let centers =
            dashCenters(
                start: startX,
                end: endX
            )


        let halfLength =
            GridMapConfiguration
                .roadDashLengthWorld
            / 2


        for centerX in centers {

            path.move(
                to:
                    CGPoint(
                        x: centerX - halfLength,
                        y: y
                    )
            )

            path.addLine(
                to:
                    CGPoint(
                        x: centerX + halfLength,
                        y: y
                    )
            )
        }
    }


    func appendVerticalDashes(
        to path: CGMutablePath,
        x: CGFloat,
        fromY startY: CGFloat,
        toY endY: CGFloat
    ) {

        let centers =
            dashCenters(
                start:
                    min(
                        startY,
                        endY
                    ),
                end:
                    max(
                        startY,
                        endY
                    )
            )


        let halfLength =
            GridMapConfiguration
                .roadDashLengthWorld
            / 2


        for centerY in centers {

            path.move(
                to:
                    CGPoint(
                        x: x,
                        y: centerY - halfLength
                    )
            )

            path.addLine(
                to:
                    CGPoint(
                        x: x,
                        y: centerY + halfLength
                    )
            )
        }
    }


    /// Produces sparse dash centers while keeping a clean zone around each
    /// intersection, matching the simplified visual reference.
    func dashCenters(
        start: CGFloat,
        end: CGFloat
    ) -> [CGFloat] {

        let low =
            min(
                start,
                end
            )

        let high =
            max(
                start,
                end
            )


        let clearance =
            GridMapConfiguration
                .roadIntersectionClearanceWorld


        let usableStart =
            low + clearance

        let usableEnd =
            high - clearance


        guard usableEnd > usableStart else {
            return []
        }


        let count =
            max(
                1,
                GridMapConfiguration
                    .roadDashCountPerSegment
            )


        let spacing =
            (usableEnd - usableStart)
            / CGFloat(count + 1)


        return (1 ... count).map {

            usableStart
            + CGFloat($0)
            * spacing
        }
    }
}


// =====================================================
// MARK: - View -> World Rectangle
// =====================================================

private extension MapGridRenderer {

    /// Converts UIKit view corners into scene/world coordinates. Using
    /// SpriteKit's own conversion keeps this correct for zoom, aspect-fit,
    /// anchor point, panning, and different device sizes.
    static func worldRectVisibleInView(
        scene: SKScene,
        view: SKView
    ) -> CGRect {

        let bounds =
            view.bounds


        let viewCorners = [
            CGPoint(
                x: bounds.minX,
                y: bounds.minY
            ),
            CGPoint(
                x: bounds.maxX,
                y: bounds.minY
            ),
            CGPoint(
                x: bounds.minX,
                y: bounds.maxY
            ),
            CGPoint(
                x: bounds.maxX,
                y: bounds.maxY
            )
        ]


        let worldCorners =
            viewCorners.map {
                scene.convertPoint(
                    fromView: $0
                )
            }


        guard let first = worldCorners.first else {
            return .zero
        }


        var minimumX = first.x
        var maximumX = first.x
        var minimumY = first.y
        var maximumY = first.y


        for point in worldCorners.dropFirst() {

            minimumX =
                min(
                    minimumX,
                    point.x
                )

            maximumX =
                max(
                    maximumX,
                    point.x
                )

            minimumY =
                min(
                    minimumY,
                    point.y
                )

            maximumY =
                max(
                    maximumY,
                    point.y
                )
        }


        return CGRect(
            x: minimumX,
            y: minimumY,
            width:
                maximumX
                - minimumX,
            height:
                maximumY
                - minimumY
        )
    }
}
