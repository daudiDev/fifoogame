//
//  DayMapView.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/25/26.
//



import SwiftUI
import SpriteKit


struct DayMapView: View {
    
    private let socketManager = SocketManager.shared

    // MARK: - Environment
    @Environment(\.scenePhase)
    private var scenePhase
    
    @State
    private var presentedNodeID:
        GameNodeID?


    @State
    private var presentedActivityMealNodeID:
        GameNodeID?


    @State
    private var presentedActivityWorkoutNodeID:
        GameNodeID?


    @State
    private var presentedActivityTaskNodeID:
        GameNodeID?


    /// Non-nil only while Fifoo Play was opened from an independent
    /// ActivityWorkout stop. Generic Play entry points leave this nil.
    @State
    private var activeIndependentWorkoutNodeID:
        GameNodeID?


    @State
    private var presentedIndependentWorkoutBrowseNodeID:
        GameNodeID?


    @State
    private var presentedIndependentWorkoutClassBrowseNodeID:
        GameNodeID?


    @State
    private var presentedIndependentWorkoutTimeNodeID:
        GameNodeID?


    @State
    private var presentedMediaNodeID:
        GameNodeID?


    @State
    private var presentedPostNodeID:
        GameNodeID?


    @State
    private var presentedHyperlinkNodeID:
        GameNodeID?


    @State
    private var presentedRouteTarget:
        RouteInteractionTarget?
    
    @State
    private var isShowingRouteBuilder =
        false


    // MARK: - Node Actions

    /// Host-app bridge for Activity actions. Off-path Activity nodes emit
    /// `.join`; Activity nodes already on the chosen path emit `.skip` or
    /// `.completed`.
    private let onActivityAction:
        ((ActivityNodeEditorAction, GameMapNode) -> Void)?


    /// Host-app bridge for User-node actions such as opening a conversation
    /// or the user's progress screen.
    private let onUserAction:
        ((UserNodeEditorAction, GameMapNode) -> Void)?


    /// Host-app bridge for read-only Post actions such as Respond, Save,
    /// opening the poster profile, or navigating to linked content.
    private let onPostAction:
        ((PostNodeViewAction, GameMapNode) -> Void)?


    /// Host bridge for hyperlink votes. The web page itself is presented by
    /// DayMapView; these callbacks let the app persist Upvote/Downvote.
    private let onHyperlinkAction:
        ((HyperlinkNodeViewAction, GameMapNode) -> Void)?


    // MARK: - State

    @StateObject
    private var store: GameStore


    @State
    private var scene: VirtualMapScene
    
    /// Single source of truth for Add Node presentation.
    ///
    /// Both the toolbar + button and road/intersection taps feed this one
    /// item-based sheet. Keeping a single sheet identity avoids SwiftUI trying
    /// to coordinate two competing AddGameNodeView presentations.
    @State
    private var addNodePresentation:
        AddNodePresentation?


    /// Direct review presentation for an empty path card that has actual
    /// app-provided suggested stop content. Cards without a suggestion bypass
    /// this sheet and open the ordinary Add Stop flow immediately.
    @State
    private var suggestedPathStopPresentation:
        SuggestedPathStopRequest?


    // MARK: - Init

    init(
        onActivityAction: ((ActivityNodeEditorAction, GameMapNode) -> Void)? = nil,
        onUserAction: ((UserNodeEditorAction, GameMapNode) -> Void)? = nil,
        onPostAction: ((PostNodeViewAction, GameMapNode) -> Void)? = nil,
        onHyperlinkAction: ((HyperlinkNodeViewAction, GameMapNode) -> Void)? = nil
    ) {


        self.onActivityAction =
            onActivityAction


        self.onUserAction =
            onUserAction


        self.onPostAction =
            onPostAction


        self.onHyperlinkAction =
            onHyperlinkAction


        let gameStore =
            SocketManager.shared.gameStore


        let mapScene =
            VirtualMapScene(
                initialTime:
                    gameStore.currentDayTime,
                initialProgressPercent:
                    gameStore.currentProgressPercent,
                roadGraph:
                    gameStore.roadGraph,
                gameNodes:
                    gameStore.gameNodes,
                revealedTileIDs:
                    gameStore.revealedTileIDs
            )


        _store =
            StateObject(
                wrappedValue:
                    gameStore
            )


        _scene =
            State(
                initialValue:
                    mapScene
            )
    }


    // MARK: - Body

