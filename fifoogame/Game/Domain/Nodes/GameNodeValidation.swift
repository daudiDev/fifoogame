//
//  GameNodeValidation.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/24/26.
//


import Foundation


// =====================================================
// MARK: - Validation Issue
// =====================================================

struct GameNodeValidationIssue:
    Identifiable,
    Equatable,
    Sendable {

    enum Severity:
        Equatable,
        Sendable {

        case error
        case warning
    }


    let id:
        String

    let severity:
        Severity

    let message:
        String


    init(
        id: String,
        severity: Severity = .error,
        message: String
    ) {

        self.id =
            id

        self.severity =
            severity

        self.message =
            message
    }
}


// =====================================================
// MARK: - Validation Result
// =====================================================

struct GameNodeValidationResult:
    Equatable,
    Sendable {

    let issues:
        [GameNodeValidationIssue]


    var errors:
        [GameNodeValidationIssue] {

        issues.filter {

            $0.severity ==
                .error
        }
    }


    var warnings:
        [GameNodeValidationIssue] {

        issues.filter {

            $0.severity ==
                .warning
        }
    }


    var isValid:
        Bool {

        errors.isEmpty
    }
}

// =====================================================
// MARK: - Validator
// =====================================================

enum GameNodeValidator {

    static func validate(
        _ node: GameMapNode,
        roadGraph: RoadGraph
    ) -> GameNodeValidationResult {

        var issues:
            [GameNodeValidationIssue] = []


        validateContent(
            node.content,
            issues:
                &issues
        )


        validateImage(
            node.content.image,
            issues:
                &issues
        )


        validatePlacement(
            node.placement,
            roadGraph:
                roadGraph,
            issues:
                &issues
        )


        return GameNodeValidationResult(
            issues:
                issues
        )
    }
}

// =====================================================
// MARK: - Content Validation
// =====================================================

private extension GameNodeValidator {

    static func validateContent(
        _ content: GameNodeContent,
        issues: inout [GameNodeValidationIssue]
    ) {

        switch content {

        // =========================================
        // Play
        // =========================================

        case let .play(
            content
        ):

            requireText(
                content.title,
                fieldName:
                    "Play title",
                id:
                    "play.title",
                issues:
                    &issues
            )


        // =========================================
        // User
        // =========================================

        case let .user(
            content
        ):

            requireText(
                content.displayName,
                fieldName:
                    "Display name",
                id:
                    "user.displayName",
                issues:
                    &issues
            )


            requireText(
                content.userID,
                fieldName:
                    "User ID",
                id:
                    "user.id",
                issues:
                    &issues
            )


        // =========================================
        // Activity
        // =========================================

        case let .activity(
            content
        ):

            requireText(
                content.title,
                fieldName:
                    "Activity title",
                id:
                    "activity.title",
                issues:
                    &issues
            )


            requireText(
                content.activityID,
                fieldName:
                    "Activity ID",
                id:
                    "activity.id",
                issues:
                    &issues
            )


        // =========================================
        // Post
        // =========================================

        case let .post(
            content
        ):

            requireText(
                content.title,
                fieldName:
                    "Post title",
                id:
                    "post.title",
                issues:
                    &issues
            )


            requireText(
                content.postID,
                fieldName:
                    "Post ID",
                id:
                    "post.id",
                issues:
                    &issues
            )


        // =========================================
        // Media
        // =========================================

        case let .media(
            content
        ):

            requireText(
                content.title,
                fieldName:
                    "Media title",
                id:
                    "media.title",
                issues:
                    &issues
            )


            requireText(
                content.mediaID,
                fieldName:
                    "Media ID",
                id:
                    "media.id",
                issues:
                    &issues
            )


            guard
                let urlString =
                    content.urlString,

                !urlString
                    .trimmingCharacters(
                        in:
                            .whitespacesAndNewlines
                    )
                    .isEmpty
            else {

                issues.append(
                    GameNodeValidationIssue(
                        id:
                            "media.url.missing",
                        message:
                            "Media URL is required."
                    )
                )

                return
            }


            if !isValidWebURL(
                urlString
            ) {

                issues.append(
                    GameNodeValidationIssue(
                        id:
                            "media.url.invalid",
                        message:
                            "Media URL must be a valid http or https URL."
                    )
                )
            }


        // =========================================
        // Hyperlink
        // =========================================

        case let .hyperlink(
            content
        ):

            requireText(
                content.title,
                fieldName:
                    "Link title",
                id:
                    "hyperlink.title",
                issues:
                    &issues
            )


            if !isValidWebURL(
                content.urlString
            ) {

                issues.append(
                    GameNodeValidationIssue(
                        id:
                            "hyperlink.url.invalid",
                        message:
                            "Link URL must be a valid http or https URL."
                    )
                )
            }
        }
    }
}

