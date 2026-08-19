//
//  GameNodeEditorView.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/19/26.
//


import SwiftUI


struct GameNodeEditorView: View {

    // =====================================================
    // MARK: - Original + Draft
    // =====================================================

    private let originalNode:
        GameMapNode


    @State
    private var draft:
        GameMapNode


    // =====================================================
    // MARK: - Input
    // =====================================================

    let roadGraph:
        RoadGraph


    let onSave:
        (GameMapNode) -> Void


    let onDelete:
        (() -> Void)?


    // =====================================================
    // MARK: - State
    // =====================================================

    @State
    private var isShowingDeleteConfirmation =
        false


    @State
    private var isShowingDiscardConfirmation =
        false


    @Environment(\.dismiss)
    private var dismiss


    // =====================================================
    // MARK: - Init
    // =====================================================

    init(
        node: GameMapNode,
        roadGraph: RoadGraph,
        onSave: @escaping (GameMapNode) -> Void,
        onDelete: (() -> Void)? = nil
    ) {

        self.originalNode =
            node


        _draft =
            State(
                initialValue:
                    node
            )


        self.roadGraph =
            roadGraph


        self.onSave =
            onSave


        self.onDelete =
            onDelete
    }


    // =====================================================
    // MARK: - Body
    // =====================================================

    var body: some View {

        NavigationStack {

            VStack(
                spacing:
                    0
            ) {

                GameNodeEditorForm(
                    node:
                        $draft,
                    roadGraph:
                        roadGraph,
                    validationIssues:
                        validation
                            .issues
                )


                if onDelete != nil {

                    deleteButton
                }
            }
            .navigationTitle(
                "Edit \(draft.content.kind.displayName)"
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

                        attemptCancel()
                    }
                }


                ToolbarItem(
                    placement:
                        .confirmationAction
                ) {

                    Button(
                        "Save"
                    ) {

                        save()
                    }
                    .fontWeight(
                        .semibold
                    )
                    .disabled(
                        !canSave
                    )
                }
            }
            .interactiveDismissDisabled(
                hasUnsavedChanges
            )
            .confirmationDialog(
                "Discard changes?",
                isPresented:
                    $isShowingDiscardConfirmation,
                titleVisibility:
                    .visible
            ) {

                Button(
                    "Discard Changes",
                    role:
                        .destructive
                ) {

                    dismiss()
                }


                Button(
                    "Keep Editing",
                    role:
                        .cancel
                ) {

                }

            } message: {

                Text(
                    "Your unsaved changes will be lost."
                )
            }
            .confirmationDialog(
                "Delete this node?",
                isPresented:
                    $isShowingDeleteConfirmation,
                titleVisibility:
                    .visible
            ) {

                Button(
                    "Delete Node",
                    role:
                        .destructive
                ) {

                    onDelete?()

                    dismiss()
                }


                Button(
                    "Cancel",
                    role:
                        .cancel
                ) {

                }

            } message: {

                Text(
                    "This removes the node from the map."
                )
            }
        }
    }
}


private extension GameNodeEditorView {

    var validation:
        GameNodeValidationResult {

        GameNodeValidator.validate(
            draft,
            roadGraph:
                roadGraph
        )
    }


    var hasUnsavedChanges:
        Bool {

        draft !=
            originalNode
    }


    var canSave:
        Bool {

        validation.isValid
        &&
        hasUnsavedChanges
    }


    func save() {

        let normalized =
            GameNodeNormalizer
                .normalize(
                    draft
                )


        let result =
            GameNodeValidator
                .validate(
                    normalized,
                    roadGraph:
                        roadGraph
                )


        guard
            result.isValid
        else {

            return
        }


        onSave(
            normalized
        )


        dismiss()
    }


    func attemptCancel() {

        if hasUnsavedChanges {

            isShowingDiscardConfirmation =
                true

        } else {

            dismiss()
        }
    }
}

private extension GameNodeEditorView {

    var deleteButton: some View {

        Button(
            role:
                .destructive
        ) {

            isShowingDeleteConfirmation =
                true

        } label: {

            Label(
                "Delete Node",
                systemImage:
                    "trash"
            )
            .fontWeight(
                .semibold
            )
            .frame(
                maxWidth:
                    .infinity
            )
            .padding(
                .vertical,
                12
            )
        }
        .padding(
            .horizontal
        )
        .padding(
            .bottom
        )
    }
}
