//
//  MapWorldArtRenderer.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/20/26.
//


import SpriteKit
import UIKit


final class MapWorldArtRenderer {

    // =====================================================
    // MARK: - Layers
    // =====================================================

    private let terrainLayer =
        SKNode()

    private let districtLayer =
        SKNode()

    private let districtLabelLayer =
        SKNode()

    private let blockLayer =
        SKNode()

    private let parkLayer =
        SKNode()

    private let buildingShadowLayer =
        SKNode()

    private let buildingLayer =
        SKNode()

    private let vegetationLayer =
        SKNode()

    private let waterLayer =
        SKNode()

    private let roadShadowLayer =
        SKNode()

    private let roadMarkingLayer =
        SKNode()

    private let intersectionLayer =
        SKNode()


    // =====================================================
    // MARK: - State
    // =====================================================

    private var detailLevel:
        MapDetailLevel?


    private var hasAttached =
        false


    // =====================================================
    // MARK: - Attach
    // =====================================================

    func attach(
        to scene: SKScene
    ) {

        guard !hasAttached else {
            return
        }

        hasAttached =
            true


        terrainLayer.name =
            "world.terrain"

        districtLayer.name =
            "world.districts"

        districtLabelLayer.name =
            "world.district-labels"

        blockLayer.name =
            "world.blocks"

        parkLayer.name =
            "world.parks"

        buildingShadowLayer.name =
            "world.building-shadows"

        buildingLayer.name =
            "world.buildings"

        vegetationLayer.name =
            "world.vegetation"

        waterLayer.name =
            "world.water"

        roadShadowLayer.name =
            "world.road-shadows"

        roadMarkingLayer.name =
            "world.road-markings"

        intersectionLayer.name =
            "world.intersections"


        terrainLayer.zPosition =
            MapLayerZ.terrain

        districtLayer.zPosition =
            MapLayerZ.districts

        districtLabelLayer.zPosition =
            MapLayerZ.districts + 10

        blockLayer.zPosition =
            MapLayerZ.blocks

        parkLayer.zPosition =
            MapLayerZ.parks

        buildingShadowLayer.zPosition =
            MapLayerZ.buildingShadows

        buildingLayer.zPosition =
            MapLayerZ.buildings

        vegetationLayer.zPosition =
            MapLayerZ.vegetation

        waterLayer.zPosition =
            MapLayerZ.water

        roadShadowLayer.zPosition =
            MapLayerZ.roadShadows

        roadMarkingLayer.zPosition =
            MapLayerZ.roadMarkings

        intersectionLayer.zPosition =
            MapLayerZ.roadMarkings + 10


        let layers = [
            terrainLayer,
            districtLayer,
            districtLabelLayer,
            blockLayer,
            parkLayer,
            buildingShadowLayer,
            buildingLayer,
            vegetationLayer,
            waterLayer,
            roadShadowLayer,
            roadMarkingLayer,
            intersectionLayer
        ]


        for layer in layers {

            layer.isUserInteractionEnabled =
                false

            scene.addChild(
                layer
            )
        }
    }


    // =====================================================
    // MARK: - Render Static World
    // =====================================================

    func render(
        graph: RoadGraph
    ) {

        clear()


        renderTerrain()

        renderDistricts()

        renderUrbanBlocks()

        renderWater()

        renderRoadShadows(
            graph:
                graph
        )

        renderRoadMarkings(
            graph:
                graph
        )

    }


    // =====================================================
    // MARK: - LOD
    // =====================================================

    func update(
        cameraScale: CGFloat
    ) {

        let newLevel =
            MapDetailLevel.resolve(
                cameraScale:
                    cameraScale
            )


        guard
            newLevel !=
            detailLevel
        else {

            return
        }


        detailLevel =
            newLevel


        switch newLevel {

        case .overview:

            buildingShadowLayer.isHidden =
                true

            buildingLayer.isHidden =
                true

            vegetationLayer.isHidden =
                true

            roadMarkingLayer.isHidden =
                true

            intersectionLayer.isHidden =
                true

            districtLabelLayer.isHidden =
                false


        case .normal:

            buildingShadowLayer.isHidden =
                false

            buildingLayer.isHidden =
                false

            vegetationLayer.isHidden =
                true

            roadMarkingLayer.isHidden =
                false

            intersectionLayer.isHidden =
                true

            districtLabelLayer.isHidden =
                false


        case .detailed:

            buildingShadowLayer.isHidden =
                false

            buildingLayer.isHidden =
                false

            vegetationLayer.isHidden =
                false

            roadMarkingLayer.isHidden =
                false

            intersectionLayer.isHidden =
                false

            districtLabelLayer.isHidden =
                true
        }
    }


