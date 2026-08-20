//
//  FutureRoutePreviewView.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/19/26.
//


import SwiftUI


struct FutureRoutePreviewView: View {

    @ObservedObject
    var store:
        GameStore


    let onCommit:
        () -> Void


    let onCancel:
        () -> Void
    
    @State
    private var commitFailed =
        false
    
    @State
    private var commitFailure:
        FutureRouteCommitFailure?


    var body: some View {

        List {
            
            if store.isFutureRoutePreviewStale {

                Section {

                    Label(
                        "Your current position changed after this preview was created.",
                        systemImage:
                            "exclamationmark.triangle.fill"
                    )
                    .foregroundStyle(
                        .orange
                    )


                    Button(
                        "Back to Editing"
                    ) {

                        onCancel()
                    }

                } footer: {

                    Text(
                        "Plan the route again from your latest position before committing."
                    )
                }
            }

            previewSummarySection

            routeChoicesSection

            confirmSection
        }
        .navigationTitle(
            "Route Preview"
        )
        .navigationBarTitleDisplayMode(
            .inline
        )
        .alert(
            "Route Could Not Be Updated",
            isPresented:
                Binding(
                    get: {
                        commitFailure != nil
                    },
                    set: { presented in

                        if !presented {

                            commitFailure =
                                nil
                        }
                    }
                )
        ) {

            Button(
                "OK",
                role:
                    .cancel
            ) { }

        } message: {

            Text(
                commitFailureMessage
            )
        }
    }
    
    private var previewModeDescription:
        String {

        if
            store
                .futureRouteDraft
                .isEditingExistingRoute
        {

            return "Replacement for Current Route"
        }


        return "New Future Route"
    }
    
}


private extension FutureRoutePreviewView {

    @ViewBuilder
    var previewSummarySection:
        some View {

        if let preview =
            store.futureRoutePreview
        {

            Section(
                "Preview"
            ) {

                LabeledContent(
                    "Stops",
                    value:
                        "\(preview.primaryRoute.stopNodeIDs.count)"
                )


                LabeledContent(
                    "Route Options",
                    value:
                        "\(preview.allRoutes.count)"
                )
                
                LabeledContent(
                    "Mode",
                    value:
                        previewModeDescription
                )


                if
                    preview.primaryRoute
                        .entryLeg
                    != nil
                {

                    Label(
                        "Starts from your current route position",
                        systemImage:
                            "location.fill"
                    )
                    .foregroundStyle(
                        .secondary
                    )
                }
            }
        }
    }
}

private extension FutureRoutePreviewView {

    @ViewBuilder
    var routeChoicesSection:
        some View {

        if let preview =
            store.futureRoutePreview
        {

            Section(
                "Choose Route"
            ) {

                ForEach(
                    Array(
                        preview
                            .allRoutes
                            .enumerated()
                    ),
                    id:
                        \.element.id
                ) { index, route in

                    previewRouteRow(
                        route:
                            route,
                        index:
                            index
                    )
                }
            }
        }
    }
}

private extension FutureRoutePreviewView {

    func previewRouteRow(
        route:
            GameRoute,
        index:
            Int
    ) -> some View {

        let selected =
            store
                .futureRoutePreview?
                .selectedRouteID
            ==
            route.id


        return Button {

            selectRoute(
                route.id
            )

        } label: {

            HStack(
                spacing:
                    12
            ) {

                Image(
                    systemName:
                        selected
                        ? "largecircle.fill.circle"
                        : "circle"
                )


                VStack(
                    alignment:
                        .leading,
                    spacing:
                        4
                ) {

                    Text(
                        index == 0
                        ? "Recommended Route"
                        : "Alternative \(index)"
                    )
                    .fontWeight(
                        .medium
                    )


                    HStack(
                        spacing:
                            12
                    ) {

                        Text(
                            "\(route.allRoadSegments.count) road segments"
                        )


                        if let cost =
                            route.plannedTotalCost
                        {

                            Text(
                                cost,
                                format:
                                    .number
                                    .precision(
                                        .fractionLength(
                                            0
                                        )
                                    )
                            )
                        }
                    }
                    .font(
                        .caption
                    )
                    .foregroundStyle(
                        .secondary
                    )
                }


                Spacer()
            }
            .contentShape(
                Rectangle()
            )
        }
        .buttonStyle(
            .plain
        )
    }
}

private extension FutureRoutePreviewView {

    func selectRoute(
        _ routeID:
            RouteID
    ) {

        store
            .selectFutureRoutePreview(
                routeID:
                    routeID
            )
    }
}

private extension FutureRoutePreviewView {

    var confirmSection:
        some View {

        Section {

            Button {

                commitRoute()

            } label: {

                Label(
                    "Use This Route",
                    systemImage:
                        "checkmark.circle.fill"
                )
                .frame(
                    maxWidth:
                        .infinity
                )
            }
            .disabled(
                store.isFutureRoutePreviewStale
            )


            Button(
                role:
                    .cancel
            ) {

                onCancel()

            } label: {

                Text(
                    "Back to Editing"
                )
                .frame(
                    maxWidth:
                        .infinity
                )
            }
        }
    }


    func commitRoute() {

        let result =
            store
                .commitFutureRoutePreview()


        guard result.succeeded else {

            commitFailure =
                result.failure

            return
        }


        onCommit()
    }
    
}

private extension FutureRoutePreviewView {

    var commitFailureMessage:
        String {

        switch commitFailure {

        case .noPreview:

            return
                "The route preview is no longer available."


        case .selectedRouteUnavailable:

            return
                "The selected route is no longer available."


        case .selectedRouteNotPlanned:

            return
                "The selected route is not fully planned."


        case .sourceRouteChanged:

            return
                "The current live route changed while you were editing it. Open the route editor again."


        case .timeMovedBackward:

            return
                "The route history could not be advanced to the current time."


        case .currentPositionChanged:

            return
                "Your current road position changed while this preview was open. Return to editing and plan again."


        case .none:

            return
                "The route could not be updated."
        }
    }
}
