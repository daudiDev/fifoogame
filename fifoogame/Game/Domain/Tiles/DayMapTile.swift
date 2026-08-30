//
//  DayMapTile.swift
//  fifoogame
//
//  Tile/card presentation model for the Fifoo day map redesign.
//

import Foundation
import CoreGraphics


// =====================================================
// MARK: - Reveal State
// =====================================================

enum DayMapTileRevealState:
    Equatable,
    Sendable {

    case hidden
    case revealed
}


// =====================================================
// MARK: - Reveal Policy
// =====================================================

/// Controls only automatic discovery of ordinary GameNode cards. Route and
/// route-preview cards remain revealed because they communicate the user's
/// active path. User-created cards are also revealed immediately.
enum DayMapTileRevealPolicy:
    Equatable,
    Sendable {

    /// FifooGame's new card mechanic: unrelated GameNodes begin concealed and
    /// the first tap flips the card. A second tap opens the existing node UI.
    case discoveryFirst

    /// Compatibility/debug behavior matching Pass 1/2.
    case revealAllNodes
}


// =====================================================
// MARK: - Route State
// =====================================================

enum DayMapTileRouteState:
    Equatable,
    Sendable {

    case none
    case completed
    case chosen(routeID: RouteID)
    case alternative(routeID: RouteID)


    var interactionTarget:
        RouteInteractionTarget? {

        switch self {

        case .none:
            return nil

        case .completed:
            return .completed

        case let .chosen(routeID):
            return .chosen(routeID: routeID)

        case let .alternative(routeID):
            return .alternative(routeID: routeID)
        }
    }
}


// =====================================================
// MARK: - Draft / Preview State
// =====================================================

enum DayMapTilePreviewState:
    Equatable,
    Sendable {

    case none
    case selected(routeID: RouteID)
    case alternative(routeID: RouteID)
}


// =====================================================
// MARK: - Tile Artwork
// =====================================================

/// Renderer-ready artwork source for a revealed card. Keeping this lightweight
/// prevents the SpriteKit renderer from needing the entire GameMapNode model.
enum DayMapTileArtworkSource:
    Equatable,
    Sendable {

    case asset(name: String)
    case remote(urlString: String)
    case placeholder(kind: GameNodeKind)
}


// =====================================================
// MARK: - Lightweight Node Preview
// =====================================================

struct DayMapTileNodePreview:
    Equatable,
    Sendable {

    let nodeID:
        GameNodeID

    let title:
        String

    let kind:
        GameNodeKind

    let time:
        DayTime

    let artworkSource:
        DayMapTileArtworkSource
}


// =====================================================
// MARK: - Tile Snapshot
// =====================================================

struct DayMapTileSnapshot:
    Equatable,
    Sendable {

    let id:
        GridCellID

    var revealState:
        DayMapTileRevealState

    var routeState:
        DayMapTileRouteState

    var previewState:
        DayMapTilePreviewState

    var nodePreviews:
        [DayMapTileNodePreview]

    var isSelected:
        Bool

    var isCurrentRouteBoundary:
        Bool

    /// Potential progress change if this empty card were used as a stop.
    /// Calculated from the card's horizontal progress coordinate relative to
    /// the user's current progress. Content cards can ignore this value.
    var potentialProgressDeltaPercent:
        Double?


    var primaryNodePreview:
        DayMapTileNodePreview? {

        nodePreviews.first
    }


    var primaryNodeID:
        GameNodeID? {

        primaryNodePreview?.nodeID
    }


    var routeInteractionTarget:
        RouteInteractionTarget? {

        routeState.interactionTarget
    }


    var hasNode:
        Bool {

        !nodePreviews.isEmpty
    }


    static func hidden(
        id: GridCellID
    ) -> DayMapTileSnapshot {

        DayMapTileSnapshot(
            id: id,
            revealState: .hidden,
            routeState: .none,
            previewState: .none,
            nodePreviews: [],
            isSelected: false,
            isCurrentRouteBoundary: false,
            potentialProgressDeltaPercent: nil
        )
    }
}




// =====================================================
// MARK: - Stacked Stop Selection
// =====================================================