    // =====================================================
    // MARK: - Terrain
    // =====================================================

    private func renderTerrain() {

        let texture =
            makeDayNightTexture()


        let sprite =
            SKSpriteNode(
                texture:
                    texture,
                size:
                    CGSize(
                        width:
                            MapVisualWorldBounds.width,
                        height:
                            MapVisualWorldBounds.height
                    )
            )


        sprite.position =
            CGPoint(
                x:
                    (
                        MapVisualWorldBounds.minimumX
                        +
                        MapVisualWorldBounds.maximumX
                    )
                    /
                    2,

                y:
                    -MapVisualWorldBounds.height
                    /
                    2
            )


        texture.filteringMode =
            .linear


        terrainLayer.addChild(
            sprite
        )
    }


    private func makeDayNightTexture()
        -> SKTexture {

        let textureSize =
            CGSize(
                width:
                    64,
                height:
                    768
            )


        let renderer =
            UIGraphicsImageRenderer(
                size:
                    textureSize
            )


        let image =
            renderer.image { context in

                let colors: [CGColor] = [

                    MapWorldPalette
                        .midnight
                        .cgColor,

                    MapWorldPalette
                        .dawn
                        .cgColor,

                    MapWorldPalette
                        .daylight
                        .cgColor,

                    MapWorldPalette
                        .noon
                        .cgColor,

                    MapWorldPalette
                        .daylight
                        .cgColor,

                    MapWorldPalette
                        .sunset
                        .cgColor,

                    MapWorldPalette
                        .lateNight
                        .cgColor
                ]


                let locations: [CGFloat] = [

                    0.00,   // 12 AM
                    0.22,   // dawn
                    0.34,   // morning
                    0.50,   // noon
                    0.67,   // afternoon
                    0.79,   // sunset
                    1.00    // midnight
                ]


                guard let gradient =
                    CGGradient(
                        colorsSpace:
                            CGColorSpaceCreateDeviceRGB(),
                        colors:
                            colors as CFArray,
                        locations:
                            locations
                    )
                else {

                    return
                }


                context
                    .cgContext
                    .drawLinearGradient(
                        gradient,
                        start:
                            CGPoint(
                                x:
                                    textureSize.width / 2,
                                y:
                                    0
                            ),
                        end:
                            CGPoint(
                                x:
                                    textureSize.width / 2,
                                y:
                                    textureSize.height
                            ),
                        options:
                            []
                    )
            }


        return SKTexture(
            image:
                image
        )
    }


    // =====================================================
    // MARK: - Districts
    // =====================================================

    private func renderDistricts() {

        let width =
        MapVisualWorldBounds.width
      

        let height =
            MapWorldConfiguration.height


        let names = [

            "Cedar Quarter",
            "Market District",
            "Central",
            "Garden District",
            "Harbor Quarter"
        ]


        let count =
            names.count


        let districtWidth =
            width
            /
            CGFloat(count)


        for index in
            0 ..< count
        {

            let rect =
                CGRect(
                    x:
                        CGFloat(index)
                        *
                        districtWidth,

                    y:
                        -height,

                    width:
                        districtWidth,

                    height:
                        height
                )


            let overlay =
                SKShapeNode(
                    rect:
                        rect
                )


            let variation =
                CGFloat(index % 2)
                *
                0.012


            overlay.fillColor =
                SKColor(
                    red:
                        0.24 + variation,
                    green:
                        0.31 + variation,
                    blue:
                        0.38 + variation,
                    alpha:
                        0.10
                )


            overlay.strokeColor =
                .clear


            districtLayer.addChild(
                overlay
            )


            for verticalIndex in
                0 ..< 4
            {

                let label =
                    SKLabelNode(
                        fontNamed:
                            "AvenirNext-DemiBold"
                    )


                label.text =
                    names[index]


                label.fontSize =
                    22


                label.fontColor =
                    SKColor(
                        white:
                            1,
                        alpha:
                            0.13
                    )


                label.horizontalAlignmentMode =
                    .center


                label.position =
                    CGPoint(
                        x:
                            rect.midX,
                        y:
                            -300
                            -
                            CGFloat(verticalIndex)
                            *
                            600
                    )


                districtLabelLayer
                    .addChild(
                        label
                    )
            }
        }
    }


    // =====================================================
    // MARK: - City Blocks
    // =====================================================

