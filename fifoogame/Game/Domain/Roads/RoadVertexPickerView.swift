//
//  RoadVertexPickerView.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/19/26.
//

import SwiftUI


struct RoadVertexPickerView: View {

    let graph:
        RoadGraph


    let selectedVertexID:
        RoadVertexID?


    let onSelect:
        (RoadVertexID) -> Void


    @Environment(\.dismiss)
    private var dismiss


    @State
    private var searchText =
        ""


    var body: some View {

        NavigationStack {

            List(
                filteredVertices
            ) { vertex in

                Button {

                    onSelect(
                        vertex.id
                    )


                    dismiss()

                } label: {

                    RoadVertexPickerRow(
                        graph:
                            graph,
                        vertex:
                            vertex,
                        isSelected:
                            vertex.id ==
                            selectedVertexID
                    )
                }
                .buttonStyle(
                    .plain
                )
            }
            .navigationTitle(
                "Choose Intersection"
            )
            .navigationBarTitleDisplayMode(
                .inline
            )
            .searchable(
                text:
                    $searchText,
                prompt:
                    "Time, progress, or road"
            )
            .toolbar {

                ToolbarItem(
                    placement:
                        .cancellationAction
                ) {

                    Button(
                        "Cancel"
                    ) {

                        dismiss()
                    }
                }
            }
        }
    }
}

private extension RoadVertexPickerView {

    var attachableVertices:
        [RoadVertex] {

        graph.vertices
            .filter {

                switch $0.kind {

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
            .sorted {

                if $0.coordinate.time !=
                    $1.coordinate.time {

                    return $0.coordinate.time <
                        $1.coordinate.time
                }


                return $0.coordinate
                    .progress
                    .percent
                    <
                    $1.coordinate
                        .progress
                        .percent
            }
    }


    var filteredVertices:
        [RoadVertex] {

        let trimmed =
            searchText
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )


        guard
            !trimmed.isEmpty
        else {

            return attachableVertices
        }


        let query =
            trimmed.lowercased()


        return attachableVertices
            .filter { vertex in

                searchableText(
                    for:
                        vertex
                )
                .lowercased()
                .contains(
                    query
                )
            }
    }


    func searchableText(
        for vertex:
            RoadVertex
    ) -> String {

        let connectedRoadNames =
            graph
                .incidentEdges(
                    to:
                        vertex.id,
                    traversableOnly:
                        false
                )
                .compactMap {

                    $0.attributes
                        .displayName
                }
                .joined(
                    separator:
                        " "
                )


        return """
        \(vertex.id.rawValue)
        \(vertex.kind.rawValue)
        \(vertex.coordinate.time.displayClockString)
        \(vertex.coordinate.progress.percent)
        \(connectedRoadNames)
        """
    }
}

private struct RoadVertexPickerRow:
    View {

    let graph:
        RoadGraph


    let vertex:
        RoadVertex


    let isSelected:
        Bool


    var body: some View {

        HStack(
            spacing:
                12
        ) {

            Image(
                systemName:
                    icon
            )
            .font(
                .title3
            )
            .frame(
                width:
                    30
            )


            VStack(
                alignment:
                    .leading,
                spacing:
                    4
            ) {

                Text(
                    title
                )
                .font(
                    .headline
                )


                HStack(
                    spacing:
                        6
                ) {

                    Text(
                        vertex.coordinate
                            .time
                            .displayClockString
                    )


                    Text(
                        "•"
                    )


                    Text(
                        vertex.coordinate
                            .progress
                            .percent,
                        format:
                            .number
                            .precision(
                                .fractionLength(
                                    1
                                )
                            )
                    )


                    Text(
                        "%"
                    )
                }
                .font(
                    .caption
                )
                .foregroundStyle(
                    .secondary
                )


                if !roadNames.isEmpty {

                    Text(
                        roadNames
                    )
                    .font(
                        .caption2
                    )
                    .foregroundStyle(
                        .secondary
                    )
                    .lineLimit(
                        1
                    )
                }
            }


            Spacer()


            if isSelected {

                Image(
                    systemName:
                        "checkmark.circle.fill"
                )
            }
        }
        .contentShape(
            Rectangle()
        )
        .padding(
            .vertical,
            4
        )
    }
}

private extension RoadVertexPickerRow {

    var connectedEdges:
        [RoadEdge] {

        graph.incidentEdges(
            to:
                vertex.id,
            traversableOnly:
                false
        )
    }


    var roadNames:
        String {

        let names =
            connectedEdges
                .compactMap {

                    $0.attributes
                        .displayName
                }
                .filter {

                    !$0.isEmpty
                }


        return Array(
            Set(
                names
            )
        )
        .sorted()
        .joined(
            separator:
                " / "
        )
    }


    var title:
        String {

        if !roadNames.isEmpty {

            return roadNames
        }


        switch vertex.kind {

        case .intersection:

            return "Intersection"


        case .junction:

            return "Road Junction"


        case .circleEntry:

            return "Roundabout Entry"


        case .circleExit:

            return "Roundabout Exit"


        case .culDeSacEnd:

            return "Cul-de-sac"


        case .control:

            return "Road Point"
        }
    }


    var icon:
        String {

        switch vertex.kind {

        case .intersection:

            return "plus"


        case .junction:

            return "arrow.triangle.branch"


        case .circleEntry,
             .circleExit:

            return "arrow.trianglehead.2.clockwise.rotate.90"


        case .culDeSacEnd:

            return "arrow.uturn.backward"


        case .control:

            return "circle"
        }
    }
}
