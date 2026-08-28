//
//  MealPlayablePathView.swift
//  fifoogame
//
//  Pass 5.19 — situation-aware playable meal path.
//

import SwiftUI


// =====================================================
// MARK: - Meal Source / Situation
// =====================================================

enum MealPathSource:
    String,
    CaseIterable,
    Identifiable,
    Codable,
    Sendable {

    case homeCooked
    case restaurant
    case storeBought
    case friend

    var id: String { rawValue }

    var title: String {
        switch self {
        case .homeCooked: return "Home-made"
        case .restaurant: return "Restaurant"
        case .storeBought: return "Store-bought"
        case .friend: return "Friend's place"
        }
    }

    var systemImage: String {
        switch self {
        case .homeCooked: return "house.fill"
        case .restaurant: return "fork.knife"
        case .storeBought: return "cart.fill"
        case .friend: return "person.2.fill"
        }
    }
}


enum MealRestaurantMode:
    String,
    CaseIterable,
    Identifiable,
    Codable,
    Sendable {

    case dineIn
    case takeout
    case delivery

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dineIn: return "Dine In"
        case .takeout: return "Takeout"
        case .delivery: return "Delivery"
        }
    }
}


enum MealStoreMode:
    String,
    CaseIterable,
    Identifiable,
    Codable,
    Sendable {

    case shopInStore
    case pickup
    case delivery

    var id: String { rawValue }

    var title: String {
        switch self {
        case .shopInStore: return "Shop"
        case .pickup: return "Pickup"
        case .delivery: return "Delivery"
        }
    }
}


struct MealPathSituation:
    Equatable,
    Sendable {

    var source: MealPathSource = .homeCooked

    // Home-made
    var ingredientsOnHand = false
    var recipeReady = false

    // Restaurant
    var restaurantName = "Burger King"
    var restaurantOpen = true
    var restaurantMode: MealRestaurantMode = .takeout

    // Store-bought
    var storeName = "Grocery Store"
    var itemInStock = true
    var storeMode: MealStoreMode = .shopInStore
    var needsHeating = true

    // Friend
    var friendName = "Friend"
    var invitationConfirmed = true
    var friendMealReady = true
    var bringSomething = false
}


// =====================================================
// MARK: - Path Stop
// =====================================================

struct MealPathStop:
    Identifiable,
    Equatable,
    Sendable {

    enum Kind:
        String,
        Equatable,
        Sendable {

        case meal
        case source
        case ingredients
        case travel
        case store
        case restaurant
        case recipe
        case preparation
        case order
        case wait
        case serve
        case enjoy
    }

    let id: String
    let section: String
    let title: String
    let detail: String
    let systemImage: String
    let estimatedMinutes: Int
    let kind: Kind
}


// =====================================================
// MARK: - Path Builder
// =====================================================

struct MealPathBuilder {

    static func build(
        mealTitle: String,
        scheduledTime: String,
        situation: MealPathSituation
    ) -> [MealPathStop] {

        let meal =
            mealTitle
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
                .isEmpty
            ? "Meal"
            : mealTitle

        var stops: [MealPathStop] = [
            stop(
                "view-meal",
                section: "Meal",
                title: "View \(meal)",
                detail: scheduledTime.isEmpty
                    ? "Review the meal you plan to enjoy."
                    : "Review the meal scheduled for \(scheduledTime).",
                icon: "fork.knife.circle.fill",
                minutes: 1,
                kind: .meal
            )
        ]

        switch situation.source {

        case .homeCooked:
            stops += homeCookedStops(
                meal: meal,
                situation: situation
            )

        case .restaurant:
            stops += restaurantStops(
                meal: meal,
                situation: situation
            )

        case .storeBought:
            stops += storeBoughtStops(
                meal: meal,
                situation: situation
            )

        case .friend:
            stops += friendStops(
                meal: meal,
                situation: situation
            )
        }

        stops.append(
            stop(
                "eat-meal",
                section: "Enjoy",
                title: "Eat \(meal)",
                detail: "The path always ends here: sit down and enjoy the meal.",
                icon: "face.smiling.inverse",
                minutes: 20,
                kind: .enjoy
            )
        )

        return stops
    }