    private func renderUrbanBlocks() {

        let minX =
            MapVisualWorldBounds.minimumX


        let maxX =
            MapVisualWorldBounds.maximumX


        let worldHeight =
            MapVisualWorldBounds.height


        let cellWidth:
            CGFloat = 138


        let cellHeight:
            CGFloat = 150


        let columns =
            Int(
                ceil(
                    (
                        maxX - minX
                    )
                    /
                    cellWidth
                )
            )


        let rows =
            Int(
                ceil(
                    worldHeight
                    /
                    cellHeight
                )
            )


        for row in
            0 ..< rows
        {

            for column in
                0 ..< columns
            {

                let left =
                    minX
                    +
                    CGFloat(column)
                    *
                    cellWidth


                let top =
                    -CGFloat(row)
                    *
                    cellHeight


                let rect =
                    CGRect(
                        x:
                            left + 9,

                        y:
                            top
                            -
                            cellHeight
                            +
                            9,

                        width:
                            cellWidth - 18,

                        height:
                            cellHeight - 18
                    )


                let parkChance =
                    random01(
                        row,
                        column,
                        7
                    )


                if parkChance <
                    0.115
                {

                    renderPark(
                        rect:
                            rect,
                        row:
                            row,
                        column:
                            column
                    )

                    continue
                }


                renderCityBlock(
                    rect:
                        rect,
                    row:
                        row,
                    column:
                        column
                )
            }
        }
    }


    private func renderCityBlock(
        rect: CGRect,
        row: Int,
        column: Int
    ) {

        let block =
            SKShapeNode(
                rect:
                    rect,
                cornerRadius:
                    8
            )


        block.fillColor =
            (
                row + column
            )
            .isMultiple(of: 2)
            ?
            MapWorldPalette.block
            :
            MapWorldPalette.blockAlternate


        block.strokeColor =
            SKColor(
                white:
                    1,
                alpha:
                    0.035
            )


        block.lineWidth =
            1


        blockLayer.addChild(
            block
        )


        let density =
            random01(
                row,
                column,
                21
            )


        let buildingColumns =
            density > 0.55
            ? 3
            : 2


        let buildingRows =
            density > 0.32
            ? 2
            : 1


        let inner =
            rect.insetBy(
                dx:
                    12,
                dy:
                    12
            )


        let gap:
            CGFloat = 7


        let itemWidth =
            (
                inner.width
                -
                CGFloat(
                    buildingColumns - 1
                )
                *
                gap
            )
            /
            CGFloat(
                buildingColumns
            )


        let itemHeight =
            (
                inner.height
                -
                CGFloat(
                    buildingRows - 1
                )
                *
                gap
            )
            /
            CGFloat(
                buildingRows
            )


        for r in
            0 ..< buildingRows
        {

            for c in
                0 ..< buildingColumns
            {

                let shrink =
                    random01(
                        row * 20 + r,
                        column * 20 + c,
                        83
                    )
                    *
                    5


                let buildingRect =
                    CGRect(
                        x:
                            inner.minX
                            +
                            CGFloat(c)
                            *
                            (
                                itemWidth
                                +
                                gap
                            )
                            +
                            shrink,

                        y:
                            inner.minY
                            +
                            CGFloat(r)
                            *
                            (
                                itemHeight
                                +
                                gap
                            )
                            +
                            shrink,

                        width:
                            max(
                                8,
                                itemWidth
                                -
                                shrink * 2
                            ),

                        height:
                            max(
                                8,
                                itemHeight
                                -
                                shrink * 2
                            )
                    )

                let buildingSeed =
                    row * 10_000
                    +
                    column * 1_000
                    +
                    r * 100
                    +
                    c

                renderBuilding(
                    rect:
                        buildingRect, seed: buildingSeed,
                    alternate:
                        (
                            r
                            +
                            c
                            +
                            row
                            +
                            column
                        )
                        .isMultiple(of: 2)
                )
            }
        }
    }


    // =====================================================
    // MARK: - Buildings
    // =====================================================

    private func renderBuilding(
        rect: CGRect,
        seed: Int,
        alternate: Bool
    ) {

        let path =
            buildingPath(
                in:
                    rect,
                seed:
                    seed
            )


        // Shadow

        let shadow =
            SKShapeNode(
                path:
                    path
            )


        shadow.fillColor =
            MapWorldPalette
                .buildingShadow


        shadow.strokeColor =
            .clear


        shadow.position =
            CGPoint(
                x:
                    2.5,
                y:
                    -3
            )


        buildingShadowLayer
            .addChild(
                shadow
            )


        // Building

        let building =
            SKShapeNode(
                path:
                    path
            )


        building.fillColor =
            alternate
            ?
            MapWorldPalette
                .buildingAlternate
            :
            MapWorldPalette
                .building


        building.strokeColor =
            SKColor(
                white:
                    1,
                alpha:
                    0.08
            )


        building.lineWidth =
            0.7


        buildingLayer.addChild(
            building
        )
    }
    