    var body: some View {
        NavigationStack {
            
            ZStack(
                alignment:
                    .bottom
            ) {
                
                // MARK: SpriteKit Map
                
                SpriteView(
                    scene:
                        scene
                )
                .ignoresSafeArea()
                
                AppOverLayView {
                    presentAddNode(
                        at:
                            socketManager.defaultNewNodeCoordinate
                    )
                }


                if store.focusedAlternativeRouteID != nil {

                    AlternateRoutePreviewOverlay(
                        progressPercent:
                            store
                                .focusedAlternativePreviewProgressPercent,
                        onViewRoute:
                            viewFocusedAlternativeRoute,
                        onClose:
                            closeFocusedAlternativeRoutePreview
                    )
                    // Keep the preview controls above the existing bottom
                    // navigation bar. The rest of this view is transparent,
                    // so map pan/zoom gestures continue to reach SpriteKit.
                    .padding(
                        .horizontal,
                        20
                    )
                    .padding(
                        .bottom,
                        112
                    )
                    .zIndex(
                        40
                    )
                }
                
                if socketManager.isShowingPlay {

                    if let workoutNodeID = activeIndependentWorkoutNodeID,
                       let workoutNode = store.gameNode(id: workoutNodeID),
                       case let .activity(activityContent) = workoutNode.content,
                       activityContent.resolvedActivityType == .workout,
                       activityContent.workout?.resolvedWorkoutType == .independent {

                        PlayView(
                            scheduledWorkoutTime: activityContent.startTime,
                            onEditScheduledWorkoutTime: {
                                presentedIndependentWorkoutTimeNodeID =
                                    workoutNodeID
                            },
                            onBrowseWorkoutClasses: {
                                presentedIndependentWorkoutClassBrowseNodeID =
                                    workoutNodeID
                            }
                        )

                    } else {
                        PlayView()
                    }
                }
        

            } //zs

        } //nav
        // One Add Node sheet handles both toolbar and road/intersection
        // entry points. Item-based presentation gives every request a stable
        // identity and avoids competing Boolean/item sheets.
        .sheet(
            item:
                $addNodePresentation
        ) { presentation in

            AddGameNodeView(
                initialCoordinate:
                    presentation.coordinate,
                roadGraph:
                    store.roadGraph
            ) { newNode in

                socketManager.addGameNode(
                    newNode
                )

                addNodePresentation =
                    nil
            }
        }
        
        .sheet(
            item:
                $suggestedPathStopPresentation
        ) { request in

            SuggestedPathStopReviewView(
                request: request,
                roadGraph: store.roadGraph,
                onViewed: {

                    socketManager.suggestedStopViewed(
                        cellID: request.cellID,
                        coordinate: request.coordinate
                    )
                },
                onEditOpened: {

                    socketManager.suggestedStopEditOpened(
                        cellID: request.cellID,
                        coordinate: request.coordinate
                    )
                },
                onAccept: { node in

                    socketManager.suggestedStopAccepted(
                        cellID: request.cellID,
                        coordinate: request.coordinate
                    )

                    store.clearSuggestedPathStop(
                        for: request.cellID
                    )

                    socketManager.addGameNode(
                        node
                    )

                    suggestedPathStopPresentation =
                        nil
                },
                onReject: {

                    socketManager.suggestedStopRejected(
                        cellID: request.cellID,
                        coordinate: request.coordinate
                    )

                    store.clearSuggestedPathStop(
                        for: request.cellID
                    )

                    suggestedPathStopPresentation =
                        nil
                }
            )
        }

        .sheet(
            item:
                $presentedRouteTarget,
            content:
                routeInspectorSheet
        )
        
        .sheet(
            isPresented:
                $isShowingRouteBuilder,
            content:
                routeBuilderSheet
        )

        // MARK: - Appear

        .onAppear {

            scene.interactionDelegate =
                socketManager


            scene.setSemanticTapsEnabled(
                store.focusedAlternativeRouteID == nil
            )


            socketManager.prepareDayMapForPresentation()


            scene.renderCurrentTime(
                store.currentDayTime
            )

            scene.renderCurrentProgress(
                store.currentProgressPercent
            )

            scene.renderSelection(
                store.selection
            )

            syncRouteLayers()
       

        }


        // MARK: - Disappear

        .onDisappear {

            scene.interactionDelegate =
                nil


            socketManager.dayMapDidDisappear()
        }


        // MARK: - Current Time
        .onChange(
            of:
                store.currentDayTime,
            initial:
                true,
            currentDayTimeDidChange
        )

        .onChange(
            of:
                store.currentProgressPercent,
            initial:
                true
        ) { _, newPercent in

            scene.renderCurrentProgress(
                newPercent
            )
        }
        
        .onChange(
            of:
                scenePhase,
            initial:
                true,
            scenePhaseDidChange
        )


        // MARK: - Selection
        .onChange(
            of:
                store.selection
        ) { _, newSelection in

            scene.renderSelection(
                newSelection
            )
        }

        .onChange(
            of:
                store.gameNodes
        ) { _, newNodes in

            scene.renderGameNodes(
                newNodes
            )
        }

        .onChange(
            of:
                store.revealedTileIDs
        ) { _, newIDs in

            scene.renderRevealedTiles(
                newIDs
            )
        }
        
        .onChange(
            of:
                store.pendingNodeAction
        ) { _, newAction in

            guard let newAction else {

                return
            }


            handleNodeAction(
                newAction
            )
        }

        .onChange(
            of:
                store.pendingRoadNodeAddRequest
        ) { _, newRequest in

            guard let newRequest else {

                return
            }

            presentAddNode(
                at:
                    newRequest.coordinate
            )

            store.consumePendingRoadNodeAddRequest()
        }


        .onChange(
            of:
                store.pendingSuggestedPathStopRequest
        ) { _, newRequest in

            guard let newRequest else {
                return
            }

            suggestedPathStopPresentation =
                newRequest

            store.consumePendingSuggestedPathStopRequest()
        }
        
        .onChange(
            of:
                store.routeState
        ) { _, _ in

            syncRouteLayers()
        }

        .onChange(
            of:
                store.focusedAlternativeRouteID
        ) { _, newRouteID in

            // Focused alternate-route preview is deliberately a camera-only
            // map mode. Suppress semantic card/node taps while leaving the
            // SpriteKit pan and pinch recognizers untouched.
            scene.setSemanticTapsEnabled(
                newRouteID == nil
            )


            // First tap on an alternate node changes presentation only: keep
            // completed history plus exactly one alternate route in view.
            syncRouteLayers()
        }

        .onChange(
            of:
                socketManager
                    .currentUserAvatarAssetName
        ) { _, _ in

            syncRouteLayers()
        }
        
        .onChange(
            of:
                store.pendingRouteAction,
            initial:
                false,
            pendingRouteActionDidChange
        )
        
        .onChange(
            of:
                store.futureRoutePreview,
            initial:
                false,
            futureRoutePreviewDidChange
        )

        .onChange(
            of: socketManager.isShowingPlay
        ) { _, isShowing in
            if !isShowing {
                activeIndependentWorkoutNodeID = nil
                presentedIndependentWorkoutBrowseNodeID = nil
                presentedIndependentWorkoutClassBrowseNodeID = nil
                presentedIndependentWorkoutTimeNodeID = nil
            }
        }
        
        .sheet(
            item:
                $presentedIndependentWorkoutBrowseNodeID
        ) { nodeID in

            if let node = store.gameNode(id: nodeID),
               case let .activity(activityContent) = node.content,
               let workout = activityContent.workout {

                ActivityWorkoutBrowseSheet(
                    selectedWorkoutID: workout.workoutID
                ) { option in
                    selectWorkoutFromIndependentPlay(
                        option,
                        nodeID: nodeID
                    )
                }
            }
        }

        .sheet(
            item:
                $presentedIndependentWorkoutClassBrowseNodeID
        ) { nodeID in

            if let node = store.gameNode(id: nodeID),
               case let .activity(activityContent) = node.content,
               let workout = activityContent.workout {

                ActivityWorkoutBrowseSheet(
                    selectedWorkoutID: workout.workoutID,
                    scope: .classesOnly
                ) { option in
                    selectWorkoutFromIndependentPlay(
                        option,
                        nodeID: nodeID
                    )
                    presentedIndependentWorkoutClassBrowseNodeID = nil
                }
            }
        }

        .sheet(
            item:
                $presentedIndependentWorkoutTimeNodeID
        ) { nodeID in

            if let node = store.gameNode(id: nodeID) {
                ActivityWorkoutScheduleTimePickerSheet(
                    node: node
                ) { newTime in
                    let updated =
                        activityWorkoutUpdatingIndependentSchedule(
                            node,
                            to: newTime,
                            roadGraph: store.roadGraph
                        )

                    socketManager.updateGameNode(updated)
                }
            }
        }

        .sheet(
            item:
                $presentedNodeID
        ) { nodeID in

            if let node =
                store.gameNode(
                    id:
                        nodeID
                )
            {

                GameNodeEditorView(
                    node:
                        node,
                    roadGraph:
                        store.roadGraph,
                    onSave: { updatedNode in

                        socketManager.updateGameNode(
                            updatedNode
                        )

                    },
                    onDelete: {

                        socketManager.deleteGameNode(
                            id:
                                node.id
                        )
                    },
                    onActivityAction: { action, updatedNode in

                        socketManager.handleActivityNodeAction(
                            action,
                            node:
                                updatedNode
                        )

                        onActivityAction?(
                            action,
                            updatedNode
                        )
                    },
                    isActivityOnChosenPath:
                        isNodeOnChosenPath(
                            node.id
                        ),
                    onUserAction: { action, updatedNode in

                        socketManager.handleUserNodeAction(
                            action,
                            node:
                                updatedNode
                        )

                        onUserAction?(
                            action,
                            updatedNode
                        )
                    }
                )
                
            }
        }
        
        .fullScreenCover(
            item:
                $presentedActivityMealNodeID
        ) { nodeID in

            if let node =
                store.gameNode(
                    id:
                        nodeID
                )
            {
                ActivityMealExperienceView(
                    node: node,
                    roadGraph: store.roadGraph,
                    onUpdate: { updatedNode in
                        socketManager.updateGameNode(updatedNode)
                    },
                    onDelete: {
                        socketManager.deleteGameNode(id: node.id)
                    },
                    onCompleted: { completedNode in
                        socketManager.handleActivityNodeAction(
                            .completed,
                            node: completedNode
                        )
                        onActivityAction?(
                            .completed,
                            completedNode
                        )
                    }
                )
            }
        }

        .fullScreenCover(
            item:
                $presentedActivityWorkoutNodeID
        ) { nodeID in

            if let node = store.gameNode(id: nodeID) {
                ActivityWorkoutClassExperienceView(
                    node: node,
                    roadGraph: store.roadGraph,
                    onUpdate: { updatedNode in
                        socketManager.updateGameNode(updatedNode)
                    },
                    onSwitchToIndependent: { updatedNode in
                        presentedActivityWorkoutNodeID = nil
                        openIndependentWorkout(updatedNode)
                    }
                )
            }
        }

        .fullScreenCover(
            item:
                $presentedActivityTaskNodeID
        ) { nodeID in

            if let node = store.gameNode(id: nodeID) {
                ActivityTaskExperienceView(
                    node: node,
                    roadGraph: store.roadGraph,
                    onUpdate: { updatedNode in
                        socketManager.updateGameNode(updatedNode)
                    },
                    onSkip: { skippedNode in
                        socketManager.handleActivityNodeAction(
                            .skip,
                            node: skippedNode
                        )
                        onActivityAction?(
                            .skip,
                            skippedNode
                        )
                    },
                    onCompleted: { completedNode in
                        socketManager.handleActivityNodeAction(
                            .completed,
                            node: completedNode
                        )
                        onActivityAction?(
                            .completed,
                            completedNode
                        )
                    }
                )
            }
        }

        .fullScreenCover(
            item:
                $presentedPostNodeID
        ) { nodeID in

            if let node =
                store.gameNode(
                    id:
                        nodeID
                )
            {

                GameNodePostView(
                    node:
                        node,
                    onAction: { action, selectedNode in

                        socketManager.handlePostNodeAction(
                            action,
                            node:
                                selectedNode
                        )

                        onPostAction?(
                            action,
                            selectedNode
                        )
                    }
                )
            }
        }

        .fullScreenCover(
            item:
                $presentedMediaNodeID
        ) { nodeID in

            if let node =
                store.gameNode(
                    id:
                        nodeID
                )
            {

                GameNodeMediaView(
                    node:
                        node
                )
            }
        }
        
        .fullScreenCover(
            item:
                $presentedHyperlinkNodeID
        ) { nodeID in

            if let node =
                store.gameNode(
                    id:
                        nodeID
                )
            {

                GameNodeHyperlinkView(
                    node:
                        node,
                    onAction: { action, selectedNode in

                        socketManager.handleHyperlinkNodeAction(
                            action,
                            node:
                                selectedNode
                        )

                        onHyperlinkAction?(
                            action,
                            selectedNode
                        )
                    }
                )
            }
        }
        
    }
    
