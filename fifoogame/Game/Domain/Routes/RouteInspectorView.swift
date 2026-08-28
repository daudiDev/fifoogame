//
//  RouteInspectorView.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/24/26.
//


import SwiftUI
import UIKit


struct RouteInspectorView: View {

    let target:
        RouteInteractionTarget


    let inspectedRoute:
        GameRoute?


    let completedRoute:
        CompletedRoute


    /// Current game-node snapshots used to resolve the route's node IDs
    /// into the image/title/time rows shown by this inspector.
    let gameNodes:
        [GameMapNode]


    let onChoose:
        ((RouteID) -> Bool)?


    @Environment(\.dismiss)
    private var dismiss


    @State
    private var routeSwitchFailed =
        false


    var body: some View {

        NavigationStack {

            List {

                switch target {

                case .completed:

                    routeNodeSection(
                        title: "Completed Stops",
                        nodes: completedNodes,
                        emptyMessage: "No completed stops yet."
                    )


                case .chosen:

                    routeNodeSection(
                        title: "Completed Stops",
                        nodes: completedNodes,
                        emptyMessage: "No completed stops yet."
                    )


                    routeNodeSection(
                        title: "Chosen Stops",
                        nodes: inspectedNodes,
                        emptyMessage: "No stops are available on the chosen path."
                    )


                case .alternative:

                    routeNodeSection(
                        title: "Completed Stops",
                        nodes: completedNodes,
                        emptyMessage: "No completed stops yet."
                    )


                    routeNodeSection(
                        title: "Alternate Stops",
                        nodes: inspectedNodes,
                        emptyMessage: "No stops are available on this alternate path."
                    )
                }
            }
            .listStyle(
                .insetGrouped
            )
            .navigationTitle(
                title
            )
            .navigationBarTitleDisplayMode(
                .inline
            )
            .toolbar {

                ToolbarItem(
                    placement:
                        .cancellationAction
                ) {

                    Button(
                        "Exit"
                    ) {

                        dismiss()
                    }
                }


                if case let .alternative(
                    routeID
                ) = target {

                    ToolbarItem(
                        placement:
                            .confirmationAction
                    ) {

                        Button(
                            "Select"
                        ) {

                            selectAlternativeRoute(
                                routeID
                            )
                        }
                        .fontWeight(
                            .semibold
                        )
                        .disabled(
                            inspectedRoute == nil
                        )
                    }
                }
            }
            .alert(
                "Path Cannot Be Selected",
                isPresented:
                    $routeSwitchFailed
            ) {

                Button(
                    "OK",
                    role:
                        .cancel
                ) {

                }

            } message: {

                Text(
                    "This path no longer connects to your current completed-path position."
                )
            }
        }
    }
}


// =====================================================
// MARK: - Title
// =====================================================

private extension RouteInspectorView {

    var title:
        String {

        switch target {

        case .completed:

            return "Completed Path"


        case .chosen:

            return "Chosen Path"


        case .alternative:

            return "Alternate Path"
        }
    }
}


// =====================================================
// MARK: - Route Nodes
// =====================================================

private extension RouteInspectorView {

    var completedNodes:
        [GameMapNode] {

        nodes(
            for:
                completedRoute
                    .reachedNodeIDs
        )
    }


    var inspectedNodes:
        [GameMapNode] {

        guard let inspectedRoute
        else {

            return []
        }


        return nodes(
            for:
                inspectedRoute
                    .stopNodeIDs
        )
    }


    /// Preserves the exact route order rather than sorting by map time.
    /// This matters if route construction intentionally contains stops at
    /// the same time or a route's logical order differs from time ordering.
    func nodes(
        for nodeIDs:
            [GameNodeID]
    ) -> [GameMapNode] {

        let byID =
            Dictionary(
                uniqueKeysWithValues:
                    gameNodes.map {
                        (
                            $0.id,
                            $0
                        )
                    }
            )


        return nodeIDs.compactMap {
            byID[
                $0
            ]
        }
    }
}