    private func buildingPath(
        in rect: CGRect,
        seed: Int
    ) -> CGPath {

        let type =
            seed % 6


        switch type {

        // =================================================
        // 0. Standard rectangle
        // =================================================

        case 0:

            return CGPath(
                roundedRect:
                    rect,
                cornerWidth:
                    3,
                cornerHeight:
                    3,
                transform:
                    nil
            )


        // =================================================
        // 1. Narrow rectangle
        // =================================================

        case 1:

            let narrow =
                rect.insetBy(
                    dx:
                        rect.width * 0.18,
                    dy:
                        2
                )


            return CGPath(
                roundedRect:
                    narrow,
                cornerWidth:
                    2,
                cornerHeight:
                    2,
                transform:
                    nil
            )


        // =================================================
        // 2. L-shaped building
        // =================================================

        case 2:

            let path =
                CGMutablePath()


            path.move(
                to:
                    CGPoint(
                        x:
                            rect.minX,
                        y:
                            rect.minY
                    )
            )


            path.addLine(
                to:
                    CGPoint(
                        x:
                            rect.maxX,
                        y:
                            rect.minY
                    )
            )


            path.addLine(
                to:
                    CGPoint(
                        x:
                            rect.maxX,
                        y:
                            rect.midY
                    )
            )


            path.addLine(
                to:
                    CGPoint(
                        x:
                            rect.midX,
                        y:
                            rect.midY
                    )
            )


            path.addLine(
                to:
                    CGPoint(
                        x:
                            rect.midX,
                        y:
                            rect.maxY
                    )
            )


            path.addLine(
                to:
                    CGPoint(
                        x:
                            rect.minX,
                        y:
                            rect.maxY
                    )
            )


            path.closeSubpath()


            return path


        // =================================================
        // 3. U-shaped / courtyard building
        // =================================================

        case 3:

            let path =
                CGMutablePath()


            let inset =
                min(
                    rect.width,
                    rect.height
                )
                *
                0.24


            path.addRect(
                CGRect(
                    x:
                        rect.minX,
                    y:
                        rect.minY,
                    width:
                        rect.width,
                    height:
                        inset
                )
            )


            path.addRect(
                CGRect(
                    x:
                        rect.minX,
                    y:
                        rect.minY,
                    width:
                        inset,
                    height:
                        rect.height
                )
            )


            path.addRect(
                CGRect(
                    x:
                        rect.maxX - inset,
                    y:
                        rect.minY,
                    width:
                        inset,
                    height:
                        rect.height
                )
            )


            return path


        // =================================================
        // 4. Stepped building
        // =================================================

        case 4:

            let path =
                CGMutablePath()


            path.move(
                to:
                    CGPoint(
                        x:
                            rect.minX,
                        y:
                            rect.minY
                    )
            )


            path.addLine(
                to:
                    CGPoint(
                        x:
                            rect.maxX,
                        y:
                            rect.minY
                    )
            )


            path.addLine(
                to:
                    CGPoint(
                        x:
                            rect.maxX,
                        y:
                            rect.midY
                    )
            )


            path.addLine(
                to:
                    CGPoint(
                        x:
                            rect.maxX
                            -
                            rect.width * 0.20,
                        y:
                            rect.midY
                    )
            )


            path.addLine(
                to:
                    CGPoint(
                        x:
                            rect.maxX
                            -
                            rect.width * 0.20,
                        y:
                            rect.maxY
                    )
            )


            path.addLine(
                to:
                    CGPoint(
                        x:
                            rect.minX,
                        y:
                            rect.maxY
                    )
            )


            path.closeSubpath()


            return path


        // =================================================
        // 5. Offset / compact building
        // =================================================

        default:

            let compact =
                CGRect(
                    x:
                        rect.minX
                        +
                        rect.width
                        *
                        0.08,

                    y:
                        rect.minY
                        +
                        rect.height
                        *
                        0.12,

                    width:
                        rect.width
                        *
                        0.78,

                    height:
                        rect.height
                        *
                        0.68
                )


            return CGPath(
                roundedRect:
                    compact,
                cornerWidth:
                    5,
                cornerHeight:
                    5,
                transform:
                    nil
            )
        }
    }


    // =====================================================
    // MARK: - Parks
    // =====================================================