    @ViewBuilder
    private var routeControl:
        some View {

        if
            store
                .routeState
                .hasChosenFutureRoute
        {

            Menu {

                Button {

                    openCurrentRouteBuilder()

                } label: {

                    Label(
                        "Edit Current Path",
                        systemImage:
                            "pencil"
                    )
                }


                Button {

                    openNewRouteBuilder()

                } label: {

                    Label(
                        "Build New Path",
                        systemImage:
                            "plus"
                    )
                }


            } label: {

                Label(
                    "Path",
                    systemImage:
                        "point.topleft.down.to.point.bottomright.curvepath"
                )
            }
            .buttonStyle(
                .borderedProminent
            )

        } else {

            Button {

                openNewRouteBuilder()

            } label: {

                Label(
                    "Path",
                    systemImage:
                        "point.topleft.down.to.point.bottomright.curvepath"
                )
            }
            .buttonStyle(
                .borderedProminent
            )
        }
    }
    
}


// =====================================================
// MARK: - Top HUD
// =====================================================

private extension DayMapView {

    var topDiagnosticHUD: some View {

        VStack(
            spacing: 10
        ) {

            HStack {

                VStack(
                    alignment:
                        .leading,
                    spacing:
                        3
                ) {
                    
                    #if DEBUG
                    Menu(
                        "Path Render Tests"
                    ) {

                        Button(
                            "Full Day — All States"
                        ) {

                            _ = store.installRouteRenderDemo(
                                .fullDayAllStates
                            )

                            syncRouteLayers()
                        }


                        Divider()


                        Button(
                            "All States — 12:45 PM"
                        ) {

                            _ = store.installRouteRenderDemo(
                                .balancedMixed
                            )

                            syncRouteLayers()
                        }


                        Button(
                            "Future Only — 8:00 AM"
                        ) {

                            _ = store.installRouteRenderDemo(
                                .futureOnly
                            )

                            syncRouteLayers()
                        }


                        Button(
                            "Early Mix — 10:00 AM"
                        ) {

                            _ = store.installRouteRenderDemo(
                                .earlyMixed
                            )

                            syncRouteLayers()
                        }


                        Button(
                            "Late Mix — 3:15 PM"
                        ) {

                            _ = store.installRouteRenderDemo(
                                .lateMixed
                            )

                            syncRouteLayers()
                        }


                        Button(
                            "Completed Only — 5:00 PM"
                        ) {

                            _ = store.installRouteRenderDemo(
                                .completedOnly
                            )

                            syncRouteLayers()
                        }
                    }
                    #endif

//                   routeControl
  
                }


                Spacer()


                VStack(
                    alignment:
                        .trailing,
                    spacing:
                        2
                ) {

                    Text(
                        "Now"
                    )
                    .foregroundStyle(
                        .secondary
                    )


                    Text(
                        store
                            .currentDayTime
                            .displayClockString
                    )
                    .fontWeight(
                        .semibold
                    )
                }
                .font(
                    .caption
                )
            }


            HStack {


                Spacer()


                Button {

                    scene
                        .centerCameraOnCurrentTime(
                            animated:
                                true
                        )

                } label: {

                    Label(
                        "Center on Now",
                        systemImage:
                            "location.fill"
                    )
                }
                .buttonStyle(
                    .borderedProminent
                )
            }
        }
        .padding()
        .background(
            .ultraThinMaterial
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius:
                    16
            )
        )
    }
}


