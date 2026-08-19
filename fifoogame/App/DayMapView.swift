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

        ZStack {

            // MARK: SpriteKit Map

            SpriteView(
                scene:
                    scene
            )
            .ignoresSafeArea()


            // MARK: SwiftUI Diagnostic UI

            VStack(
                spacing: 12
            ) {

                topDiagnosticHUD


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

                bottomDiagnosticHUD
            }
            .padding()
            
            VStack {

                HStack {

                    Spacer()


                    Button {

                        isShowingAddNode =
                            true

                    } label: {

                        Image(
                            systemName:
                                "plus"
                        )
                        .font(
                            .headline
                        )
                        .frame(
                            width:
                                44,
                            height:
                                44
                        )
                        .background(
                            .ultraThinMaterial
                        )
                        .clipShape(
                            Circle()
                        )
                    }
                    .buttonStyle(
                        .plain
                    )
                }
                .padding()


                Spacer()
            }
            
            
        } //zs
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
                store.currentDayTime
        ) { _, newTime in

            scene.renderCurrentTime(
                newTime
            )
        }


        // MARK: - Scene Phase

        .onChange(
            of:
                scenePhase
        ) { _, newPhase in

            guard
                newPhase == .active
            else {

                return
            }


            /*
             Do not wait for the next
             30-second clock tick after
             returning from background.
             */

            store.refreshCurrentTime()


            scene.renderCurrentTime(
                store.currentDayTime
            )
        }


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

                    Text(
                        "Fifoo"
                    )
                    .font(
                        .headline
                    )


                    Text(
                        "Section 4A • Interactive Nodes"
                    )
                    .font(
                        .caption
                    )
                    .foregroundStyle(
                        .secondary
                    )
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