    private func renderPark(
        rect: CGRect,
        row: Int,
        column: Int
    ) {

        let park =
            SKShapeNode(
                rect:
                    rect,
                cornerRadius:
                    14
            )


        park.fillColor =
            MapWorldPalette.park


        park.strokeColor =
            MapWorldPalette.parkEdge


        park.lineWidth =
            1


        parkLayer.addChild(
            park
        )


        let treeCount =
            6
            +
            Int(
                random01(
                    row,
                    column,
                    103
                )
                *
                8
            )


        for index in
            0 ..< treeCount
        {

            let xFraction =
                random01(
                    row,
                    column,
                    200 + index
                )


            let yFraction =
                random01(
                    column,
                    row,
                    300 + index
                )


            let x =
                rect.minX
                +
                10
                +
                xFraction
                *
                (
                    rect.width
                    -
                    20
                )


            let y =
                rect.minY
                +
                10
                +
                yFraction
                *
                (
                    rect.height
                    -
                    20
                )


            let radius =
                2.5
                +
                random01(
                    row,
                    index,
                    column
                )
                *
                2.5


            let treeShadow =
                SKShapeNode(
                    circleOfRadius:
                        radius
                        +
                        1
                )


            treeShadow.fillColor =
                SKColor(
                    blackWithAlpha:
                        0.16
                )


            treeShadow.strokeColor =
                .clear


            treeShadow.position =
                CGPoint(
                    x:
                        x + 1.5,
                    y:
                        y - 1.5
                )


            vegetationLayer
                .addChild(
                    treeShadow
                )


            let tree =
                SKShapeNode(
                    circleOfRadius:
                        radius
                )


            tree.fillColor =
                MapWorldPalette.tree


            tree.strokeColor =
                .clear


            tree.position =
                CGPoint(
                    x:
                        x,
                    y:
                        y
                )


            vegetationLayer
                .addChild(
                    tree
                )
        }
    }


    // =====================================================
    // MARK: - Water
    // =====================================================

    private func renderWater() {

        let width =
        MapVisualWorldBounds.width

        let height =
            MapWorldConfiguration.height


        let path =
            CGMutablePath()


        path.move(
            to:
                CGPoint(
                    x:
                        width * 0.76,
                    y:
                        0
                )
        )


        path.addCurve(
            to:
                CGPoint(
                    x:
                        width * 0.63,
                    y:
                        -height * 0.36
                ),
            control1:
                CGPoint(
                    x:
                        width * 0.62,
                    y:
                        -height * 0.10
                ),
            control2:
                CGPoint(
                    x:
                        width * 0.80,
                    y:
                        -height * 0.24
                )
        )


        path.addCurve(
            to:
                CGPoint(
                    x:
                        width * 0.69,
                    y:
                        -height * 0.68
                ),
            control1:
                CGPoint(
                    x:
                        width * 0.47,
                    y:
                        -height * 0.46
                ),
            control2:
                CGPoint(
                    x:
                        width * 0.78,
                    y:
                        -height * 0.55
                )
        )


        path.addCurve(
            to:
                CGPoint(
                    x:
                        width * 0.57,
                    y:
                        -height
                ),
            control1:
                CGPoint(
                    x:
                        width * 0.60,
                    y:
                        -height * 0.78
                ),
            control2:
                CGPoint(
                    x:
                        width * 0.67,
                    y:
                        -height * 0.90
                )
        )


        let edge =
            SKShapeNode(
                path:
                    path
            )


        edge.strokeColor =
            MapWorldPalette.waterEdge


        edge.lineWidth =
            72


        edge.lineCap =
            .round


        edge.lineJoin =
            .round


        waterLayer.addChild(
            edge
        )


        let water =
            SKShapeNode(
                path:
                    path
            )


        water.strokeColor =
            MapWorldPalette.water


        water.lineWidth =
            62


        water.lineCap =
            .round


        water.lineJoin =
            .round


        waterLayer.addChild(
            water
        )


        let highlight =
            SKShapeNode(
                path:
                    path
            )


        highlight.strokeColor =
            SKColor(
                white:
                    1,
                alpha:
                    0.07
            )


        highlight.lineWidth =
            2


        waterLayer.addChild(
            highlight
        )
    }


    // =====================================================
    // MARK: - Road Shadows
    // =====================================================

    private func renderRoadShadows(
        graph: RoadGraph
    ) {

        for edge in
            graph.edges
        {

            let points =
                sampledPoints(
                    edge:
                        edge,
                    graph:
                        graph
                )


            guard
                points.count >= 2
            else {

                continue
            }


            let path =
                path(
                    through:
                        points
                )


            let shadow =
                SKShapeNode(
                    path:
                        path
                )


            shadow.strokeColor =
                MapWorldPalette
                    .roadShadow


            shadow.lineWidth =
                roadWidth(
                    edge.roadClass
                )
                +
                7


            shadow.lineCap =
                .round


            shadow.lineJoin =
                .round


            shadow.position =
                CGPoint(
                    x:
                        1.5,
                    y:
                        -2
                )


            roadShadowLayer
                .addChild(
                    shadow
                )
        }
    }


