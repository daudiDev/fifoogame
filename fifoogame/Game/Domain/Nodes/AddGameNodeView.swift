//
//  AddGameNodeView.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/19/26.
//


import SwiftUI


struct AddGameNodeView: View {

    let initialCoordinate:
        MapCoordinate


    let roadGraph:
        RoadGraph


    let onAdd:
        (GameMapNode) -> Void


    @Environment(\.dismiss)
    private var dismiss


    var body: some View {

        NavigationStack {

            List {

                Section {

                    ForEach(
                        GameNodeKind.allCases,
                        id:
                            \.self
                    ) { kind in

                        NavigationLink {

                            NewGameNodeEditorScreen(
                                kind:
                                    kind,
                                initialCoordinate:
                                    initialCoordinate,
                                roadGraph:
                                    roadGraph,
                                onAdd:
                                    onAdd
                            )

                        } label: {

                            GameNodeKindRow(
                                kind:
                                    kind
                            )
                        }
                    }

                } header: {

                    Text(
                        "Choose Node Type"
                    )

                } footer: {

                    Text(
                        "Choose the type of content you want to place on the day map."
                    )
                }
            }
            .navigationTitle(
                "Add Node"
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
                        "Cancel"
                    ) {

                        dismiss()
                    }
                }
            }
        }
    }
}

private struct GameNodeKindRow: View {

    let kind:
        GameNodeKind


    var body: some View {

        HStack(
            spacing:
                14
        ) {

            Image(
                systemName:
                    kind.systemImageName
            )
            .font(
                .title2
            )
            .frame(
                width:
                    36,
                height:
                    36
            )


            VStack(
                alignment:
                    .leading,
                spacing:
                    3
            ) {

                Text(
                    kind.displayName
                )
                .font(
                    .headline
                )


                Text(
                    kind.description
                )
                .font(
                    .caption
                )
                .foregroundStyle(
                    .secondary
                )
            }


            Spacer()
        }
        .padding(
            .vertical,
            4
        )
    }
}

private struct NewGameNodeEditorScreen: View {

    let roadGraph:
        RoadGraph


    let onAdd:
        (GameMapNode) -> Void


    @State
    private var draft:
        GameMapNode


    init(
        kind: GameNodeKind,
        initialCoordinate: MapCoordinate,
        roadGraph: RoadGraph,
        onAdd: @escaping (GameMapNode) -> Void
    ) {

        self.roadGraph =
            roadGraph


        self.onAdd =
            onAdd


        _draft =
            State(
                initialValue:
                    GameNodeFactory.make(
                        kind:
                            kind,
                        coordinate:
                            initialCoordinate
                    )
            )
    }


    var body: some View {

        GameNodeEditorForm(
            node:
                $draft,
            roadGraph:
                roadGraph,
            validationIssues:
                validation
                    .issues
        )
        .navigationTitle(
            "New \(draft.content.kind.displayName)"
        )
        .navigationBarTitleDisplayMode(
            .inline
        )
        .toolbar {

            ToolbarItem(
                placement:
                    .confirmationAction
            ) {

                Button(
                    "Add"
                ) {

                    guard
                        validation.isValid
                    else {

                        return
                    }

                    let normalized =
                        GameNodeNormalizer
                            .normalize(
                                draft
                            )


                    guard
                        GameNodeValidator
                            .validate(
                                normalized,
                                roadGraph:
                                    roadGraph
                            )
                            .isValid
                    else {

                        return
                    }


                    onAdd(
                        normalized
                    )
                    
                    
                }
                .fontWeight(
                    .semibold
                )
                .disabled(
                    !validation.isValid
                )
            }
        }
    }
}

private extension NewGameNodeEditorScreen {

    var validation:
        GameNodeValidationResult {

        GameNodeValidator.validate(
            draft,
            roadGraph:
                roadGraph
        )
    }
}