// =====================================================
// MARK: - Bottom Diagnostic HUD
// =====================================================

private extension DayMapView {

    @ViewBuilder
    var bottomDiagnosticHUD: some View {

        if let interaction =
            store.lastSceneInteraction {

            switch interaction {

            case let .backgroundTapped(
                worldPoint,
                coordinate
            ):

                backgroundDiagnosticView(
                    worldPoint:
                        worldPoint,
                    coordinate:
                        coordinate
                )


            case .dayTileTapped,
                 .roadEdgeTapped,
                 .roadVertexTapped,
                 .gameNodeTapped:

                EmptyView()
            
            case .routeTapped:

                EmptyView()
                
            }
        }
    }
}


// =====================================================
// MARK: - Background Diagnostic View
// =====================================================

private extension DayMapView {

    func backgroundDiagnosticView(
        worldPoint:
            WorldPoint,
        coordinate:
            MapCoordinate
    ) -> some View {

        VStack(
            alignment:
                .leading,
            spacing:
                6
        ) {

            HStack {

                Text(
                    "Map Coordinate"
                )
                .font(
                    .headline
                )


                Spacer()


                Text(
                    coordinate
                        .time
                        .displayClockString
                )
                .fontWeight(
                    .semibold
                )
            }


            Divider()


            // MARK: World X

            HStack {

                Text(
                    "World X"
                )


                Spacer()


                Text(
                    String(
                        format:
                            "%.1f",
                        worldPoint.x
                    )
                )
            }


            // MARK: World Y

            HStack {

                Text(
                    "World Y"
                )


                Spacer()


                Text(
                    String(
                        format:
                            "%.1f",
                        worldPoint.y
                    )
                )
            }


            // MARK: Progress

            HStack {

                Text(
                    "Progress"
                )


                Spacer()


                Text(
                    String(
                        format:
                            "%.1f%%",
                        coordinate
                            .progress
                            .percent
                    )
                )
            }


            // MARK: Time

            HStack {

                Text(
                    "Time"
                )


                Spacer()


                Text(
                    coordinate
                        .time
                        .displayClockString
                )
            }
        }
        .font(
            .caption.monospaced()
        )
        .padding()
        .frame(
            maxWidth:
                .infinity,
            alignment:
                .leading
        )
        .background(
            .ultraThinMaterial
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius:
                    16
            )
        )
    }
}


