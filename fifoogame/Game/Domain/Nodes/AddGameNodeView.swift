//
//  AddGameNodeView 2.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/25/26.
//


import SwiftUI


struct AddGameNodeView: View {

    let initialCoordinate:
        MapCoordinate


    let roadGraph:
        RoadGraph


    let onAdd:
        (GameMapNode) -> Void


    var body: some View {

        NavigationStack {
            VStack {
                HStack {
                    Spacer()
                    Text("Add Stop to Path")
                        .font(.title)
                        .foregroundStyle(.white)
                        .padding(.vertical)
                    Spacer()
                }
                
                Spacer()
                // Row 1 — Meal / Workout
                HStack {
                    
                    Spacer()
                    AddGameNodeEmojiButton(
                        addType:
                                .meal,
                        emoji:
                            "🍲"
                    )
                    Spacer()
                    
                    AddGameNodeEmojiButton(
                        addType:
                                .workout,
                        emoji:
                            "🏋🏻‍♂️"
                    )
                    
                    Spacer()
                }
                
                Spacer()
                
                // Row 2 — Task
                HStack {
                    
                    Spacer()
                    
                    
                    AddGameNodeEmojiButton(
                        addType:
                                .task,
                        emoji:
                            "🤹"
                    )
                    
                    
                    Spacer()
                }
                
                Spacer()
                
                // Row 3 — Tip / Request
                HStack {
                    Spacer()
                    AddGameNodeEmojiButton(
                        addType:
                                .tip,
                        emoji:
                            "📢"
                    )
                    
                    Spacer()
                    
                    AddGameNodeEmojiButton(
                        addType:
                                .request,
                        emoji:
                            "✋"
                    )
                    Spacer()
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
            .background( Color(red: 26 / 255, green: 38 / 255, blue: 50 / 255))
            .navigationTitle(
                            "|||||||||||||||"
                        )
                        .navigationBarTitleDisplayMode(
                            .inline
                        )
            .navigationDestination(
                for:
                    AddGameNodeType.self
            ) { addType in
                
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
            }
        }
    }
}


private struct AddGameNodeEmojiButton: View {

    let addType:
        AddGameNodeType


    let emoji:
        String


    var body: some View {

        NavigationLink(
            value:
                addType
        ) {

            Text(
                emoji
            )
            .font(
                .system(
                    size:
                        70
                )
            )
            .frame(
                width:
                    124,
                height:
                    124
            )
            .background(
                RoundedRectangle(
                    cornerRadius:
                        30,
                    style:
                        .continuous
                )
                .fill(
                    .ultraThickMaterial
                )
            )
            .overlay {

                RoundedRectangle(
                    cornerRadius:
                        30,
                    style:
                        .continuous
                )
                .stroke(
                    .primary
                        .opacity(
                            0.08
                        ),
                    lineWidth:
                        1
                )
            }
            .shadow(
                color:
                    .black
                        .opacity(
                            0.08
                        ),
                radius:
                    10,
                x:
                    0,
                y:
                    6
            )
        }
        .buttonStyle(
            .plain
        )
        .accessibilityLabel(
            addType.displayName
        )
    }
}


private struct NewGameNodeEditorScreen: View {

    let addType:
        AddGameNodeType


    let initialCoordinate:
        MapCoordinate


    let roadGraph:
        RoadGraph


    let onAdd:
        (GameMapNode) -> Void


    @State
    private var draft:
        GameMapNode


    @State
    private var didRecordTypeSelection =
        false


    init(
        addType: AddGameNodeType,
        initialCoordinate: MapCoordinate,
        roadGraph: RoadGraph,
        onAdd: @escaping (GameMapNode) -> Void
    ) {

        self.addType =
            addType


        self.initialCoordinate =
            initialCoordinate


        self.roadGraph =
            roadGraph


        self.onAdd =
            onAdd


        _draft =
            State(
                initialValue:
                    SocketManager.shared
                        .makeNewGameNodeDraft(
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
        .onAppear {

            guard
                !didRecordTypeSelection
            else {

                return
            }

            didRecordTypeSelection =
                true

            SocketManager.shared
                .nodeCreationTypeSelected(
                    addType:
                        addType,
                    coordinate:
                        initialCoordinate
                )
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