    private static func homeCookedStops(
        meal: String,
        situation: MealPathSituation
    ) -> [MealPathStop] {

        var result: [MealPathStop] = [
            stop(
                "source-home",
                section: "Source",
                title: "Make it at home",
                detail: "Use the home-made path for \(meal).",
                icon: "house.fill",
                minutes: 1,
                kind: .source
            ),
            stop(
                "check-ingredients",
                section: "Ingredients",
                title: "Check ingredients",
                detail: "Confirm what you already have before starting.",
                icon: "list.bullet.clipboard.fill",
                minutes: 3,
                kind: .ingredients
            )
        ]

        if !situation.ingredientsOnHand {
            result += [
                stop(
                    "grocery-store",
                    section: "Ingredients",
                    title: "Go to Grocery Store",
                    detail: "Travel to a store that has the missing ingredients.",
                    icon: "car.fill",
                    minutes: 12,
                    kind: .travel
                ),
                stop(
                    "buy-ingredients",
                    section: "Ingredients",
                    title: "Buy ingredients",
                    detail: "Collect the ingredients needed for \(meal).",
                    icon: "cart.fill",
                    minutes: 15,
                    kind: .store
                ),
                stop(
                    "return-home",
                    section: "Ingredients",
                    title: "Return home",
                    detail: "Bring the ingredients back to your kitchen.",
                    icon: "house.fill",
                    minutes: 12,
                    kind: .travel
                )
            ]
        } else {
            result.append(
                stop(
                    "ingredients-ready",
                    section: "Ingredients",
                    title: "Ingredients ready",
                    detail: "Everything needed is already available at home.",
                    icon: "checkmark.circle.fill",
                    minutes: 1,
                    kind: .ingredients
                )
            )
        }

        if !situation.recipeReady {
            result.append(
                stop(
                    "choose-recipe",
                    section: "Recipe",
                    title: "Choose recipe",
                    detail: "Pick the recipe and review its cooking steps.",
                    icon: "book.closed.fill",
                    minutes: 5,
                    kind: .recipe
                )
            )
        }

        result += [
            stop(
                "prep-home",
                section: "Recipe",
                title: "Prep ingredients",
                detail: "Measure, cut, season, and organize everything before cooking.",
                icon: "takeoutbag.and.cup.and.straw.fill",
                minutes: 10,
                kind: .preparation
            ),
            stop(
                "cook-home",
                section: "Recipe",
                title: "Cook step-by-step",
                detail: "Play through the recipe one step at a time until the meal is ready.",
                icon: "flame.fill",
                minutes: 20,
                kind: .preparation
            ),
            stop(
                "plate-home",
                section: "Serve",
                title: "Plate the meal",
                detail: "Finish, plate, and get ready to eat.",
                icon: "circle.grid.2x2.fill",
                minutes: 3,
                kind: .serve
            )
        ]

        return result
    }


