//
//  DayMapView.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/18/26.
//

import SwiftUI
import SpriteKit


struct DayMapView: View {

    // MARK: - Environment
    @Environment(\.scenePhase)
    private var scenePhase
    
    @Environment(\.openURL)
    private var openURL
    
    @State
    private var presentedNodeID:
        GameNodeID?


    @State
    private var presentedMediaNodeID:
        GameNodeID?

    @State
    private var presentedRouteTarget:
        RouteInteractionTarget?
    
    @State
    private var isShowingRouteBuilder =
        false

    // MARK: - State

    @StateObject
    private var store: GameStore


    @State
    private var scene: VirtualMapScene
    
    @State
    private var isShowingAddNode =
        false


    // MARK: - Init

    init() {

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
                
                
                // MARK: SwiftUI Diagnostic UI
                
                VStack(
                    spacing: 12
                ) {
                    
                    // topDiagnosticHUD
                    
                    
                    Spacer()
                    
                    
                    if
                        let nodeID =
                            store.selection
                            .selectedNodeID,
                        
                            let gameNode =
                            store.gameNode(
                                id:
                                    nodeID
                            )
                    {
                        
                        GameNodeInspectorHUD(
                            node:
                                gameNode
                        )
                        
                        
                    } else if hasRoadSelection {
                        
                        RoadInspectorHUD(
                            graph:
                                store.roadGraph,
                            selection:
                                store.selection
                        )
                    }
                    
                    
                    /*
                     This HUD is primarily useful
                     when empty map/background space
                     is tapped.
                     */
                    
                    //                bottomDiagnosticHUD
                }
                .padding()
                

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
            
            scene.renderRoutes(
                store.routeRenderState
            )
            
            print("Chosen empty:", store.routeState.chosenFutureRoute.isEmpty)
            print("Chosen planned:", store.routeState.chosenFutureRoute.isFullyPlanned)
            print("Chosen segments:",
                  store.routeRenderState.chosenFuture?.segments.count ?? 0)

            print("Alternatives:",
                  store.routeRenderState.alternatives.count)

            print("Completed:",
                  store.routeRenderState.completedSegments.count)

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
                store.routeState
        ) { _, _ in

            scene.renderRoutes(
                store.routeRenderState
            )
        }
        
        .onChange(
            of:
                store.currentDayTime
        ) { _, _ in

            scene.renderRoutes(
                store.routeRenderState
            )
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
// MARK: - Selection Helpers
// =====================================================

private extension DayMapView {

    var hasRoadSelection: Bool {

        store.selection
            .selectedRoadEdgeID != nil

        ||

        store.selection
            .selectedRoadVertexID != nil
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

                   routeControl
  
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

    func openHyperlink(
        _ urlString:
            String
    ) {

        guard
            let url =
                URL(
                    string:
                        urlString
                ),

            let scheme =
                url.scheme?
                    .lowercased(),

            scheme == "http"
            ||
            scheme == "https"
        else {

            return
        }


        openURL(
            url
        )
    }
}

private extension DayMapView {

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

        case let .showLabel(
            nodeID
        ):

            presentedNodeID =
                nodeID


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

            presentedNodeID =
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

            presentedNodeID =
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

            chosenRoute:
                store
                    .routeState
                    .chosenFutureRoute,

            inspectedRoute:
                inspectedFutureRoute(
                    for:
                        target
                ),

            completedRoute:
                store
                    .routeState
                    .completedRoute,

            onChoose:
                chooseRoute,

            onEditChosenRoute:
                openExistingRouteBuilder
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

        guard
            newPreview != nil
        else {

            scene.clearRoutePreview()

            return
        }


        let renderState:
            RoutePreviewRenderState =
                store.routePreviewRenderState


        scene.renderRoutePreview(
            renderState
        )
    }
}

private extension DayMapView {

    func openExistingRouteBuilder(
        _ routeID:
            RouteID
    ) {

        // =================================================
        // Make sure the route the inspector referred to
        // is still the current chosen route.
        // =================================================

        guard
            store
                .routeState
                .chosenFutureRoute
                .id
            ==
            routeID
        else {

            return
        }


        let succeeded =
            store
                .beginEditingChosenFutureRoute()


        guard succeeded else {

            return
        }


        /*
         RouteInspectorView is itself being dismissed.

         Yield one UI cycle before asking SwiftUI to
         present the Route Builder sheet.
        */

        Task { @MainActor in

            await Task.yield()


            isShowingRouteBuilder =
                true
        }
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


        // Completed route grows and chosen future shrinks.
        let routeState:
            RouteRenderState =
                store.routeRenderState


        scene.renderRoutes(
            routeState
        )


        // Keep an active editor preview synchronized
        // with the same current time.
        if
            store.futureRoutePreview
            != nil
        {

            scene.renderRoutePreview(
                store.routePreviewRenderState
            )
        }
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