// =====================================================
// MARK: - Sections
// =====================================================

private extension RouteInspectorView {

    @ViewBuilder
    func routeNodeSection(
        title: String,
        nodes: [GameMapNode],
        emptyMessage: String
    ) -> some View {

        Section(
            title
        ) {

            if nodes.isEmpty {

                Text(
                    emptyMessage
                )
                .font(
                    .callout
                )
                .foregroundStyle(
                    .secondary
                )

            } else {

                ForEach(
                    nodes
                ) { node in

                    RouteInspectorNodeRow(
                        node:
                            node
                    )
                }
            }
        }
    }
}


// =====================================================
// MARK: - Alternate Selection
// =====================================================

private extension RouteInspectorView {

    func selectAlternativeRoute(
        _ routeID:
            RouteID
    ) {

        let succeeded =
            onChoose?(
                routeID
            )
            ??
            false


        if succeeded {

            dismiss()

        } else {

            routeSwitchFailed =
                true
        }
    }
}


// =====================================================
// MARK: - Node Row
// =====================================================

private struct RouteInspectorNodeRow: View {

    let node:
        GameMapNode


    var body: some View {

        HStack(
            spacing:
                12
        ) {

            RouteInspectorNodeImage(
                kind:
                    node.content.kind,
                image:
                    node.content.image
            )


            VStack(
                alignment:
                    .leading,
                spacing:
                    4
            ) {

                Text(
                    resolvedTitle
                )
                .font(
                    .body
                )
                .fontWeight(
                    .semibold
                )
                .lineLimit(
                    1
                )
                .truncationMode(
                    .tail
                )


                Text(
                    node.time
                        .displayClockString
                )
                .font(
                    .caption
                )
                .foregroundStyle(
                    .secondary
                )
            }


            Spacer(
                minLength:
                    0
            )
        }
        .padding(
            .vertical,
            3
        )
    }


    private var resolvedTitle:
        String {

        let cleaned =
            node.content.title
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )


        return cleaned.isEmpty
            ? node.content.kind.rawValue.capitalized
            : cleaned
    }
}


// =====================================================
// MARK: - Node Image
// =====================================================

private struct RouteInspectorNodeImage: View {

    let kind:
        GameNodeKind


    let image:
        GameNodeImage?


    private let size:
        CGFloat = 44


    var body: some View {

        resolvedImage
            .frame(
                width:
                    size,
                height:
                    size
            )
            .clipShape(
                Circle()
            )
            .overlay {

                Circle()
                    .stroke(
                        .secondary.opacity(
                            0.22
                        ),
                        lineWidth:
                            1
                    )
            }
    }


    @ViewBuilder
    private var resolvedImage:
        some View {

        switch image {

        case let .asset(
            name
        ):

            if let uiImage =
                UIImage(
                    named:
                        name
                )
            {

                Image(
                    uiImage:
                        uiImage
                )
                .resizable()
                .scaledToFill()

            } else {

                placeholder
            }


        case let .remote(
            urlString
        ):

            if let url =
                URL(
                    string:
                        urlString
                )
            {

                AsyncImage(
                    url:
                        url
                ) { phase in

                    switch phase {

                    case .empty:

                        ZStack {

                            placeholder


                            ProgressView()
                                .scaleEffect(
                                    0.7
                                )
                        }


                    case let .success(
                        image
                    ):

                        image
                            .resizable()
                            .scaledToFill()


                    case .failure:

                        placeholder


                    @unknown default:

                        placeholder
                    }
                }

            } else {

                placeholder
            }


        case .systemSymbol,
             nil:

            placeholder
        }
    }


    private var placeholder:
        some View {

        Image(
            uiImage:
                GameNodePlaceholderImage.image(
                    for:
                        kind
                )
        )
        .resizable()
        .scaledToFill()
    }
}