/// One tap on a revealed tile that contains multiple stops opens a compact
/// fan-out chooser before any individual stop sheet is presented.
struct StackedDayTileSelectionRequest:
    Identifiable,
    Equatable,
    Sendable {

    let id: UUID

    let cellID:
        GridCellID

    let nodePreviews:
        [DayMapTileNodePreview]


    init(
        id: UUID = UUID(),
        cellID: GridCellID,
        nodePreviews: [DayMapTileNodePreview]
    ) {

        self.id = id
        self.cellID = cellID
        self.nodePreviews = nodePreviews
    }
}

// =====================================================
// MARK: - Route Connections
// =====================================================

/// Visual role for the short gutter bridge between two sequential route
/// cards. This is presentation state only; it does not replace or mutate the
/// hidden RoadGraph used for actual pathfinding.
enum DayMapTileRouteConnectionStyle:
    Equatable,
    Hashable,
    Sendable {

    case completed
    case chosen
    case alternative
    case previewSelected
    case previewAlternative


    /// Used when multiple route layers share the same card-to-card edge.
    /// Preview wins because it is the user's immediate planning interaction,
    /// then completed history, chosen future, and finally alternatives.
    var visualPriority: Int {

        switch self {

        case .previewSelected:
            return 50

        case .previewAlternative:
            return 40

        case .completed:
            return 30

        case .chosen:
            return 20

        case .alternative:
            return 10
        }
    }
}


/// One short visual bridge between neighboring cards in the projected route.
/// Endpoints are canonicalized so the same edge can be de-duplicated even
/// when multiple route layers traverse it in opposite directions.
struct DayMapTileRouteConnection:
    Equatable,
    Hashable,
    Sendable {

    /// Traversal-preserving endpoints so directional affordances can point
    /// toward the actual next stop in the path.
    let fromCellID:
        GridCellID

    let toCellID:
        GridCellID

    /// Canonicalized endpoints used only for edge de-duplication and stable
    /// sorting across multiple route layers.
    let firstCellID:
        GridCellID

    let secondCellID:
        GridCellID

    let style:
        DayMapTileRouteConnectionStyle


    init(
        firstCellID: GridCellID,
        secondCellID: GridCellID,
        style: DayMapTileRouteConnectionStyle
    ) {

        fromCellID =
            firstCellID

        toCellID =
            secondCellID

        if Self.isOrderedBefore(
            firstCellID,
            secondCellID
        ) {

            self.firstCellID =
                firstCellID

            self.secondCellID =
                secondCellID

        } else {

            self.firstCellID =
                secondCellID

            self.secondCellID =
                firstCellID
        }

        self.style =
            style
    }


    private static func isOrderedBefore(
        _ lhs: GridCellID,
        _ rhs: GridCellID
    ) -> Bool {

        if lhs.row != rhs.row {
            return lhs.row < rhs.row
        }

        return lhs.column <= rhs.column
    }
}


// =====================================================
// MARK: - Render State
// =====================================================

struct DayMapTileRenderState:
    Equatable,
    Sendable {

    var tiles:
        [GridCellID: DayMapTileSnapshot]

    /// Sequential card-to-card bridges that make the route read as one
    /// coherent chain without rendering the legacy road network.
    var routeConnections:
        Set<DayMapTileRouteConnection>


    static let empty =
        DayMapTileRenderState(
            tiles: [:],
            routeConnections: []
        )


    func snapshot(
        for id: GridCellID
    ) -> DayMapTileSnapshot {

        tiles[id]
        ?? .hidden(id: id)
    }
}


// =====================================================
// MARK: - Resolver
// =====================================================

/// Converts the existing game-node + road-route domain into the tile/card
/// presentation model. The road graph remains a semantic/pathfinding engine;
/// no road geometry is rendered by this type.
enum DayMapTileResolver {