private extension DayMapView {

    /// The user's chosen path is the route already completed today plus the
    /// currently selected future route. Alternative-route stops are not part
    /// of the chosen path until that alternative is selected.
    func isNodeOnChosenPath(
        _ nodeID: GameNodeID
    ) -> Bool {

        store.routeState
            .completedRoute
            .reachedNodeIDs
            .contains(
                nodeID
            )
        ||
        store.routeState
            .chosenFutureRoute
            .stopNodeIDs
            .contains(
                nodeID
            )
    }


    func presentAddNode(
        at coordinate: MapCoordinate
    ) {

        // Record the intent before presentation rather than mutating the
        // observable SocketManager from AddGameNodeView.onAppear. This keeps
        // sheet construction side-effect free.
        socketManager.nodeCreationSheetOpened(
            at:
                coordinate
        )

        addNodePresentation =
            AddNodePresentation(
                coordinate:
                    coordinate
            )
    }


}


private struct AddNodePresentation:
    Identifiable {

    let id = UUID()

    let coordinate:
        MapCoordinate
}



// =====================================================
// MARK: - Suggested Path Stop Review
// =====================================================

private struct SuggestedPathStopReviewView: View {

    let request:
        SuggestedPathStopRequest

    let roadGraph:
        RoadGraph

    let onViewed:
        () -> Void

    let onEditOpened:
        () -> Void

    let onAccept:
        (GameMapNode) -> Void

    let onReject:
        () -> Void


    @State
    private var draft:
        GameMapNode

    @State
    private var isEditing =
        false

    @State
    private var didRecordView =
        false


    init(
        request: SuggestedPathStopRequest,
        roadGraph: RoadGraph,
        onViewed: @escaping () -> Void,
        onEditOpened: @escaping () -> Void,
        onAccept: @escaping (GameMapNode) -> Void,
        onReject: @escaping () -> Void
    ) {

        self.request = request
        self.roadGraph = roadGraph
        self.onViewed = onViewed
        self.onEditOpened = onEditOpened
        self.onAccept = onAccept
        self.onReject = onReject

        _draft =
            State(
                initialValue:
                    request
                        .suggestion
                        .makeGameNode(
                            at: request.coordinate
                        )
            )
    }


