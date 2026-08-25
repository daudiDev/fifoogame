//
//  DayMapView.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/24/26.
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
    
    @State
    private var isShowingAddNode =
        false

    /// Set when the user taps a road or intersection. The request carries the
    /// exact semantic coordinate resolved by RoadHitTester.
    @State
    private var roadNodeAddRequest:
        RoadNodeAddRequest?


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
            GameStore()


        let mapScene =
            VirtualMapScene(
                initialTime:
                    gameStore.currentDayTime,
                roadGraph:
                    gameStore.roadGraph,
                gameNodes:
                    gameStore.gameNodes
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
            
            ZStack {
                
                // MARK: SpriteKit Map
                
                SpriteView(
                    scene:
                        scene
                )
                .ignoresSafeArea()
                
                AppOverLayView(isShowingAddNode: $isShowingAddNode)
                
                if (socketManager.isShowingPlay) {
                    PlayView()
                }
        

            } //zs

        } //nav
        .sheet(
            isPresented:
                $isShowingAddNode
        ) {

            AddGameNodeView(
                initialCoordinate:
                    newNodeInitialCoordinate,
                roadGraph:
                    store.roadGraph
            ) { newNode in

                store.addGameNode(
                    newNode
                )


                isShowingAddNode =
                    false
            }
        }

        // A road/intersection tap opens the same node-type chooser as the
        // normal Add Node flow, but seeds it with the tapped road's resolved
        // time/progress coordinate.
        .sheet(
            item:
                $roadNodeAddRequest
        ) { request in

            AddGameNodeView(
                initialCoordinate:
                    request.coordinate,
                roadGraph:
                    store.roadGraph
            ) { newNode in

                store.addGameNode(
                    newNode
                )

                roadNodeAddRequest =
                    nil
            }
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
                store


            store.startClock()


            scene.renderCurrentTime(
                store.currentDayTime
            )

            scene.renderSelection(
                store.selection
            )
            
            syncRouteLayers()
            
            store.useSimulatedClock(
                speed: 60
            )

            store.resetSimulationDay(
                to:
                    DayTime(
                        secondsFromMidnight:
                            8 * 3600
                    )
            )
            
            //MARK: todo - remove for production
            store.printDebugRouteVertices()
            
            store.installDebugRouteScenario()

            store.installRouteRenderDemo(
                .fullDayAllStates
            )
       

        }


        // MARK: - Disappear

        .onDisappear {

            scene.interactionDelegate =
                nil


            store.stopClock()
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

            roadNodeAddRequest =
                newRequest

            store.consumePendingRoadNodeAddRequest()
        }
        
        .onChange(
            of:
                store.routeState
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

                        store.updateGameNode(
                            updatedNode
                        )

                    },
                    onDelete: {

                        store.deleteGameNode(
                            id:
                                node.id
                        )
                    },
                    onActivityAction:
                        onActivityAction,
                    isActivityOnChosenPath:
                        isNodeOnChosenPath(
                            node.id
                        ),
                    onUserAction:
                        onUserAction
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
                    onAction:
                        onPostAction
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
                    onAction:
                        onHyperlinkAction
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
                        "Edit Current Route",
                        systemImage:
                            "pencil"
                    )
                }


                Button {

                    openNewRouteBuilder()

                } label: {

                    Label(
                        "Build New Route",
                        systemImage:
                            "plus"
                    )
                }


            } label: {

                Label(
                    "Route",
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
                    "Route",
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
                        "Route Render Tests"
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


            case .roadEdgeTapped,
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


    var newNodeInitialCoordinate:
        MapCoordinate {

        MapCoordinate(
            time:
                store.currentDayTime,
            progress:
                MapProgress(
                    50
                )
        )
    }
}

private extension DayMapView {

    func handleNodeAction(
        _ action:
            GameNodeAction
    ) {

        switch action {

        case .showPlay:

            socketManager.isShowingPlay =
                true


        case let .showUser(
            nodeID,
            _
        ):

            presentedNodeID =
                nodeID


        case let .showActivity(
            nodeID,
            _
        ):

            presentedNodeID =
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

        store.chooseFutureRoute(
            routeID:
                routeID
        )
    }
}

private extension DayMapView {

    func openNewRouteBuilder() {

        store
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
            store
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
            store.routeRenderState
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

            store.startGameClock()


        case .inactive,
             .background:

            store.stopGameClock()


        @unknown default:

            store.stopGameClock()
        }
    }
}
