//
//  AddGameNodeView.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/24/26.
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

                ForEach(
                    AddGameNodeType.allCases
                ) { addType in

                    Section {

                        NavigationLink {

                            NewGameNodeEditorScreen(
                                addType:
                                    addType,
                                initialCoordinate:
                                    initialCoordinate,
                                roadGraph:
                                    roadGraph,
                                onAdd:
                                    onAdd
                            )

                        } label: {

                            AddGameNodeTypeRow(
                                addType:
                                    addType
                            )
                        }

                    } header: {

                        Text(
                            addType.displayName
                        )

                    } footer: {

                        Text(
                            addType.description
                        )
                    }
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


private struct AddGameNodeTypeRow: View {

    let addType:
        AddGameNodeType


    var body: some View {

        HStack(
            spacing:
                14
        ) {

            Image(
                systemName:
                    addType.systemImageName
            )
            .font(
                .system(
                    size:
                        20,
                    weight:
                        .semibold
                )
            )
            .frame(
                width:
                    40,
                height:
                    40
            )
            .background(
                Circle()
                    .fill(
                        .secondary
                            .opacity(
                                0.12
                            )
                    )
            )


            VStack(
                alignment:
                    .leading,
                spacing:
                    3
            ) {

                Text(
                    "Add \(addType.displayName)"
                )
                .font(
                    .headline
                )


                Text(
                    addType.backingModelDescription
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

    let addType:
        AddGameNodeType


    let roadGraph:
        RoadGraph


    let onAdd:
        (GameMapNode) -> Void


    @State
    private var draft:
        GameMapNode


    init(
        addType: AddGameNodeType,
        initialCoordinate: MapCoordinate,
        roadGraph: RoadGraph,
        onAdd: @escaping (GameMapNode) -> Void
    ) {

        self.addType =
            addType


        self.roadGraph =
            roadGraph


        self.onAdd =
            onAdd


        _draft =
            State(
                initialValue:
                    GameNodeFactory.make(
                        addType:
                            addType,
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
            "New \(addType.displayName)"
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