    var body: some View {

        NavigationStack {

            Group {

                if isEditing {

                    GameNodeEditorForm(
                        node: $draft,
                        roadGraph: roadGraph,
                        validationIssues:
                            validation.issues
                    )

                } else {

                    SuggestedStopContentPreview(
                        node: draft
                    )
                }
            }
            .navigationTitle(
                isEditing
                ? "Edit Suggested Stop"
                : "Suggested Stop"
            )
            .navigationBarTitleDisplayMode(
                .inline
            )
            .toolbar {

                if isEditing {

                    ToolbarItem(
                        placement: .cancellationAction
                    ) {

                        Button(
                            "Cancel"
                        ) {

                            draft =
                                request
                                    .suggestion
                                    .makeGameNode(
                                        at: request.coordinate
                                    )

                            isEditing =
                                false
                        }
                    }


                    ToolbarItem(
                        placement: .confirmationAction
                    ) {

                        Button(
                            "Save"
                        ) {

                            guard validation.isValid else {
                                return
                            }

                            draft =
                                GameNodeNormalizer
                                    .normalize(
                                        draft
                                    )

                            isEditing =
                                false
                        }
                        .disabled(
                            !validation.isValid
                        )
                    }
                }
            }
            .safeAreaInset(
                edge: .bottom
            ) {

                if !isEditing {

                    HStack(
                        spacing: 12
                    ) {

                        Button(
                            role: .destructive,
                            action: onReject
                        ) {

                            Label(
                                "Reject",
                                systemImage: "xmark"
                            )
                            .frame(
                                maxWidth: .infinity
                            )
                        }
                        .buttonStyle(
                            .bordered
                        )


                        Button {

                            onEditOpened()
                            isEditing = true

                        } label: {

                            Label(
                                "Edit",
                                systemImage: "pencil"
                            )
                            .frame(
                                maxWidth: .infinity
                            )
                        }
                        .buttonStyle(
                            .bordered
                        )


                        Button {

                            guard validation.isValid else {
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
                                        roadGraph: roadGraph
                                    )
                                    .isValid
                            else {
                                return
                            }

                            onAccept(
                                normalized
                            )

                        } label: {

                            Label(
                                "Accept",
                                systemImage: "checkmark"
                            )
                            .frame(
                                maxWidth: .infinity
                            )
                        }
                        .buttonStyle(
                            .borderedProminent
                        )
                        .disabled(
                            !validation.isValid
                        )
                    }
                    .padding(
                        .horizontal
                    )
                    .padding(
                        .vertical,
                        10
                    )
                    .background(
                        .ultraThinMaterial
                    )
                }
            }
        }
        .presentationDetents(
            [
                .medium,
                .large
            ]
        )
        .onAppear {

            guard !didRecordView else {
                return
            }

            didRecordView = true
            onViewed()
        }
    }
}


private extension SuggestedPathStopReviewView {

    var validation:
        GameNodeValidationResult {

        GameNodeValidator.validate(
            draft,
            roadGraph: roadGraph
        )
    }
}


private struct SuggestedStopContentPreview: View {

    let node:
        GameMapNode


    @ViewBuilder
    var body: some View {

        switch node.content {

        case let .activity(content):

            ActivityNodeDetailView(
                content: content
            )

        case let .post(content):

            PostNodeDetailView(
                content: content
            )

        case let .hyperlink(content):

            HyperlinkNodeDetailView(
                content: content
            )

        case let .media(content):

            MediaNodeMetadataView(
                content: content
            )

        case let .user(content):

            UserNodeDetailView(
                content: content
            )

        case let .play(content):

            VStack(
                spacing: 18
            ) {

                Image(
                    systemName: "play.fill"
                )
                .font(
                    .system(
                        size: 46,
                        weight: .semibold
                    )
                )

                Text(
                    content.title
                )
                .font(
                    .title2.weight(.bold)
                )

                Text(
                    node.time.displayClockString
                )
                .foregroundStyle(
                    .secondary
                )
            }
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity
            )
            .padding()
        }
    }
}


private extension DayMapView {

    func handleNodeAction(
        _ action:
            GameNodeAction
    ) {

        switch action {

        case .showPlay:

            socketManager.openPlay()


        case let .showUser(
            nodeID,
            _
        ):

            presentedNodeID =
                nodeID


        case let .showActivityMeal(
            nodeID,
            _
        ):

            presentedActivityMealNodeID =
                nodeID


        case let .showActivityWorkout(
            nodeID,
            _
        ):

            presentActivityWorkout(
                nodeID: nodeID
            )


        case let .showActivityTask(
            nodeID,
            _
        ):

            presentedActivityTaskNodeID =
                nodeID


        case let .showPost(
            nodeID,
            _
        ):

            presentedPostNodeID =
                nodeID


        case let .showMedia(
            nodeID,
            _
        ):

            presentedMediaNodeID =
                nodeID


        case let .openHyperlink(
            nodeID,
            _
        ):

            presentedHyperlinkNodeID =
                nodeID
        }


        store.consumePendingNodeAction()
    }
}