    // =====================================================
    // MARK: - Road Markings
    // =====================================================

    private func renderRoadMarkings(
        graph: RoadGraph
    ) {

        for edge in graph.edges {

            let points =
                sampledPoints(
                    edge:
                        edge,
                    graph:
                        graph,
                    samples:
                        60
                )


            guard
                points.count >= 2
            else {

                continue
            }


            switch edge.roadClass {

            case .highway:

                addDottedCenterLine(
                    points:
                        points,
                    dotRadius:
                        1.7,
                    spacing:
                        10
                )


            case .arterial:

                addDottedCenterLine(
                    points:
                        points,
                    dotRadius:
                        1.4,
                    spacing:
                        9
                )


            case .connector:

                addDottedCenterLine(
                    points:
                        points,
                    dotRadius:
                        1.15,
                    spacing:
                        8
                )


            case .local,
                 .circle,
                 .culDeSac:

                break
            }
        }
    }


    private func addDashedCenterLine(
        points: [CGPoint],
        width: CGFloat
    ) {

        let dashed =
            dashedPath(
                points:
                    points,
                dashLength:
                    7,
                gapLength:
                    6
            )


        let node =
            SKShapeNode(
                path:
                    dashed
            )


        node.strokeColor =
            MapWorldPalette
                .roadMarking


        node.lineWidth =
            width


        node.lineCap =
            .round


        roadMarkingLayer
            .addChild(
                node
            )
    }


    private func addSolidLine(
        points: [CGPoint],
        width: CGFloat
    ) {

        guard
            points.count >= 2
        else {

            return
        }


        let node =
            SKShapeNode(
                path:
                    path(
                        through:
                            points
                    )
            )


        node.strokeColor =
            MapWorldPalette
                .roadMarking


        node.lineWidth =
            width


        node.lineCap =
            .round


        node.lineJoin =
            .round


        roadMarkingLayer
            .addChild(
                node
            )
    }


    // =====================================================
    // MARK: - Intersections
    // =====================================================

    private func renderIntersections(
        graph: RoadGraph
    ) {

        for vertex in
            graph.vertices
        {

            let edges =
                graph.incidentEdges(
                    to:
                        vertex.id,
                    traversableOnly:
                        true
                )


            guard
                edges.count >= 3
            else {

                continue
            }


            let vertexPoint =
                MapCoordinateConverter
                    .worldPoint(
                        for:
                            vertex.coordinate
                    )
                    .cgPoint


            for edge in
                edges.prefix(4)
            {

                guard let direction =
                    directionAwayFromVertex(
                        edge:
                            edge,
                        vertexPoint:
                            vertexPoint,
                        graph:
                            graph
                    )
                else {

                    continue
                }


                renderCrosswalk(
                    vertex:
                        vertexPoint,
                    direction:
                        direction,
                    roadWidth:
                        roadWidth(
                            edge.roadClass
                        )
                )
            }
        }
    }


    private func renderCrosswalk(
        vertex: CGPoint,
        direction: CGVector,
        roadWidth: CGFloat
    ) {

        let normal =
            CGVector(
                dx:
                    -direction.dy,
                dy:
                    direction.dx
            )


        let baseDistance =
            roadWidth * 0.72


        let halfWidth =
            roadWidth * 0.38


        // Stop line

        let stopCenter =
            CGPoint(
                x:
                    vertex.x
                    +
                    direction.dx
                    *
                    baseDistance,

                y:
                    vertex.y
                    +
                    direction.dy
                    *
                    baseDistance
            )


        let stopPath =
            CGMutablePath()


        stopPath.move(
            to:
                CGPoint(
                    x:
                        stopCenter.x
                        -
                        normal.dx
                        *
                        halfWidth,
                    y:
                        stopCenter.y
                        -
                        normal.dy
                        *
                        halfWidth
                )
        )


        stopPath.addLine(
            to:
                CGPoint(
                    x:
                        stopCenter.x
                        +
                        normal.dx
                        *
                        halfWidth,
                    y:
                        stopCenter.y
                        +
                        normal.dy
                        *
                        halfWidth
                )
        )


        let stopLine =
            SKShapeNode(
                path:
                    stopPath
            )


        stopLine.strokeColor =
            MapWorldPalette.crosswalk


        stopLine.lineWidth =
            1.8


        intersectionLayer
            .addChild(
                stopLine
            )


        // Crosswalk stripes

        for stripeIndex in
            0 ..< 4
        {

            let distance =
                baseDistance
                +
                4
                +
                CGFloat(stripeIndex)
                *
                3.5


            let center =
                CGPoint(
                    x:
                        vertex.x
                        +
                        direction.dx
                        *
                        distance,

                    y:
                        vertex.y
                        +
                        direction.dy
                        *
                        distance
                )


            let stripePath =
                CGMutablePath()


            stripePath.move(
                to:
                    CGPoint(
                        x:
                            center.x
                            -
                            normal.dx
                            *
                            halfWidth,
                        y:
                            center.y
                            -
                            normal.dy
                            *
                            halfWidth
                    )
            )


            stripePath.addLine(
                to:
                    CGPoint(
                        x:
                            center.x
                            +
                            normal.dx
                            *
                            halfWidth,
                        y:
                            center.y
                            +
                            normal.dy
                            *
                            halfWidth
                    )
            )


            let stripe =
                SKShapeNode(
                    path:
                        stripePath
                )


            stripe.strokeColor =
                MapWorldPalette.crosswalk


            stripe.lineWidth =
                1.3


            intersectionLayer
                .addChild(
                    stripe
                )
        }
    }


