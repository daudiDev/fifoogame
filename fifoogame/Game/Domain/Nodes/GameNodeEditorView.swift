//
//  GameNodeEditorView.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/24/26.
//



import SwiftUI


enum ActivityNodeEditorAction:
    Equatable,
    Sendable {

    /// Used when the Activity is not already part of the user's chosen path.
    /// Joining is intentionally exposed to the host app instead of inventing a
    /// route mutation inside the node editor.
    case join
    case skip
    case completed


    /// Only status-changing Activity actions map to an Activity status value.
    /// `join` is a navigation/domain action and does not rewrite the snapshot
    /// status by itself.
    var statusValue: String? {

        switch self {

        case .join:

            return nil

        case .skip:

            return "Skipped"

        case .completed:

            return "Completed"
        }
    }
}


/// User-specific bottom actions. The map layer exposes these as hooks so the
/// host application can open its real conversation or progress experience.
enum UserNodeEditorAction:
    Equatable,
    Sendable {

    case sendMessage
    case viewProgress
}


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


    /// Optional application-level hook for Activity-specific actions.
    ///
    /// The editor always updates the map node locally through `onSave`.
    /// This callback is where the parent app can later call its Activity API,
    /// SocketManager, ActivityManager, etc. without coupling the map domain to
    /// those systems.
    let onActivityAction:
        ((ActivityNodeEditorAction, GameMapNode) -> Void)?


    /// True when this Activity is already part of the user's active chosen
    /// path. The chosen path includes both completed history and the currently
    /// chosen future route. Off-path Activity nodes show Join instead of
    /// Skip/Completed.
    let isActivityOnChosenPath:
        Bool


    /// Optional application-level hook for User-specific navigation/actions.
    /// Use this to open the real messaging flow or user progress screen.
    let onUserAction:
        ((UserNodeEditorAction, GameMapNode) -> Void)?


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
        onDelete: (() -> Void)? = nil,
        onActivityAction: ((ActivityNodeEditorAction, GameMapNode) -> Void)? = nil,
        isActivityOnChosenPath: Bool = true,
        onUserAction: ((UserNodeEditorAction, GameMapNode) -> Void)? = nil
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


        self.onActivityAction =
            onActivityAction


        self.isActivityOnChosenPath =
            isActivityOnChosenPath


        self.onUserAction =
            onUserAction
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


                bottomActionSection
            }
            .navigationTitle(
                navigationTitle
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


// =====================================================
// MARK: - Navigation Title
// =====================================================

private extension GameNodeEditorView {

    var navigationTitle: String {

        switch draft.content.kind {

        case .activity:

            return "Activity"

        case .user:

            return "User"

        default:

            return "Edit \(draft.content.kind.displayName)"
        }
    }
}


// =====================================================
// MARK: - Validation / Save
// =====================================================

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


    func normalizedValidatedDraft() -> GameMapNode? {

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


        guard result.isValid
        else {

            return nil
        }


        return normalized
    }


    func save() {

        guard let normalized =
            normalizedValidatedDraft()
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


// =====================================================
// MARK: - Bottom Actions
// =====================================================

private extension GameNodeEditorView {

    @ViewBuilder
    var bottomActionSection: some View {

        switch draft.content.kind {

        case .activity:

            if isActivityOnChosenPath {

                activityActionButtons

            } else {

                activityJoinButton
            }

        case .user:

            userActionButtons

        default:

            // Temporary legacy behavior while the unique button pairs for
            // the remaining node kinds are defined one by one.
            if onDelete != nil {

                deleteButton
            }
        }
    }


    var activityJoinButton: some View {

        Button {

            performActivityAction(
                .join
            )

        } label: {

            Text(
                "Join"
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
        .buttonStyle(
            .borderedProminent
        )
        .tint(
            .blue
        )
        .disabled(
            !validation.isValid
        )
        .padding(
            .horizontal
        )
        .padding(
            .top,
            10
        )
        .padding(
            .bottom
        )
        .background(
            .bar
        )
    }


    var activityActionButtons: some View {

        HStack(
            spacing:
                12
        ) {

            Button {

                performActivityAction(
                    .skip
                )

            } label: {

                Text(
                    "Skip"
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
            .buttonStyle(
                .bordered
            )
            .tint(
                .orange
            )
            .disabled(
                !validation.isValid
            )


            Button {

                performActivityAction(
                    .completed
                )

            } label: {

                Text(
                    "Completed"
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
            .buttonStyle(
                .borderedProminent
            )
            .tint(
                .green
            )
            .disabled(
                !validation.isValid
            )
        }
        .padding(
            .horizontal
        )
        .padding(
            .top,
            10
        )
        .padding(
            .bottom
        )
        .background(
            .bar
        )
    }


    func performActivityAction(
        _ action:
            ActivityNodeEditorAction
    ) {

        // =================================================
        // Join
        // =================================================
        // Joining an off-path Activity is not the same thing as changing its
        // completion status. Preserve any draft edits, then hand the Join
        // intent to the host application. The host can join the Activity and/or
        // rebuild the chosen route using its existing domain/network layer.
        if action == .join {

            guard let normalized =
                normalizedValidatedDraft()
            else {

                return
            }


            if normalized != originalNode {

                onSave(
                    normalized
                )
            }


            guard let onActivityAction
            else {

                // Without a host Join handler, keep the sheet open instead of
                // making the button appear to succeed while doing nothing.
                return
            }


            onActivityAction(
                .join,
                normalized
            )


            dismiss()

            return
        }


        // =================================================
        // Skip / Completed
        // =================================================

        var updated =
            draft


        guard
            case var .activity(
                content
            ) = updated.content,
            let statusValue =
                action.statusValue
        else {

            return
        }


        content.status =
            statusValue


        updated.content =
            .activity(
                content
            )


        let normalized =
            GameNodeNormalizer
                .normalize(
                    updated
                )


        let result =
            GameNodeValidator
                .validate(
                    normalized,
                    roadGraph:
                        roadGraph
                )


        guard result.isValid
        else {

            return
        }


        draft =
            normalized


        // Always persist the changed node in map state.
        onSave(
            normalized
        )


        // Optional hook for the application's real Activity status update.
        onActivityAction?(
            action,
            normalized
        )


        dismiss()
    }


    var userActionButtons: some View {

        HStack(
            spacing:
                12
        ) {

            Button {

                performUserAction(
                    .sendMessage
                )

            } label: {

                Text(
                    "Send Message"
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
            .buttonStyle(
                .bordered
            )
            .tint(
                .blue
            )
            .disabled(
                !validation.isValid
            )


            Button {

                performUserAction(
                    .viewProgress
                )

            } label: {

                Text(
                    "View Progress"
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
            .buttonStyle(
                .borderedProminent
            )
            .tint(
                .blue
            )
            .disabled(
                !validation.isValid
            )
        }
        .padding(
            .horizontal
        )
        .padding(
            .top,
            10
        )
        .padding(
            .bottom
        )
        .background(
            .bar
        )
    }


    func performUserAction(
        _ action:
            UserNodeEditorAction
    ) {

        guard let normalized =
            normalizedValidatedDraft()
        else {
            return
        }


        // Preserve an edited map time before leaving the editor. Profile data
        // itself is a read-only snapshot on this screen.
        if hasUnsavedChanges {
            onSave(
                normalized
            )
        }


        guard let onUserAction
        else {

            // The host app has not wired messaging/progress navigation yet.
            // Keep the editor open rather than dismissing into a no-op.
            return
        }


        onUserAction(
            action,
            normalized
        )


        dismiss()
    }


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