private extension DayMapView {

    func viewFocusedAlternativeRoute() {

        guard let routeID =
            store.focusedAlternativeRouteID
        else {
            return
        }


        presentedRouteTarget =
            .alternative(
                routeID:
                    routeID
            )
    }


    func closeFocusedAlternativeRoutePreview() {

        store.closeAlternativeRoutePreview()
    }
}


private extension DayMapView {

    func pendingRouteActionDidChange(
        _ oldAction:
            RouteAction?,
        _ newAction:
            RouteAction?
    ) {

        guard let newAction else {
            return
        }


        switch newAction {

        case .inspectCompleted:

            presentedRouteTarget =
                .completed


        case let .inspectChosen(
            routeID
        ):

            presentedRouteTarget =
                .chosen(
                    routeID:
                        routeID
                )


        case let .inspectAlternative(
            routeID
        ):

            presentedRouteTarget =
                .alternative(
                    routeID:
                        routeID
                )
        }


        store.consumePendingRouteAction()
    }
}

private extension DayMapView {

    @ViewBuilder
    func routeInspectorSheet(
        target:
            RouteInteractionTarget
    ) -> some View {

        RouteInspectorView(
            target:
                target,

            inspectedRoute:
                inspectedFutureRoute(
                    for:
                        target
                ),

            completedRoute:
                store
                    .routeState
                    .completedRoute,

            gameNodes:
                store
                    .gameNodes,

            onChoose:
                chooseRoute
        )
    }
}

private extension DayMapView {

    func inspectedFutureRoute(
        for target:
            RouteInteractionTarget
    ) -> GameRoute? {

        guard let routeID =
            target.routeID
        else {

            return nil
        }


        return store.futureRoute(
            id:
                routeID
        )
    }


    func chooseRoute(
        _ routeID:
            RouteID
    ) -> Bool {

        let succeeded =
            socketManager.chooseFutureRoute(
                routeID:
                    routeID
            )


        if succeeded {

            // Selecting the previewed alternate makes it the real chosen
            // route, so preview mode and its interaction lock are no longer
            // needed.
            store.closeAlternativeRoutePreview()
        }


        return succeeded
    }
}

private extension DayMapView {

    func openNewRouteBuilder() {

        socketManager
            .beginNewFutureRouteDraft()


        isShowingRouteBuilder =
            true
    }
}

private extension DayMapView {

    func routeBuilderSheet() -> some View {

        FutureRouteBuilderView(
            store:
                store
        )
    }
}

private extension DayMapView {

    func futureRoutePreviewDidChange(
        _ oldPreview:
            FutureRoutePreview?,
        _ newPreview:
            FutureRoutePreview?
    ) {

        // Keep preview and live route layers synchronized through selection,
        // replanning, cancellation and commit. A successful commit publishes
        // routeState and then clears futureRoutePreview; this helper is safe
        // regardless of which SwiftUI observation fires first.
        syncRouteLayers()
    }
}


private extension DayMapView {

    func openCurrentRouteBuilder() {

        guard
            !isShowingRouteBuilder
        else {

            return
        }


        let succeeded =
            socketManager
                .beginEditingChosenFutureRoute()


        guard succeeded else {
            return
        }


        isShowingRouteBuilder =
            true
    }
    
}

private extension DayMapView {

    /// Synchronizes the live and temporary route layers as one visual unit.
    /// This is deliberately idempotent so route commits can publish several
    /// store properties without briefly leaving stale preview geometry behind.
    func syncRouteLayers() {

        scene.renderRoutes(
            store.routeRenderState,
            focusedAlternativeRouteID:
                store.focusedAlternativeRouteID,
            currentUserAvatarAssetName:
                socketManager
                    .currentUserAvatarAssetName
        )


        if store.futureRoutePreview != nil {

            scene.renderRoutePreview(
                store.routePreviewRenderState
            )

        } else {

            scene.clearRoutePreview()
        }
    }
}


private extension DayMapView {

    func currentDayTimeDidChange(
        _ oldTime:
            DayTime,
        _ newTime:
            DayTime
    ) {

        // Current-time line / marker
        scene.renderCurrentTime(
            newTime
        )


        // Completed route grows, chosen future shrinks, and any active
        // preview is clipped from this same current-time boundary.
        syncRouteLayers()
    }


    func scenePhaseDidChange(
        _ oldPhase:
            ScenePhase,
        _ newPhase:
            ScenePhase
    ) {

        switch newPhase {

        case .active:

            socketManager.startDayMapGameClock()


        case .inactive,
             .background:

            socketManager.stopDayMapGameClock()


        @unknown default:

            socketManager.stopDayMapGameClock()
        }
    }
}

// =====================================================
// MARK: - Alternate Route Preview Overlay
// =====================================================

/// Lightweight preview controls shown after the first tap on an alternate
/// GameNode card. The overlay itself does not cover the map with a hit-testing
/// surface; only this compact control bar accepts touches. SpriteKit disables
/// semantic taps separately, which preserves pan and pinch-to-zoom everywhere
/// else on the map.
private struct AlternateRoutePreviewOverlay: View {

    let progressPercent:
        Double?

