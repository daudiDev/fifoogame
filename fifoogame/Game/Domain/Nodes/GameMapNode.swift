//
//  GameMapNode.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/23/26.
//

import Foundation


struct GameMapNode:
    Identifiable,
    Codable,
    Equatable,
    Sendable {

    let id: GameNodeID

    var placement:
        GameNodePlacement

    /// Semantic time owned by the node itself.
    ///
    /// For free-coordinate nodes this is kept in sync with the
    /// placement coordinate's time. For road-attached nodes this
    /// should match the attached road vertex time.
    var time:
        DayTime

    var content:
        GameNodeContent

    var isEnabled:
        Bool


    init(
        id: GameNodeID = GameNodeID(),
        placement: GameNodePlacement,
        time: DayTime? = nil,
        content: GameNodeContent,
        isEnabled: Bool = true
    ) {

        let resolvedTime =
            time
            ??
            Self.timeEmbedded(
                in: placement
            )
            ??
            .startOfDay

        self.id =
            id

        self.time =
            resolvedTime

        self.placement =
            Self.normalizedPlacement(
                placement,
                time: resolvedTime
            )

        self.content =
            content

        self.isEnabled =
            isEnabled
    }
}


// =====================================================
// MARK: - Backward-compatible Codable
// =====================================================

extension GameMapNode {

    private enum CodingKeys:
        String,
        CodingKey {

        case id
        case placement
        case time
        case content
        case isEnabled
    }


    init(
        from decoder: Decoder
    ) throws {

        let container =
            try decoder.container(
                keyedBy: CodingKeys.self
            )

        let id =
            try container.decode(
                GameNodeID.self,
                forKey: .id
            )

        let decodedPlacement =
            try container.decode(
                GameNodePlacement.self,
                forKey: .placement
            )

        let decodedTime =
            try container.decodeIfPresent(
                DayTime.self,
                forKey: .time
            )

        let resolvedTime =
            decodedTime
            ??
            Self.timeEmbedded(
                in: decodedPlacement
            )
            ??
            .startOfDay

        self.id =
            id

        self.time =
            resolvedTime

        self.placement =
            Self.normalizedPlacement(
                decodedPlacement,
                time: resolvedTime
            )

        self.content =
            try container.decode(
                GameNodeContent.self,
                forKey: .content
            )

        self.isEnabled =
            try container.decodeIfPresent(
                Bool.self,
                forKey: .isEnabled
            )
            ?? true
    }


    func encode(
        to encoder: Encoder
    ) throws {

        var container =
            encoder.container(
                keyedBy: CodingKeys.self
            )

        try container.encode(
            id,
            forKey: .id
        )

        try container.encode(
            placement,
            forKey: .placement
        )

        try container.encode(
            time,
            forKey: .time
        )

        try container.encode(
            content,
            forKey: .content
        )

        try container.encode(
            isEnabled,
            forKey: .isEnabled
        )
    }
}


// =====================================================
// MARK: - Time / Placement Synchronization
// =====================================================

extension GameMapNode {

    /// Changes the node time and, when this is a free-coordinate node,
    /// moves the coordinate vertically to the same semantic time.
    mutating func setTime(
        _ newTime: DayTime
    ) {

        time =
            newTime

        placement =
            Self.normalizedPlacement(
                placement,
                time: newTime
            )
    }


    /// Replaces placement while keeping node time coherent.
    ///
    /// If the new placement contains a semantic coordinate, that
    /// coordinate becomes the node's time. For road-vertex placement,
    /// pass `resolvedRoadTime` when the vertex is known.
    mutating func setPlacement(
        _ newPlacement: GameNodePlacement,
        resolvedRoadTime: DayTime? = nil
    ) {

        let resolvedTime =
            resolvedRoadTime
            ??
            Self.timeEmbedded(
                in: newPlacement
            )
            ??
            time

        time =
            resolvedTime

        placement =
            Self.normalizedPlacement(
                newPlacement,
                time: resolvedTime
            )
    }
}


private extension GameMapNode {

    static func timeEmbedded(
        in placement: GameNodePlacement
    ) -> DayTime? {

        guard case let .coordinate(
            coordinate
        ) = placement
        else {

            return nil
        }

        return coordinate.time
    }


    static func normalizedPlacement(
        _ placement: GameNodePlacement,
        time: DayTime
    ) -> GameNodePlacement {

        switch placement {

        case let .coordinate(
            coordinate
        ):

            return .coordinate(
                MapCoordinate(
                    time: time,
                    progress: coordinate.progress
                )
            )

        case .roadVertex:

            return placement
        }
    }
}
