//
//  RouteInspectorView.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/19/26.
//

import SwiftUI


struct RouteInspectorView: View {

    let target:
        RouteInteractionTarget


    let chosenRoute:
        GameRoute


    let inspectedRoute:
        GameRoute?


    let completedRoute:
        CompletedRoute


    let onChoose:
        ((RouteID) -> Bool)?


    @Environment(\.dismiss)
    private var dismiss

    @State
    private var routeSwitchFailed =
        false

    var body: some View {

        NavigationStack {

            Form {

                statusSection


                switch target {

                case .completed:

                    completedSection


                case .chosen,
                     .alternative:

                    futureRouteSection
                }
            }
            .navigationTitle(
                title
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
                        "Done"
                    ) {

                        dismiss()
                    }
                }
            }
        }
    }
}


private extension RouteInspectorView {

    var title:
        String {

        switch target {

        case .completed:

            return "Completed Route"


        case .chosen:

            return "Chosen Route"


        case .alternative:

            return "Alternative Route"
        }
    }


    var statusSection:
        some View {

        Section {

            HStack {

                Image(
                    systemName:
                        statusSymbol
                )


                Text(
                    statusText
                )
                .fontWeight(
                    .semibold
                )
            }

        } header: {

            Text(
                "Status"
            )
        }
    }


    var statusText:
        String {

        switch target {

        case .completed:

            return "Completed History"


        case .chosen:

            return "Current Chosen Route"


        case .alternative:

            return "Alternative Route"
        }
    }


    var statusSymbol:
        String {

        switch target {

        case .completed:

            return "checkmark.circle.fill"


        case .chosen:

            return "location.fill"


        case .alternative:

            return "arrow.triangle.branch"
        }
    }
}

private extension RouteInspectorView {

    var completedSection:
        some View {

        Section(
            "History"
        ) {

            LabeledContent(
                "Road Segments",
                value:
                    "\(completedRoute.segments.count)"
            )


            LabeledContent(
                "Reached Stops",
                value:
                    "\(completedRoute.reachedNodeIDs.count)"
            )


            if let throughTime =
                completedRoute
                    .throughTime
            {

                LabeledContent(
                    "Completed Through",
                    value:
                        throughTime
                            .displayClockString
                )
            }
        }
    }
}

private extension RouteInspectorView {
    @ViewBuilder
    var futureRouteSection: some View {
        if let route = inspectedRoute {
            Section("Route") {
                LabeledContent("Stops", value: "\(route.stopNodeIDs.count)")
                LabeledContent("Legs", value: "\(route.legs.count)")
                LabeledContent("Road Segments", value: "\(route.legs.reduce(0) { result, leg in result + (leg.path?.segments.count ?? 0) })")
                
                if let totalCost = route.plannedTotalCost {
                    LabeledContent("Routing Cost") {
                        Text(totalCost, format: .number.precision(.fractionLength(0)))
                    }
                }
            }
            
            if case let .alternative(routeID) = target {
                alternativeComparisonSection(route: route)
                
                Section {
                    Button {

                        let succeeded =
                            onChoose?(
                                routeID
                            )
                            ??
                            false


                        if succeeded {

                            dismiss()

                        } else {

                            routeSwitchFailed =
                                true
                        }

                    } label: {

                        Label(
                            "Choose This Route",
                            systemImage:
                                "checkmark.circle.fill"
                        )
                        .frame(
                            maxWidth:
                                .infinity
                        )
                    }
                    .alert(
                        "Route Cannot Be Selected",
                        isPresented:
                            $routeSwitchFailed
                    ) {

                        Button(
                            "OK",
                            role:
                                .cancel
                        ) {

                        }

                    } message: {

                        Text(
                            "This route no longer connects to your current completed-route position."
                        )
                    }
                }
            }
        } else {
            Section {
                ContentUnavailableView("Route Not Found", systemImage: "exclamationmark.triangle")
            }
        }
    }
}

private extension RouteInspectorView {

    func alternativeComparisonSection(
        route:
            GameRoute
    ) -> some View {

        Section(
            "Compared With Chosen Route"
        ) {

            if let ratio =
                route.costRatio(
                    comparedTo:
                        chosenRoute
                )
            {

                let percentDifference =
                    (
                        ratio - 1
                    )
                    *
                    100


                LabeledContent(
                    "Cost Difference"
                ) {

                    Text(
                        percentDifference,
                        format:
                            .number
                            .precision(
                                .fractionLength(
                                    1
                                )
                            )
                    )

                    Text("%")
                }
            }


            if let difference =
                route.costDifference(
                    comparedTo:
                        chosenRoute
                )
            {

                LabeledContent(
                    "Additional Cost"
                ) {

                    Text(
                        difference,
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
        }
    }
}