    let onViewRoute:
        () -> Void

    let onClose:
        () -> Void


    var body: some View {

        HStack(
            spacing:
                12
        ) {

            Button(
                action:
                    onViewRoute
            ) {

                Label(
                    "View Path",
                    systemImage:
                        "map.fill"
                )
                .font(
                    .system(
                        size: 14,
                        weight: .semibold
                    )
                )
                .lineLimit(
                    1
                )
                .padding(
                    .horizontal,
                    13
                )
                .frame(
                    minHeight:
                        44
                )
            }
            .buttonStyle(
                .plain
            )
            .background(
                Color.black.opacity(
                    0.34
                ),
                in:
                    RoundedRectangle(
                        cornerRadius: 14,
                        style: .continuous
                    )
            )


            Spacer(
                minLength:
                    0
            )


            // This is intentionally informational rather than an actionable
            // map control. It is styled as the middle preview button/pill the
            // product spec calls for, but does not steal an extra action from
            // the user.
            VStack(
                spacing:
                    1
            ) {

                Text(
                    previewPercentText
                )
                .font(
                    .system(
                        size: 20,
                        weight: .bold,
                        design: .rounded
                    )
                )


                Text(
                    "PREVIEW"
                )
                .font(
                    .system(
                        size: 9,
                        weight: .bold
                    )
                )
                .opacity(
                    0.72
                )
            }
            .padding(
                .horizontal,
                16
            )
            .frame(
                minHeight:
                    44
            )
            .background(
                Color.white.opacity(
                    0.13
                ),
                in:
                    RoundedRectangle(
                        cornerRadius: 14,
                        style: .continuous
                    )
            )
            .accessibilityElement(
                children:
                    .combine
            )
            .accessibilityLabel(
                "Preview progress \(previewPercentText)"
            )


            Spacer(
                minLength:
                    0
            )


            Button(
                action:
                    onClose
            ) {

                Image(
                    systemName:
                        "xmark"
                )
                .font(
                    .system(
                        size: 16,
                        weight: .bold
                    )
                )
                .frame(
                    width: 44,
                    height: 44
                )
            }
            .buttonStyle(
                .plain
            )
            .background(
                Color.black.opacity(
                    0.34
                ),
                in:
                    RoundedRectangle(
                        cornerRadius: 14,
                        style: .continuous
                    )
            )
            .accessibilityLabel(
                "Close alternate path preview"
            )
        }
        .foregroundStyle(
            .white
        )
        .padding(
            10
        )
        .background(
            .ultraThinMaterial,
            in:
                RoundedRectangle(
                    cornerRadius: 20,
                    style: .continuous
                )
        )
        .overlay {

            RoundedRectangle(
                cornerRadius: 20,
                style: .continuous
            )
            .stroke(
                Color.white.opacity(
                    0.18
                ),
                lineWidth: 1
            )
        }
    }


    private var previewPercentText:
        String {

        guard let progressPercent else {
            return "--%"
        }


        return "\(Int(progressPercent.rounded()))%"
    }
}



// =====================================================
// MARK: - ActivityWorkout Presentation (Pass 5.29)
// =====================================================

private extension DayMapView {

    func presentActivityWorkout(
        nodeID: GameNodeID
    ) {

        guard let node = store.gameNode(id: nodeID),
              case let .activity(content) = node.content,
              content.resolvedActivityType == .workout else {
            presentedNodeID = nodeID
            return
        }

        let workoutType =
            content.workout?.resolvedWorkoutType
            ?? .independent

        switch workoutType {
        case .guidedClass:
            activeIndependentWorkoutNodeID = nil

            if socketManager.isShowingPlay {
                socketManager.closePlay(
                    pauseActiveWorkout: false
                )
            }

            presentedActivityWorkoutNodeID = nodeID

        case .independent:
            openIndependentWorkout(node)
        }
    }


    func openIndependentWorkout(
        _ node: GameMapNode
    ) {

        guard case let .activity(content) = node.content,
              let workout = content.workout else {
            return
        }

        presentedActivityWorkoutNodeID = nil
        activeIndependentWorkoutNodeID = node.id

        socketManager.activateIndependentWorkout(
            from: workout
        )

        socketManager.openPlay()
    }


    func selectWorkoutFromIndependentPlay(
        _ option: ActivityWorkoutBrowseOption,
        nodeID: GameNodeID
    ) {

        guard let node = store.gameNode(id: nodeID) else {
            return
        }

        let updated =
            activityWorkoutApplyingSelection(
                option,
                to: node,
                roadGraph: store.roadGraph
            )

        socketManager.updateGameNode(updated)
        presentedIndependentWorkoutBrowseNodeID = nil
        presentedIndependentWorkoutClassBrowseNodeID = nil

        switch option.summary.resolvedWorkoutType {
        case .independent:
            activeIndependentWorkoutNodeID = nodeID
            socketManager.activateIndependentWorkout(
                from: option.summary
            )

        case .guidedClass:
            socketManager.closePlay(
                pauseActiveWorkout: false
            )
            activeIndependentWorkoutNodeID = nil
            presentedActivityWorkoutNodeID = nodeID
        }
    }
}