    // =====================================================
    // MARK: - Road Geometry
    // =====================================================

    private func sampledPoints(
        edge: RoadEdge,
        graph: RoadGraph,
        samples: Int = 28
    ) -> [CGPoint] {

        guard samples > 0 else {
            return []
        }


        return (0 ... samples)
            .compactMap { index in

                let fraction =
                    Double(index)
                    /
                    Double(samples)


                return RoadEdgeGeometry
                    .point(
                        atFraction:
                            fraction,
                        on:
                            edge,
                        graph:
                            graph,
                        cubicSegments:
                            96
                    )?
                    .cgPoint
            }
    }


    private func directionAwayFromVertex(
        edge: RoadEdge,
        vertexPoint: CGPoint,
        graph: RoadGraph
    ) -> CGVector? {

        let points =
            sampledPoints(
                edge:
                    edge,
                graph:
                    graph,
                samples:
                    10
            )


        guard
            points.count >= 2,
            let first =
                points.first,
            let last =
                points.last
        else {

            return nil
        }


        let firstDistance =
            distance(
                first,
                vertexPoint
            )


        let lastDistance =
            distance(
                last,
                vertexPoint
            )


        let vector:
            CGVector


        if firstDistance <=
            lastDistance
        {

            vector =
                CGVector(
                    dx:
                        points[1].x
                        -
                        points[0].x,

                    dy:
                        points[1].y
                        -
                        points[0].y
                )

        } else {

            let lastIndex =
                points.count - 1


            vector =
                CGVector(
                    dx:
                        points[lastIndex - 1].x
                        -
                        points[lastIndex].x,

                    dy:
                        points[lastIndex - 1].y
                        -
                        points[lastIndex].y
                )
        }


        return normalized(
            vector
        )
    }


    private func roadWidth(
        _ roadClass: RoadClass
    ) -> CGFloat {

        switch roadClass {

        case .local:
            return 13

        case .connector:
            return 14

        case .culDeSac:
            return 13

        case .arterial:
            return 20

        case .circle:
            return 20

        case .highway:
            return 28
        }
    }


    // =====================================================
    // MARK: - Geometry Helpers
    // =====================================================

    private func path(
        through points: [CGPoint]
    ) -> CGPath {

        let result =
            CGMutablePath()


        guard let first =
            points.first
        else {

            return result
        }


        result.move(
            to:
                first
        )


        for point in
            points.dropFirst()
        {

            result.addLine(
                to:
                    point
            )
        }


        return result
    }


    private func dashedPath(
        points: [CGPoint],
        dashLength: CGFloat,
        gapLength: CGFloat
    ) -> CGPath {

        let path =
            CGMutablePath()


        guard
            points.count >= 2
        else {

            return path
        }


        for index in
            0 ..<
            points.count - 1
        {

            let a =
                points[index]

            let b =
                points[index + 1]


            let dx =
                b.x - a.x

            let dy =
                b.y - a.y


            let length =
                hypot(
                    dx,
                    dy
                )


            guard
                length > 0
            else {

                continue
            }


            let ux =
                dx / length

            let uy =
                dy / length


            var position:
                CGFloat = 0


            while position <
                length
            {

                let startDistance =
                    position


                let endDistance =
                    min(
                        position
                        +
                        dashLength,
                        length
                    )


                path.move(
                    to:
                        CGPoint(
                            x:
                                a.x
                                +
                                ux
                                *
                                startDistance,

                            y:
                                a.y
                                +
                                uy
                                *
                                startDistance
                        )
                )


                path.addLine(
                    to:
                        CGPoint(
                            x:
                                a.x
                                +
                                ux
                                *
                                endDistance,

                            y:
                                a.y
                                +
                                uy
                                *
                                endDistance
                        )
                )


                position +=
                    dashLength
                    +
                    gapLength
            }
        }


        return path
    }