    private static func restaurantStops(
        meal: String,
        situation: MealPathSituation
    ) -> [MealPathStop] {

        let restaurant =
            situation.restaurantName
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
                .isEmpty
            ? "Restaurant"
            : situation.restaurantName

        var result: [MealPathStop] = [
            stop(
                "source-restaurant",
                section: "Source",
                title: "Get it from a restaurant",
                detail: "Use a prepared-food path for \(meal).",
                icon: "fork.knife",
                minutes: 1,
                kind: .source
            )
        ]

        if situation.restaurantOpen {
            result.append(
                stop(
                    "restaurant-selected",
                    section: "Restaurant",
                    title: restaurant,
                    detail: "Restaurant selected and available.",
                    icon: "building.2.fill",
                    minutes: 1,
                    kind: .restaurant
                )
            )
        } else {
            result += [
                stop(
                    "restaurant-unavailable",
                    section: "Restaurant",
                    title: "Restaurant unavailable",
                    detail: "The first restaurant cannot fulfill the meal right now.",
                    icon: "exclamationmark.triangle.fill",
                    minutes: 1,
                    kind: .restaurant
                ),
                stop(
                    "find-open-restaurant",
                    section: "Restaurant",
                    title: "Find an open restaurant",
                    detail: "Choose the next available restaurant serving \(meal).",
                    icon: "magnifyingglass.circle.fill",
                    minutes: 4,
                    kind: .restaurant
                )
            ]
        }

        switch situation.restaurantMode {

        case .dineIn:
            result += [
                stop(
                    "travel-restaurant",
                    section: "Travel",
                    title: "Go to the restaurant",
                    detail: "Travel to the restaurant before the scheduled meal time.",
                    icon: "car.fill",
                    minutes: 12,
                    kind: .travel
                ),
                stop(
                    "order-dine-in",
                    section: "Order",
                    title: "Order \(meal)",
                    detail: "Place the dine-in order.",
                    icon: "menucard.fill",
                    minutes: 5,
                    kind: .order
                ),
                stop(
                    "wait-dine-in",
                    section: "Order",
                    title: "Wait for the meal",
                    detail: "The restaurant prepares and serves it.",
                    icon: "clock.fill",
                    minutes: 12,
                    kind: .wait
                )
            ]

        case .takeout:
            result += [
                stop(
                    "order-takeout",
                    section: "Order",
                    title: "Place takeout order",
                    detail: "Order \(meal) for pickup.",
                    icon: "bag.fill",
                    minutes: 3,
                    kind: .order
                ),
                stop(
                    "travel-pickup",
                    section: "Travel",
                    title: "Go to \(restaurant)",
                    detail: "Travel to the restaurant when the order is nearly ready.",
                    icon: "car.fill",
                    minutes: 12,
                    kind: .travel
                ),
                stop(
                    "pickup-restaurant",
                    section: "Order",
                    title: "Pick up the meal",
                    detail: "Collect the takeout order.",
                    icon: "takeoutbag.and.cup.and.straw.fill",
                    minutes: 4,
                    kind: .order
                ),
                stop(
                    "return-home-restaurant",
                    section: "Travel",
                    title: "Take it home",
                    detail: "Return home with the meal.",
                    icon: "house.fill",
                    minutes: 12,
                    kind: .travel
                )
            ]

        case .delivery:
            result += [
                stop(
                    "order-delivery",
                    section: "Order",
                    title: "Place delivery order",
                    detail: "Order \(meal) for delivery to home.",
                    icon: "iphone.gen3",
                    minutes: 3,
                    kind: .order
                ),
                stop(
                    "wait-delivery",
                    section: "Delivery",
                    title: "Track delivery",
                    detail: "Wait while the restaurant prepares and delivers the meal.",
                    icon: "location.fill",
                    minutes: 25,
                    kind: .wait
                ),
                stop(
                    "receive-delivery",
                    section: "Delivery",
                    title: "Receive the meal",
                    detail: "Bring the delivered order inside and get ready to eat.",
                    icon: "door.left.hand.open",
                    minutes: 2,
                    kind: .serve
                )
            ]
        }

        return result
    }