    static func makeRenderState(
        gameNodes: [GameMapNode],
        roadGraph: RoadGraph,
        routes: RouteRenderState,
        preview: RoutePreviewRenderState,
        selection: SelectionState,
        revealedCellIDs: Set<GridCellID>,
        currentProgressPercent: Double,
        focusedAlternativeRouteID: RouteID? = nil
    ) -> DayMapTileRenderState {

        var nodePreviewsByCell:
            [GridCellID: [DayMapTileNodePreview]] = [:]

        for node in gameNodes where node.isEnabled {

            guard
                let coordinate =
                    GameNodePlacementResolver
                        .mapCoordinate(
                            for: node,
                            graph: roadGraph
                        ),
                let cellID =
                    GridMapGeometry
                        .cellID(
                            containing: coordinate
                        )
            else {
                continue
            }

            nodePreviewsByCell[
                cellID,
                default: []
            ]
            .append(
                DayMapTileNodePreview(
                    nodeID: node.id,
                    title: node.content.title,
                    kind: node.content.kind,
                    time: node.time,
                    artworkSource:
                        artworkSource(
                            for: node
                        )
                )
            )
        }


        // Keep collisions deterministic. The tile can expose a +N indicator
        // while the first node remains the primary tap target for now.
        for key in nodePreviewsByCell.keys {

            nodePreviewsByCell[key]?
                .sort { lhs, rhs in

                    if lhs.time != rhs.time {
                        return lhs.time < rhs.time
                    }

                    return lhs.nodeID.rawValue.uuidString
                        < rhs.nodeID.rawValue.uuidString
                }
        }


        var routeStateByCell:
            [GridCellID: DayMapTileRouteState] = [:]

        var connectionByCellPair:
            [DayMapTileConnectionKey: DayMapTileRouteConnection] = [:]


        // Alternatives are the lowest-priority live route state. When no
        // alternate is focused, only cells that actually contain a GameNode
        // receive the orange/white alternate perimeter. Empty transit cells
        // stay visually neutral. Once the user focuses one alternate route,
        // every cell in that route is exposed and stitched so the route reads
        // as one continuous path alongside completed history.
        for alternative in routes.alternatives {

            let ordered =
                orderedCells(
                    for: alternative.segments,
                    graph: roadGraph
                )

            let isFocusedAlternative =
                focusedAlternativeRouteID == alternative.routeID

            for cellID in Set(ordered) {

                guard
                    isFocusedAlternative
                    || nodePreviewsByCell[cellID] != nil
                else {
                    continue
                }

                if routeStateByCell[cellID] == nil {

                    routeStateByCell[cellID] =
                        .alternative(
                            routeID:
                                alternative.routeID
                        )
                }
            }

            if isFocusedAlternative {

                mergeConnections(
                    for: ordered,
                    style: .alternative,
                    into: &connectionByCellPair
                )
            }
        }


        // Chosen route overrides an alternative wherever they overlap.
        if let chosen = routes.chosenFuture {

            let ordered =
                orderedCells(
                    for: chosen.segments,
                    graph: roadGraph
                )

            for cellID in Set(ordered) {

                routeStateByCell[cellID] =
                    .chosen(
                        routeID:
                            chosen.routeID
                    )
            }

            mergeConnections(
                for: ordered,
                style: .chosen,
                into: &connectionByCellPair
            )
        }


        // Completed history is visually authoritative for the past.
        let completedOrdered =
            orderedCells(
                for: routes.completedSegments,
                graph: roadGraph
            )

        for cellID in Set(completedOrdered) {

            routeStateByCell[cellID] =
                .completed
        }

        mergeConnections(
            for: completedOrdered,
            style: .completed,
            into: &connectionByCellPair
        )


        var previewStateByCell:
            [GridCellID: DayMapTilePreviewState] = [:]


        // Unselected preview alternatives first.
        for route in preview.routes where !route.isSelected {

            let ordered =
                orderedCells(
                    for: route.segments,
                    graph: roadGraph
                )

            for cellID in Set(ordered) {

                if previewStateByCell[cellID] == nil {

                    previewStateByCell[cellID] =
                        .alternative(
                            routeID:
                                route.routeID
                        )
                }
            }

            // Unselected alternate previews also avoid gutter bridges so the
            // map never paints alternate join paths.
        }


        // Selected preview wins over preview alternatives.
        for route in preview.routes where route.isSelected {

            let ordered =
                orderedCells(
                    for: route.segments,
                    graph: roadGraph
                )

            for cellID in Set(ordered) {

                previewStateByCell[cellID] =
                    .selected(
                        routeID:
                            route.routeID
                    )
            }

            mergeConnections(
                for: ordered,
                style: .previewSelected,
                into: &connectionByCellPair
            )
        }


        let currentBoundaryCell =
            cellID(
                for: routes.currentBoundary,
                graph: roadGraph
            )


        var allCellIDs =
            Set(nodePreviewsByCell.keys)
            .union(routeStateByCell.keys)
            .union(previewStateByCell.keys)
            .union(revealedCellIDs)

        if let currentBoundaryCell {
            allCellIDs.insert(currentBoundaryCell)
        }


        var tiles:
            [GridCellID: DayMapTileSnapshot] = [:]

        tiles.reserveCapacity(
            allCellIDs.count
        )


        for cellID in allCellIDs {

            let nodePreviews =
                nodePreviewsByCell[cellID]
                ?? []

            let routeState =
                routeStateByCell[cellID]
                ?? .none

            let previewState =
                previewStateByCell[cellID]
                ?? .none

            let selectedNode =
                selection.selectedNodeID
                .map { selectedID in

                    nodePreviews.contains {
                        $0.nodeID == selectedID
                    }
                }
                ?? false

            let selectedRoute =
                selection.selectedRouteID
                .map { selectedRouteID in

                    switch routeState {

                    case let .chosen(routeID),
                         let .alternative(routeID):

                        return routeID == selectedRouteID

                    case .none,
                         .completed:

                        return false
                    }
                }
                ?? false


            let containsUserStop =
                nodePreviews.contains { preview in
                    preview.kind == .user
                }

            tiles[cellID] =
                DayMapTileSnapshot(
                    id: cellID,
                    // Path/preview cards are always exposed because they
                    // communicate the user's path. Off-path User stops are
                    // also always revealed so people remain discoverable on
                    // the day map. Every other off-path stop still requires
                    // an explicit reveal by the current user.
                    revealState:
                        revealedCellIDs.contains(cellID)
                        || containsUserStop
                        || routeState != .none
                        || previewState != .none
                        ? .revealed
                        : .hidden,
                    routeState: routeState,
                    previewState: previewState,
                    nodePreviews: nodePreviews,
                    isSelected:
                        selectedNode
                        || selectedRoute,
                    isCurrentRouteBoundary:
                        cellID == currentBoundaryCell,
                    potentialProgressDeltaPercent:
                        GridMapGeometry
                            .mapCoordinateAtTileCenter(
                                for: cellID
                            )
                            .progress
                            .percent
                        - currentProgressPercent
                )
        }


        return DayMapTileRenderState(
            tiles: tiles,
            routeConnections:
                Set(
                    connectionByCellPair.values
                )
        )
    }
}


