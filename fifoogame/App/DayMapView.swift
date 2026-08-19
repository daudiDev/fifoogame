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


    // MARK: - State

    @StateObject
    private var store: GameStore


    @State
    private var scene: VirtualMapScene


    // MARK: - Init

    init() {

        let gameStore =
            GameStore()


        let mapScene =
            VirtualMapScene(
                initialTime:
                    gameStore.currentDayTime,
                roadGraph:
                    gameStore.roadGraph
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


                /*
                 RoadInspectorHUD is only visible
                 when a road edge or road vertex
                 is selected.
                 */

                if hasRoadSelection {

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
        }


        // MARK: - Appear

        .onAppear {

            scene.interactionDelegate =
                store


            store.startClock()


            scene.renderCurrentTime(
                store.currentDayTime
            )


            scene.renderRoadSelection(
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


        // MARK: - Road Selection

        .onChange(
            of:
                store.selection
        ) { _, newSelection in

            /*
             GameStore remains the source
             of truth.

             SpriteKit only renders the
             resulting selection.
             */

            scene.renderRoadSelection(
                newSelection
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

                    Text(
                        "Fifoo"
                    )
                    .font(
                        .headline
                    )


                    Text(
                        "Section 3E • Road Inspection"
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

                Text(
                    "1000 × 2400"
                )
                .font(
                    .caption.monospaced()
                )
                .foregroundStyle(
                    .secondary
                )


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

            // =====================================
            // Background
            // =====================================

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


            // =====================================
            // Road Edge
            // =====================================

            case .roadEdgeTapped:

                /*
                 RoadInspectorHUD displays all
                 edge information, so we don't
                 need a second HUD here.
                 */

                EmptyView()


            // =====================================
            // Road Vertex / Intersection
            // =====================================

            case .roadVertexTapped:

                /*
                 RoadInspectorHUD displays all
                 intersection information.
                 */

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