    private static func storeBoughtStops(
        meal: String,
        situation: MealPathSituation
    ) -> [MealPathStop] {

        let store =
            situation.storeName
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
                .isEmpty
            ? "Store"
            : situation.storeName

        var result: [MealPathStop] = [
            stop(
                "source-store",
                section: "Source",
                title: "Buy it prepared",
                detail: "Use a store-bought path for \(meal).",
                icon: "cart.fill",
                minutes: 1,
                kind: .source
            ),
            stop(
                "store-selected",
                section: "Store",
                title: store,
                detail: "Store selected for the meal.",
                icon: "storefront.fill",
                minutes: 1,
                kind: .store
            )
        ]

        if !situation.itemInStock {
            result += [
                stop(
                    "store-out-of-stock",
                    section: "Store",
                    title: "Meal is out of stock",
                    detail: "The first store cannot fulfill this meal.",
                    icon: "xmark.circle.fill",
                    minutes: 1,
                    kind: .store
                ),
                stop(
                    "find-alternate-store",
                    section: "Store",
                    title: "Find another store",
                    detail: "Locate the same or a suitable replacement meal nearby.",
                    icon: "magnifyingglass.circle.fill",
                    minutes: 4,
                    kind: .store
                )
            ]
        }

        switch situation.storeMode {

        case .shopInStore:
            result += [
                stop(
                    "travel-store",
                    section: "Travel",
                    title: "Go to the store",
                    detail: "Travel to the selected store.",
                    icon: "car.fill",
                    minutes: 10,
                    kind: .travel
                ),
                stop(
                    "buy-store-meal",
                    section: "Store",
                    title: "Buy \(meal)",
                    detail: "Find, purchase, and bag the prepared meal.",
                    icon: "basket.fill",
                    minutes: 10,
                    kind: .store
                ),
                stop(
                    "return-home-store",
                    section: "Travel",
                    title: "Return home",
                    detail: "Bring the meal home.",
                    icon: "house.fill",
                    minutes: 10,
                    kind: .travel
                )
            ]

        case .pickup:
            result += [
                stop(
                    "order-store-pickup",
                    section: "Store",
                    title: "Reserve for pickup",
                    detail: "Place the store order before leaving.",
                    icon: "iphone.gen3",
                    minutes: 3,
                    kind: .order
                ),
                stop(
                    "pickup-store",
                    section: "Travel",
                    title: "Pick up from \(store)",
                    detail: "Travel to the store and collect the order.",
                    icon: "car.fill",
                    minutes: 15,
                    kind: .travel
                ),
                stop(
                    "return-home-store-pickup",
                    section: "Travel",
                    title: "Return home",
                    detail: "Bring the prepared meal home.",
                    icon: "house.fill",
                    minutes: 10,
                    kind: .travel
                )
            ]

        case .delivery:
            result += [
                stop(
                    "order-store-delivery",
                    section: "Store",
                    title: "Order store delivery",
                    detail: "Have the prepared meal delivered to home.",
                    icon: "iphone.gen3",
                    minutes: 3,
                    kind: .order
                ),
                stop(
                    "wait-store-delivery",
                    section: "Delivery",
                    title: "Wait for delivery",
                    detail: "Track the store order until it arrives.",
                    icon: "clock.fill",
                    minutes: 25,
                    kind: .wait
                )
            ]
        }

        if situation.needsHeating {
            result.append(
                stop(
                    "heat-store-meal",
                    section: "Prepare",
                    title: "Heat and plate",
                    detail: "Warm the meal according to its instructions and plate it.",
                    icon: "flame.fill",
                    minutes: 8,
                    kind: .preparation
                )
            )
        } else {
            result.append(
                stop(
                    "plate-store-meal",
                    section: "Prepare",
                    title: "Plate the meal",
                    detail: "Open, portion, and get the meal ready to eat.",
                    icon: "circle.grid.2x2.fill",
                    minutes: 2,
                    kind: .serve
                )
            )
        }

        return result
    }