// =====================================================
// MARK: - Node Artwork Resolution
// =====================================================

private extension DayMapTileResolver {

    static func artworkSource(
        for node: GameMapNode
    ) -> DayMapTileArtworkSource {

        // Post cards are content-first rather than marker-first: use the post
        // image/GIF when available, then fall back to the poster. This makes
        // a square card read like the actual post while the legacy circular
        // map marker can remain person-first if that renderer is reused.
        if case let .post(content) = node.content,
           let urlString = content.snapshot?.preferredMarkerImageURL,
           isUsableRemoteURLString(urlString)
        {
            return .remote(
                urlString: urlString
            )
        }

        // Media cards can use their actual image/GIF as artwork even when an
        // explicit marker thumbnail was never assigned. Videos still prefer
        // an explicit thumbnail because SpriteKit does not decode video frames
        // for these lightweight map cards.
        if case let .media(content) = node.content,
           content.mediaType != .video,
           let urlString = content.urlString,
           isUsableRemoteURLString(urlString)
        {
            return .remote(
                urlString: urlString
            )
        }

        // Activity snapshots often contain useful artwork even when older
        // persisted GameNode data predates the top-level `image` field.
        if case let .activity(content) = node.content,
           content.image == nil,
           let urlString = activityFallbackImageURL(content),
           isUsableRemoteURLString(urlString)
        {
            return .remote(
                urlString: urlString
            )
        }

        if let image = node.content.image {

            switch image {

            case let .asset(name):

                let trimmed =
                    name.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )

                if !trimmed.isEmpty {
                    return .asset(
                        name: trimmed
                    )
                }


            case let .remote(urlString):

                if isUsableRemoteURLString(urlString) {
                    return .remote(
                        urlString: urlString
                    )
                }


            case .systemSymbol:

                break
            }
        }