// =====================================================
// MARK: - Validation Helpers
// =====================================================

private extension GameNodeValidator {

    static func requireText(
        _ value: String,
        fieldName: String,
        id: String,
        issues: inout [GameNodeValidationIssue]
    ) {

        let trimmed =
            value.trimmingCharacters(
                in:
                    .whitespacesAndNewlines
            )


        guard
            !trimmed.isEmpty
        else {

            issues.append(
                GameNodeValidationIssue(
                    id:
                        id,
                    message:
                        "\(fieldName) is required."
                )
            )

            return
        }
    }


    static func isValidWebURL(
        _ value: String
    ) -> Bool {

        let trimmed =
            value.trimmingCharacters(
                in:
                    .whitespacesAndNewlines
            )


        guard
            let components =
                URLComponents(
                    string:
                        trimmed
                ),

            let scheme =
                components.scheme?
                    .lowercased(),

            scheme == "http"
            ||
            scheme == "https",

            let host =
                components.host,

            !host.isEmpty
        else {

            return false
        }


        return true
    }
}

// =====================================================
// MARK: - Image Validation
// =====================================================

private extension GameNodeValidator {

    static func validateImage(
        _ image: GameNodeImage?,
        issues: inout [GameNodeValidationIssue]
    ) {

        guard let image else {

            return
        }


        switch image {

        // =========================================
        // Asset
        // =========================================

        case let .asset(
            name
        ):

            if
                name
                    .trimmingCharacters(
                        in:
                            .whitespacesAndNewlines
                    )
                    .isEmpty
            {

                issues.append(
                    GameNodeValidationIssue(
                        id:
                            "image.asset.empty",
                        message:
                            "Asset image name cannot be empty."
                    )
                )
            }


        // =========================================
        // Legacy SF Symbol
        // =========================================

        case .systemSymbol:

            issues.append(
                GameNodeValidationIssue(
                    id:
                        "image.symbol.legacy",
                    severity:
                        .warning,
                    message:
                        "SF Symbol marker images are legacy. This node will render its type-specific placeholder until you choose an Asset or Remote image."
                )
            )


        // =========================================
        // Remote
        // =========================================

        case let .remote(
            urlString
        ):

            if !isValidWebURL(
                urlString
            ) {

                issues.append(
                    GameNodeValidationIssue(
                        id:
                            "image.remote.invalid",
                        message:
                            "Remote image must use a valid http or https URL."
                    )
                )
            }
        }
    }
}

// =====================================================
// MARK: - Placement Validation
// =====================================================

private extension GameNodeValidator {

    static func validatePlacement(
        _ placement: GameNodePlacement,
        roadGraph: RoadGraph,
        issues: inout [GameNodeValidationIssue]
    ) {

        switch placement {

        // =========================================
        // Coordinate
        // =========================================

        case let .coordinate(
            coordinate
        ):

            let progress =
                coordinate
                    .progress
                    .percent


            guard
                progress.isFinite
            else {

                issues.append(
                    GameNodeValidationIssue(
                        id:
                            "placement.progress.invalid",
                        message:
                            "Progress must be a valid number."
                    )
                )

                return
            }


            /*
             Negative and >100 values are intentionally
             valid in the Fifoo map.

             Warn only when the value is outside the
             currently explorable domain.
             */

            if
                progress <
                    MapWorldConfiguration
                        .minimumExplorableProgress

                ||

                progress >
                    MapWorldConfiguration
                        .maximumExplorableProgress
            {

                issues.append(
                    GameNodeValidationIssue(
                        id:
                            "placement.progress.outsideExplorableRange",
                        severity:
                            .warning,
                        message:
                            "This node is outside the currently explorable progress range."
                    )
                )
            }


        // =========================================
        // Road Vertex
        // =========================================

        case let .roadVertex(
            vertexID
        ):

            guard let vertex =
                roadGraph.vertex(
                    id:
                        vertexID
                )
            else {

                issues.append(
                    GameNodeValidationIssue(
                        id:
                            "placement.vertex.missing",
                        message:
                            "The selected road intersection no longer exists."
                    )
                )

                return
            }


            if !isAttachable(
                vertex
            ) {

                issues.append(
                    GameNodeValidationIssue(
                        id:
                            "placement.vertex.unsupported",
                        message:
                            "This road point cannot be used for node placement."
                    )
                )
            }
        }
    }


    static func isAttachable(
        _ vertex: RoadVertex
    ) -> Bool {

        switch vertex.kind {

        case .intersection,
             .junction,
             .circleEntry,
             .circleExit,
             .culDeSacEnd:

            return true


        case .control:

            return false
        }
    }
}