    private static func friendStops(
        meal: String,
        situation: MealPathSituation
    ) -> [MealPathStop] {

        let friend =
            situation.friendName
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
                .isEmpty
            ? "Friend"
            : situation.friendName

        var result: [MealPathStop] = [
            stop(
                "source-friend",
                section: "Source",
                title: "Eat at \(friend)'s",
                detail: "Use the friend's-place path for \(meal).",
                icon: "person.2.fill",
                minutes: 1,
                kind: .source
            )
        ]

        if situation.invitationConfirmed {
            result.append(
                stop(
                    "confirm-friend",
                    section: "Friend",
                    title: "Plans confirmed",
                    detail: "Meal time and location are confirmed with \(friend).",
                    icon: "checkmark.message.fill",
                    minutes: 1,
                    kind: .source
                )
            )
        } else {
            result.append(
                stop(
                    "contact-friend",
                    section: "Friend",
                    title: "Confirm the plan",
                    detail: "Message \(friend) to confirm the meal time before leaving.",
                    icon: "message.fill",
                    minutes: 3,
                    kind: .source
                )
            )
        }

        if situation.bringSomething {
            result.append(
                stop(
                    "bring-something",
                    section: "Friend",
                    title: "Pick up something to bring",
                    detail: "Grab a drink, side, dessert, or other item before heading over.",
                    icon: "bag.fill",
                    minutes: 10,
                    kind: .store
                )
            )
        }

        result.append(
            stop(
                "travel-friend",
                section: "Travel",
                title: "Go to \(friend)'s",
                detail: "Travel to the meal location.",
                icon: "car.fill",
                minutes: 15,
                kind: .travel
            )
        )

        if situation.friendMealReady {
            result.append(
                stop(
                    "friend-meal-ready",
                    section: "Serve",
                    title: "Meal is ready",
                    detail: "Join everyone and get ready to eat.",
                    icon: "checkmark.circle.fill",
                    minutes: 2,
                    kind: .serve
                )
            )
        } else {
            result += [
                stop(
                    "help-friend-prep",
                    section: "Prepare",
                    title: "Help finish the meal",
                    detail: "Pitch in with the remaining preparation while the meal finishes.",
                    icon: "hands.sparkles.fill",
                    minutes: 10,
                    kind: .preparation
                ),
                stop(
                    "friend-serve",
                    section: "Serve",
                    title: "Serve the meal",
                    detail: "Bring the finished meal to the table.",
                    icon: "circle.grid.2x2.fill",
                    minutes: 3,
                    kind: .serve
                )
            ]
        }

        return result
    }


    private static func stop(
        _ id: String,
        section: String,
        title: String,
        detail: String,
        icon: String,
        minutes: Int,
        kind: MealPathStop.Kind
    ) -> MealPathStop {

        MealPathStop(
            id: id,
            section: section,
            title: title,
            detail: detail,
            systemImage: icon,
            estimatedMinutes: minutes,
            kind: kind
        )
    }
}


// =====================================================
// MARK: - Playable Meal Path
// =====================================================

struct MealPlayablePathView: View {

    let mealTitle: String
    let scheduledTime: String

    @State private var situation =
        MealPathSituation()

    @State private var currentStepIndex = 0

    @State private var completedStopIDs:
        Set<String> = []


    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 16
        ) {

            header

            sourcePicker

            situationControls

            pathSummary

            MealPathMapView(
                stops: stops,
                currentStepIndex: currentStepIndex,
                completedStopIDs: completedStopIDs,
                onTapStop: playStop
            )

            currentStepControls
        }
        .padding(
            .vertical,
            4
        )
        .onChange(
            of: situation
        ) { _, _ in
            resetPathProgress()
        }
    }
}


private extension MealPlayablePathView {

    var stops: [MealPathStop] {
        MealPathBuilder.build(
            mealTitle: mealTitle,
            scheduledTime: scheduledTime,
            situation: situation
        )
    }