        return .placeholder(
            kind: node.content.kind
        )
    }


    static func activityFallbackImageURL(
        _ content: ActivityNodeContent
    ) -> String? {

        if let url = content.meal?.imageURL,
           isUsableRemoteURLString(url)
        {
            return url
        }

        if let url =
            content.workout?
                .imageURLs?
                .first(
                    where: isUsableRemoteURLString
                )
        {
            return url
        }

        if let url =
            content.task?
                .imageURLs?
                .first(
                    where: isUsableRemoteURLString
                )
        {
            return url
        }

        return nil
    }


    static func isUsableRemoteURLString(
        _ value: String
    ) -> Bool {

        let trimmed =
            value.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !trimmed.isEmpty else {
            return false
        }

        let lowered =
            trimmed.lowercased()

        return lowered != "none"
            && lowered != "null"
            && (
                lowered.hasPrefix("http://")
                || lowered.hasPrefix("https://")
            )
    }
}


// =====================================================
// MARK: - Route -> Cell Projection
// =====================================================

private extension DayMapTileResolver {

    struct DayMapTileConnectionKey:
        Hashable {

        let first:
            GridCellID

        let second:
            GridCellID


        init(
            _ lhs: GridCellID,
            _ rhs: GridCellID
        ) {

            let connection =
                DayMapTileRouteConnection(
                    firstCellID: lhs,
                    secondCellID: rhs,
                    style: .alternative
                )

            first = connection.firstCellID
            second = connection.secondCellID
        }
    }


    /// Projects the hidden road-route geometry into an ordered card chain.
    /// Consecutive duplicates are collapsed, but traversal order is retained
    /// so the renderer can stitch only genuinely sequential cards together.
    static func orderedCells(
        for segments: [RoadRouteSegment],
        graph: RoadGraph
    ) -> [GridCellID] {

        var result:
            [GridCellID] = []


        for segment in segments {

            let points =
                RoadEdgeGeometry
                    .sampledPoints(
                        along: segment,
                        graph: graph,
                        cubicSegments: 96
                    )


            for point in points {

                guard let id =
                    GridMapGeometry
                        .cellID(
                            nearestToWorldPoint:
                                point.cgPoint
                        )
                else {
                    continue
                }

                guard result.last != id else {
                    continue
                }

                result.append(id)
            }
        }


        return result
    }


    static func mergeConnections(
        for orderedCells: [GridCellID],
        style: DayMapTileRouteConnectionStyle,
        into accumulator:
            inout [DayMapTileConnectionKey: DayMapTileRouteConnection]
    ) {

        guard orderedCells.count >= 2 else {
            return
        }


        for pair in zip(
            orderedCells,
            orderedCells.dropFirst()
        ) {

            let first = pair.0
            let second = pair.1

            let columnDistance =
                abs(
                    first.column - second.column
                )

            let rowDistance =
                abs(
                    first.row - second.row
                )

            // The dense road sampling should normally move one card at a
            // time. Refuse to draw a long bridge if malformed route data ever
            // jumps multiple cells; route semantics still remain intact.
            guard
                max(columnDistance, rowDistance) <= 1,
                columnDistance + rowDistance > 0
            else {
                continue
            }

            let key =
                DayMapTileConnectionKey(
                    first,
                    second
                )

            let candidate =
                DayMapTileRouteConnection(
                    firstCellID: first,
                    secondCellID: second,
                    style: style
                )

            if let existing = accumulator[key],
               existing.style.visualPriority >= style.visualPriority
            {
                continue
            }

            accumulator[key] =
                candidate
        }
    }


    static func cellID(
        for location:
            GameNodeRouteAnchor.RoadLocation?,
        graph: RoadGraph
    ) -> GridCellID? {

        guard let location else {
            return nil
        }


        let worldPoint:
            WorldPoint?


        switch location {

        case let .vertex(vertexID):

            worldPoint =
                graph
                    .vertex(
                        id: vertexID
                    )?
                    .worldPoint


        case let .edge(
            edgeID,
            fraction
        ):

            guard let edge =
                graph.edge(
                    id: edgeID
                )
            else {
                return nil
            }

            worldPoint =
                RoadEdgeGeometry
                    .point(
                        atFraction: fraction,
                        on: edge,
                        graph: graph
                    )
        }


        guard let worldPoint else {
            return nil
        }


        return GridMapGeometry
            .cellID(
                nearestToWorldPoint:
                    worldPoint.cgPoint
            )
    }
}