    private func offsetPolyline(
        _ points: [CGPoint],
        offset: CGFloat
    ) -> [CGPoint] {

        guard
            points.count >= 2
        else {

            return points
        }


        return points
            .indices
            .map { index in

                let previous =
                    points[
                        max(
                            0,
                            index - 1
                        )
                    ]


                let next =
                    points[
                        min(
                            points.count - 1,
                            index + 1
                        )
                    ]


                let vector =
                    normalized(
                        CGVector(
                            dx:
                                next.x
                                -
                                previous.x,

                            dy:
                                next.y
                                -
                                previous.y
                        )
                    )


                let normal =
                    CGVector(
                        dx:
                            -vector.dy,
                        dy:
                            vector.dx
                    )


                return CGPoint(
                    x:
                        points[index].x
                        +
                        normal.dx
                        *
                        offset,

                    y:
                        points[index].y
                        +
                        normal.dy
                        *
                        offset
                )
            }
    }


    private func normalized(
        _ vector: CGVector
    ) -> CGVector {

        let length =
            hypot(
                vector.dx,
                vector.dy
            )


        guard
            length > 0.0001
        else {

            return .zero
        }


        return CGVector(
            dx:
                vector.dx / length,
            dy:
                vector.dy / length
        )
    }


    private func distance(
        _ a: CGPoint,
        _ b: CGPoint
    ) -> CGFloat {

        hypot(
            a.x - b.x,
            a.y - b.y
        )
    }


    // =====================================================
    // MARK: - Deterministic Random
    // =====================================================

    private func random01(
        _ a: Int,
        _ b: Int,
        _ c: Int
    ) -> CGFloat {

        var value =
            UInt64(
                abs(
                    a * 73_856_093
                    +
                    b * 19_349_663
                    +
                    c * 83_492_791
                )
            )


        value ^=
            value >> 13


        value &*=
            1_274_126_177


        value ^=
            value >> 16


        return CGFloat(
            value % 10_000
        )
        /
        10_000
    }


    // =====================================================
    // MARK: - Clear
    // =====================================================

    private func clear() {

        terrainLayer
            .removeAllChildren()

        districtLayer
            .removeAllChildren()

        districtLabelLayer
            .removeAllChildren()

        blockLayer
            .removeAllChildren()

        parkLayer
            .removeAllChildren()

        buildingShadowLayer
            .removeAllChildren()

        buildingLayer
            .removeAllChildren()

        vegetationLayer
            .removeAllChildren()

        waterLayer
            .removeAllChildren()

        roadShadowLayer
            .removeAllChildren()

        roadMarkingLayer
            .removeAllChildren()

        intersectionLayer
            .removeAllChildren()
    }
    
    private func addDottedCenterLine(
        points: [CGPoint],
        dotRadius: CGFloat,
        spacing: CGFloat
    ) {

        guard
            points.count >= 2
        else {

            return
        }


        var distanceUntilNextDot:
            CGFloat = 0


        for index in
            0 ..< points.count - 1
        {

            let start =
                points[index]

            let end =
                points[index + 1]


            let dx =
                end.x - start.x

            let dy =
                end.y - start.y


            let segmentLength =
                hypot(
                    dx,
                    dy
                )


            guard
                segmentLength > 0
            else {

                continue
            }


            let ux =
                dx / segmentLength

            let uy =
                dy / segmentLength


            var position =
                distanceUntilNextDot


            while position <
                segmentLength
            {

                let point =
                    CGPoint(
                        x:
                            start.x
                            +
                            ux
                            *
                            position,

                        y:
                            start.y
                            +
                            uy
                            *
                            position
                    )


                let dot =
                    SKShapeNode(
                        circleOfRadius:
                            dotRadius
                    )


                dot.fillColor =
                    MapWorldPalette
                        .roadMarking


                dot.strokeColor =
                    .clear


                dot.position =
                    point


                roadMarkingLayer
                    .addChild(
                        dot
                    )


                position +=
                    spacing
            }


            distanceUntilNextDot =
                position
                -
                segmentLength
        }
    }
}


private extension SKColor {

    convenience init(
        blackWithAlpha alpha: CGFloat
    ) {

        self.init(
            red:
                0,
            green:
                0,
            blue:
                0,
            alpha:
                alpha
        )
    }
}