    var header: some View {

        VStack(
            alignment: .leading,
            spacing: 6
        ) {

            Text("Meal Path")
                .font(.title3)
                .fontWeight(.bold)

            Text(
                scheduledTime.isEmpty
                    ? mealTitle
                    : "\(mealTitle) • \(scheduledTime)"
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)

            Text(
                "Choose how you will source the meal. The playable path rebuilds automatically when the situation changes, but every branch ends with eating the meal."
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }


    var sourcePicker: some View {

        VStack(
            alignment: .leading,
            spacing: 8
        ) {

            Text("Source")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            Picker(
                "Source",
                selection: $situation.source
            ) {

                ForEach(
                    MealPathSource.allCases
                ) { source in

                    Label(
                        source.title,
                        systemImage: source.systemImage
                    )
                    .tag(source)
                }
            }
            .pickerStyle(.menu)
        }
    }


    @ViewBuilder
    var situationControls: some View {

        VStack(
            alignment: .leading,
            spacing: 10
        ) {

            Text("Situation")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            switch situation.source {

            case .homeCooked:

                Toggle(
                    "Ingredients already at home",
                    isOn: $situation.ingredientsOnHand
                )

                Toggle(
                    "Recipe already selected",
                    isOn: $situation.recipeReady
                )

            case .restaurant:

                TextField(
                    "Restaurant",
                    text: $situation.restaurantName
                )
                .textFieldStyle(.roundedBorder)

                Toggle(
                    "Restaurant is available",
                    isOn: $situation.restaurantOpen
                )

                Picker(
                    "How to get it",
                    selection: $situation.restaurantMode
                ) {
                    ForEach(
                        MealRestaurantMode.allCases
                    ) { mode in
                        Text(mode.title)
                            .tag(mode)
                    }
                }
                .pickerStyle(.segmented)

            case .storeBought:

                TextField(
                    "Store",
                    text: $situation.storeName
                )
                .textFieldStyle(.roundedBorder)

                Toggle(
                    "Meal is in stock",
                    isOn: $situation.itemInStock
                )

                Toggle(
                    "Needs heating/preparation",
                    isOn: $situation.needsHeating
                )

                Picker(
                    "How to get it",
                    selection: $situation.storeMode
                ) {
                    ForEach(
                        MealStoreMode.allCases
                    ) { mode in
                        Text(mode.title)
                            .tag(mode)
                    }
                }
                .pickerStyle(.segmented)

            case .friend:

                TextField(
                    "Friend",
                    text: $situation.friendName
                )
                .textFieldStyle(.roundedBorder)

                Toggle(
                    "Plans already confirmed",
                    isOn: $situation.invitationConfirmed
                )

                Toggle(
                    "Meal will be ready",
                    isOn: $situation.friendMealReady
                )

                Toggle(
                    "Bring something",
                    isOn: $situation.bringSomething
                )
            }
        }
    }


    var pathSummary: some View {

        HStack(
            spacing: 12
        ) {

            Label(
                "\(stops.count) stops",
                systemImage: "map.fill"
            )

            Label(
                "~\(totalMinutes) min",
                systemImage: "clock.fill"
            )

            Spacer()

            if currentStepIndex >= stops.count {

                Text("Meal complete")
                    .fontWeight(.semibold)
                    .foregroundStyle(.green)
            }
        }
        .font(.caption)
    }


    var totalMinutes: Int {
        stops.reduce(0) {
            $0 + $1.estimatedMinutes
        }
    }


    @ViewBuilder
    var currentStepControls: some View {

        if currentStepIndex < stops.count {

            let current =
                stops[currentStepIndex]

            VStack(
                alignment: .leading,
                spacing: 10
            ) {

                Text("Current Stop")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(current.title)
                    .fontWeight(.semibold)

                Text(current.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button {
                    playStop(current)
                } label: {

                    Label(
                        current.kind == .enjoy
                            ? "Enjoy Meal"
                            : "Complete Stop",
                        systemImage:
                            current.kind == .enjoy
                            ? "fork.knife"
                            : "checkmark.circle.fill"
                    )
                    .frame(
                        maxWidth: .infinity
                    )
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(12)
            .background(
                .thinMaterial,
                in: RoundedRectangle(
                    cornerRadius: 14,
                    style: .continuous
                )
            )

        } else {

            VStack(
                spacing: 8
            ) {

                Image(
                    systemName: "checkmark.circle.fill"
                )
                .font(.title)
                .foregroundStyle(.green)

                Text("Meal path complete")
                    .fontWeight(.bold)

                Text("You reached the final stop and ate the meal.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button("Play Again") {
                    resetPathProgress()
                }
                .buttonStyle(.bordered)
            }
            .frame(
                maxWidth: .infinity
            )
            .padding(12)
        }
    }


    func playStop(
        _ stop: MealPathStop
    ) {

        guard
            currentStepIndex < stops.count,
            stops[currentStepIndex].id == stop.id
        else {
            return
        }

        withAnimation(.snappy) {

            completedStopIDs.insert(
                stop.id
            )

            currentStepIndex += 1
        }
    }


    func resetPathProgress() {

        withAnimation(.snappy) {
            currentStepIndex = 0
            completedStopIDs.removeAll()
        }
    }
}


// =====================================================
// MARK: - Mini Map
// =====================================================

private struct MealPathMapView: View {

    let stops: [MealPathStop]
    let currentStepIndex: Int
    let completedStopIDs: Set<String>
    let onTapStop: (MealPathStop) -> Void


    var body: some View {

        VStack(
            spacing: 0
        ) {

            ForEach(
                Array(stops.enumerated()),
                id: \.element.id
            ) { index, stop in

                pathRow(
                    stop,
                    index: index
                )

                if index < stops.count - 1 {

                    pathArrow(
                        fromIndex: index
                    )
                }
            }
        }
        .padding(
            .vertical,
            4
        )
    }


    @ViewBuilder
    func pathRow(
        _ stop: MealPathStop,
        index: Int
    ) -> some View {

        HStack {

            if index.isMultiple(of: 2) {

                MealPathStopCard(
                    stop: stop,
                    state: state(for: index)
                )
                .onTapGesture {
                    onTapStop(stop)
                }

                Spacer(
                    minLength: 48
                )

            } else {

                Spacer(
                    minLength: 48
                )

                MealPathStopCard(
                    stop: stop,
                    state: state(for: index)
                )
                .onTapGesture {
                    onTapStop(stop)
                }
            }
        }
    }


    func pathArrow(
        fromIndex index: Int
    ) -> some View {

        HStack {

            Spacer()

            Image(
                systemName:
                    index.isMultiple(of: 2)
                    ? "arrow.down.right"
                    : "arrow.down.left"
            )
            .font(
                .system(
                    size: 18,
                    weight: .bold
                )
            )
            .foregroundStyle(
                index < currentStepIndex
                    ? Color.green
                    : Color.secondary.opacity(0.55)
            )
            .frame(
                width: 56,
                height: 34
            )

            Spacer()
        }
    }


    func state(
        for index: Int
    ) -> MealPathStopCard.State {

        if index < currentStepIndex {
            return .completed
        }

        if index == currentStepIndex {
            return .current
        }

        return .future
    }
}


private struct MealPathStopCard: View {

    enum State {
        case completed
        case current
        case future
    }

    let stop: MealPathStop
    let state: State


    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 6
        ) {

            HStack {

                Image(
                    systemName: stop.systemImage
                )

                Spacer()

                if state == .completed {
                    Image(
                        systemName: "checkmark.circle.fill"
                    )
                    .foregroundStyle(.green)
                }
            }

            Text(stop.section.uppercased())
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundStyle(.secondary)

            Text(stop.title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(2)

            Text("~\(stop.estimatedMinutes) min")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(
            maxWidth: 210,
            alignment: .leading
        )
        .padding(12)
        .background(
            background,
            in: RoundedRectangle(
                cornerRadius: 14,
                style: .continuous
            )
        )
        .overlay {

            if state == .current {

                RoundedRectangle(
                    cornerRadius: 14,
                    style: .continuous
                )
                .stroke(
                    Color.green,
                    lineWidth: 2
                )
            }
        }
        .opacity(
            state == .future
                ? 0.72
                : 1
        )
        .contentShape(
            RoundedRectangle(
                cornerRadius: 14,
                style: .continuous
            )
        )
    }


    var background: some ShapeStyle {

        switch state {
        case .completed:
            return AnyShapeStyle(
                Color.green.opacity(0.12)
            )
        case .current:
            return AnyShapeStyle(
                .thinMaterial
            )
        case .future:
            return AnyShapeStyle(
                Color.secondary.opacity(0.08)
            )
        }
    }
}
