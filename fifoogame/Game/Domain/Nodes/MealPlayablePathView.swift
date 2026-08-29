//
//  MealPlayablePathView.swift
//  fifoogame
//
//  Pass 5.28 — full-screen ActivityMeal welcome + action experience.
//

import SwiftUI
import UIKit


// =====================================================
// MARK: - Meal Experience Domain
// =====================================================

enum ActivityMealExperienceState:
    Equatable,
    Sendable {

    case welcome
    case action
}


/// Identifies which editable time on the ActivityMeal welcome page is
/// currently being changed by the wheel-style time picker.
enum ActivityMealWelcomeTimePickerTarget:
    Equatable,
    Sendable {

    case start
    case end
}


enum ActivityMealSource:
    String,
    CaseIterable,
    Identifiable,
    Sendable {

    case homeMade
    case restaurantOrStore
    case invited

    var id: String { rawValue }

    var title: String {
        switch self {
        case .homeMade: return "Home-made"
        case .restaurantOrStore: return "Restaurant / Store"
        case .invited: return "Hosted / Invited"
        }
    }

    var subtitle: String {
        switch self {
        case .homeMade:
            return "Recipe, ingredients, shopping, preparation and cooking."
        case .restaurantOrStore:
            return "Restaurant, takeout, delivery, pickup or ready-made store meal."
        case .invited:
            return "A friend, host, dinner party or event provides most of the meal."
        }
    }

    var systemImage: String {
        switch self {
        case .homeMade: return "house.fill"
        case .restaurantOrStore: return "fork.knife"
        case .invited: return "person.2.fill"
        }
    }
}


enum ActivityMealFulfillmentMode:
    String,
    CaseIterable,
    Identifiable,
    Sendable {

    case dineIn
    case takeout
    case delivery
    case storePickup

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dineIn: return "Dine In"
        case .takeout: return "Takeout"
        case .delivery: return "Delivery"
        case .storePickup: return "Store Pickup"
        }
    }
}


enum ActivityMealPresentedSheet:
    String,
    Identifiable {

    case browseMeals
    case recipeDetails
    case browseRecipes
    case ingredients
    case shoppingList
    case ingredientStores
    case venues
    case friends
    case friendChat
    case contributionItems

    var id: String { rawValue }
}


struct ActivityMealBrowseChoice:
    Identifiable,
    Equatable,
    Sendable {

    var id: String
    var title: String
    var subtitle: String
    var imageURL: String?
}


struct ActivityMealRecipeInstruction:
    Identifiable,
    Equatable,
    Sendable {

    var id: String
    var title: String
    var detail: String
    var timerSeconds: Int?
}


struct ActivityMealRecipeOption:
    Identifiable,
    Equatable,
    Sendable {

    var id: String
    var title: String
    var subtitle: String
    var estimatedMinutes: Int
    var ingredients: [String]
    var instructions: [ActivityMealRecipeInstruction]
}


struct ActivityMealStoreOption:
    Identifiable,
    Equatable,
    Sendable {

    var id: String
    var name: String
    var address: String
    var distanceMiles: Double
    var hours: String
    var isOpen: Bool
}


struct ActivityMealVenueOption:
    Identifiable,
    Equatable,
    Sendable {

    var id: String
    var name: String
    var address: String
    var distanceMiles: Double
    var hours: String
    var isOpen: Bool
    var isStore: Bool
}


struct ActivityMealFriendOption:
    Identifiable,
    Equatable,
    Sendable {

    var id: String
    var name: String
    var subtitle: String
    var chatAvailable: Bool
}


struct ActivityMealActionStep:
    Identifiable,
    Equatable,
    Sendable {

    enum Kind:
        Equatable,
        Sendable {

        case confirmMeal
        case chooseSource
        case recipe
        case ingredients
        case shopping
        case recipeInstruction(Int)
        case venue
        case availability
        case order
        case host
        case invitation
        case contribution
        case travel
        case serve
        case enjoy
    }

    let id: String
    let title: String
    let eyebrow: String
    let instruction: String
    let systemImage: String
    let kind: Kind
    let estimatedMinutes: Int?
    let timerSeconds: Int?
}


// =====================================================
// MARK: - Full-screen Meal Experience
// =====================================================

struct ActivityMealExperienceView: View {

    let node: GameMapNode
    let roadGraph: RoadGraph
    let onUpdate: (GameMapNode) -> Void
    let onDelete: () -> Void
    let onCompleted: (GameMapNode) -> Void

    @State private var draft: GameMapNode
    @State private var experienceState: ActivityMealExperienceState = .welcome

    @State private var suggestedMealName: String
    @State private var source: ActivityMealSource = .homeMade

    @State private var mealConfirmed = false

    @State private var recipeName = "Recommended Recipe"
    @State private var ingredientsReady = false
    @State private var groceriesNeeded = true
    @State private var ingredients: [String] = []
    @State private var shoppingList: [String] = []
    @State private var ingredientStoreName = ""

    @State private var venueName = "Restaurant or Store"
    @State private var venueLocation = ""
    @State private var venueHours = "Open now"
    @State private var venueAvailable = true
    @State private var fulfillmentMode: ActivityMealFulfillmentMode = .takeout

    @State private var hostName = "Host"
    @State private var selectedHostID: String?
    @State private var eventLocation = ""
    @State private var invitationConfirmed = true
    @State private var contribution = "Nothing required"
    @State private var contributionItems: [String] = []

    @State private var currentStepIndex = 0
    @State private var pendingRestoredStepID: String?
    @State private var completedStepIDs: Set<String> = []
    @State private var skippedStepIDs: Set<String> = []

    @State private var isShowingSkipConfirmation = false
    @State private var isShowingDoneConfirmation = false
    @State private var activeWelcomeTimePicker: ActivityMealWelcomeTimePickerTarget?
    @State private var presentedSheet: ActivityMealPresentedSheet?

    @Environment(\.dismiss) private var dismiss


    init(
        node: GameMapNode,
        roadGraph: RoadGraph,
        onUpdate: @escaping (GameMapNode) -> Void,
        onDelete: @escaping () -> Void,
        onCompleted: @escaping (GameMapNode) -> Void
    ) {

        self.node = node
        self.roadGraph = roadGraph
        self.onUpdate = onUpdate
        self.onDelete = onDelete
        self.onCompleted = onCompleted

        _draft = State(initialValue: node)

        let activityContent: ActivityNodeContent?
        if case let .activity(content) = node.content {
            activityContent = content
        } else {
            activityContent = nil
        }

        let mealName =
            activityContent?.meal?.title.isEmpty == false
            ? (activityContent?.meal?.title ?? activityContent?.title ?? node.content.title)
            : (activityContent?.title ?? node.content.title)

        let plan = activityContent?.meal?.executionPlan

        _suggestedMealName = State(
            initialValue: plan?.selectedMealName.isEmpty == false
                ? (plan?.selectedMealName ?? mealName)
                : mealName
        )

        _source = State(
            initialValue: ActivityMealSource(rawValue: plan?.source ?? "") ?? .homeMade
        )
        _mealConfirmed = State(initialValue: plan?.mealConfirmed ?? false)
        _recipeName = State(
            initialValue: plan?.recipeName.isEmpty == false
                ? (plan?.recipeName ?? "Classic \(mealName)")
                : "Classic \(mealName)"
        )
        _ingredientsReady = State(initialValue: plan?.ingredientsReady ?? false)
        _groceriesNeeded = State(initialValue: plan?.groceriesNeeded ?? true)

        let defaultIngredients = [
            "Main ingredients for \(mealName)",
            "Seasoning",
            "Cooking oil or butter",
            "Optional garnish"
        ]
        _ingredients = State(initialValue: plan?.ingredients ?? defaultIngredients)
        _shoppingList = State(initialValue: plan?.shoppingList ?? defaultIngredients)
        _ingredientStoreName = State(initialValue: plan?.ingredientStoreName ?? "")

        _venueName = State(initialValue: plan?.venueName ?? "Restaurant or Store")
        _venueLocation = State(initialValue: plan?.venueLocation ?? "")
        _venueHours = State(initialValue: plan?.venueHours ?? "Open now")
        _venueAvailable = State(initialValue: plan?.venueAvailable ?? true)
        _fulfillmentMode = State(
            initialValue: ActivityMealFulfillmentMode(rawValue: plan?.fulfillmentMode ?? "") ?? .takeout
        )

        _hostName = State(initialValue: plan?.hostName ?? "Host")
        _selectedHostID = State(initialValue: plan?.selectedHostID)
        _eventLocation = State(initialValue: plan?.eventLocation ?? "")
        _invitationConfirmed = State(initialValue: plan?.invitationConfirmed ?? true)
        _contribution = State(initialValue: plan?.contribution ?? "Nothing required")
        _contributionItems = State(
            initialValue: plan?.contributionItems
                ?? (plan?.contribution.isEmpty == false ? [plan?.contribution ?? ""] : [])
        )

        _completedStepIDs = State(initialValue: Set(plan?.completedStepIDs ?? []))
        _skippedStepIDs = State(initialValue: Set(plan?.skippedStepIDs ?? []))
        _pendingRestoredStepID = State(initialValue: plan?.currentStepID)
    }


    var body: some View {

        ZStack {
            switch experienceState {
            case .welcome:
                welcomePage
            case .action:
                actionPage
            }
        }
        // Foreground content respects the device safe area. Individual
        // background layers opt into edge-to-edge rendering themselves.
        .onAppear {
            restorePersistedStepIfNeeded()
        }
        .confirmationDialog(
            "Skip this meal?",
            isPresented: $isShowingSkipConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Meal Stop", role: .destructive) {
                onDelete()
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Skipping removes this meal stop entirely from the day map and redraws the path without it.")
        }
        .confirmationDialog(
            "Mark this meal completed?",
            isPresented: $isShowingDoneConfirmation,
            titleVisibility: .visible
        ) {
            Button("Meal Completed") {
                finishMeal()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This marks the ActivityMeal as completed and returns to the day map.")
        }
        .sheet(item: $presentedSheet) { sheet in
            actionSheetContent(sheet)
        }
    }
}


// =====================================================
// MARK: - Welcome Page
// =====================================================

private extension ActivityMealExperienceView {

    var welcomePage: some View {

        GeometryReader { geometry in
            ZStack {
                MealExperienceBackgroundImage(
                    kind: .activityMeal,
                    image: mealContent?.image
                )

                LinearGradient(
                    colors: [
                        Color.black.opacity(0.40),
                        Color.black.opacity(0.10),
                        Color.black.opacity(0.74)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                // Welcome is intentionally a true full-screen experience.
                // Foreground content ignores the safe area together with the
                // background; generous internal vertical padding keeps the
                // header and controls comfortably away from device edges.
                VStack(spacing: welcomeVerticalSpacing(for: geometry.size.height)) {
                    welcomeHeader
                    editableTimeRow

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Suggested meal")
                            .font(.caption.weight(.semibold))
                            .textCase(.uppercase)
                            .foregroundStyle(.white.opacity(0.72))

                        Text(suggestedMealName)
                            .font(
                                .system(
                                    size: geometry.size.height < 700 ? 28 : 34,
                                    weight: .bold,
                                    design: .rounded
                                )
                            )
                            .foregroundStyle(.white)
                            .lineLimit(2)
                            .minimumScaleFactor(0.72)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Spacer(minLength: geometry.size.height < 700 ? 12 : 28)

                    welcomeControls
                }
                .padding(.horizontal, 20)
                .padding(
                    .top,
                    welcomeTopPadding(for: geometry.size.height)
                )
                .padding(
                    .bottom,
                    welcomeBottomPadding(for: geometry.size.height)
                )
                .frame(
                    width: geometry.size.width,
                    height: geometry.size.height,
                    alignment: .top
                )

                if let target = activeWelcomeTimePicker {
                    welcomeTimePickerOverlay(for: target)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipped()
        }
        .ignoresSafeArea()
    }


    func welcomeTopPadding(
        for height: CGFloat
    ) -> CGFloat {
        height < 700 ? 54 : 72
    }


    func welcomeBottomPadding(
        for height: CGFloat
    ) -> CGFloat {
        height < 700 ? 34 : 48
    }


    func welcomeVerticalSpacing(
        for height: CGFloat
    ) -> CGFloat {
        height < 700 ? 12 : 18
    }


    var welcomeHeader: some View {

        HStack(spacing: 14) {
            Text(activityTitle)
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.8)

            Spacer()

            Button {
                persistDraft()
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.headline.weight(.bold))
                    .frame(width: 42, height: 42)
                    .background(.black.opacity(0.28), in: Circle())
                    .foregroundStyle(.white)
            }
        }
    }


    var editableTimeRow: some View {

        HStack(spacing: 12) {
            mealTimeField(
                title: "Start",
                text: startTimeBinding,
                target: .start
            )

            Image(systemName: "arrow.right")
                .foregroundStyle(.white.opacity(0.7))

            mealTimeField(
                title: "End",
                text: endTimeBinding,
                target: .end
            )
        }
    }


    func mealTimeField(
        title: String,
        text: Binding<String>,
        target: ActivityMealWelcomeTimePickerTarget
    ) -> some View {

        Button {
            withAnimation(.snappy(duration: 0.22)) {
                activeWelcomeTimePicker = target
            }
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.65))

                HStack(spacing: 8) {
                    Text(text.wrappedValue.isEmpty ? "Select time" : text.wrappedValue)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Spacer(minLength: 0)

                    Image(systemName: "clock")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.72))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                .black.opacity(0.25),
                in: RoundedRectangle(cornerRadius: 14)
            )
        }
        .buttonStyle(.plain)
    }


    @ViewBuilder
    func welcomeTimePickerOverlay(
        for target: ActivityMealWelcomeTimePickerTarget
    ) -> some View {

        ZStack(alignment: .bottom) {
            Color.black.opacity(0.38)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.snappy(duration: 0.22)) {
                        activeWelcomeTimePicker = nil
                    }
                }

            VStack(spacing: 10) {
                HStack {
                    Text(target == .start ? "Start Time" : "End Time")
                        .font(.headline.weight(.semibold))

                    Spacer()

                    Button("Done") {
                        withAnimation(.snappy(duration: 0.22)) {
                            activeWelcomeTimePicker = nil
                        }
                    }
                    .font(.headline.weight(.semibold))
                }
                .padding(.horizontal, 18)
                .padding(.top, 16)

                DatePicker(
                    "",
                    selection: welcomeTimeDateBinding(for: target),
                    displayedComponents: .hourAndMinute
                )
                .labelsHidden()
                .datePickerStyle(.wheel)
                .frame(maxWidth: .infinity)
            }
            .foregroundStyle(.primary)
            .background(.ultraThinMaterial)
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 26,
                    topTrailingRadius: 26
                )
            )
            .padding(.bottom, 0)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
        .zIndex(50)
    }


    func welcomeTimeDateBinding(
        for target: ActivityMealWelcomeTimePickerTarget
    ) -> Binding<Date> {

        Binding(
            get: {
                let value =
                    target == .start
                    ? startTimeBinding.wrappedValue
                    : endTimeBinding.wrappedValue

                let fallback =
                    target == .start
                    ? draft.time
                    : DayTime(
                        secondsFromMidnight:
                            min(
                                draft.time.secondsFromMidnight + 3_600,
                                DayTime.secondsPerDay - 60
                            )
                    )

                return dateForMealClockString(
                    value,
                    fallback: fallback
                )
            },
            set: { newDate in
                let dayTime =
                    DayTime.from(
                        date: newDate,
                        timeZone: .current
                    )

                let formatted =
                    dayTime.displayClockString

                if target == .start {
                    startTimeBinding.wrappedValue = formatted
                } else {
                    endTimeBinding.wrappedValue = formatted
                }
            }
        )
    }


    func dateForMealClockString(
        _ value: String,
        fallback: DayTime
    ) -> Date {

        let dayTime =
            parseActivityTime(value)
            ?? fallback

        var calendar =
            Calendar(identifier: .gregorian)

        calendar.timeZone =
            .current

        let startOfToday =
            calendar.startOfDay(for: Date())

        return startOfToday.addingTimeInterval(
            min(
                dayTime.secondsFromMidnight,
                DayTime.secondsPerDay - 60
            )
        )
    }


    var welcomeControls: some View {

        HStack(spacing: 16) {
            welcomeButton(
                title: "Skip",
                systemImage: "forward.end.fill",
                roleColor: .red
            ) {
                isShowingSkipConfirmation = true
            }

            Button {
                persistDraft()
                experienceState = .action
            } label: {
                Image(systemName: "play.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.black)
                    .frame(width: 68, height: 68)
                    .background(.white, in: Circle())
                    .shadow(radius: 12)
            }

            welcomeButton(
                title: "Done",
                systemImage: "checkmark",
                roleColor: .green
            ) {
                isShowingDoneConfirmation = true
            }
        }
    }


    func welcomeButton(
        title: String,
        systemImage: String,
        roleColor: Color,
        action: @escaping () -> Void
    ) -> some View {

        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.headline.weight(.bold))
                Text(title)
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(roleColor.opacity(0.25), in: RoundedRectangle(cornerRadius: 16))
        }
    }
}


// =====================================================
// MARK: - Action Page
// =====================================================

private extension ActivityMealExperienceView {

    var actionPage: some View {

        GeometryReader { geometry in
            let step = currentStep
            let compactHeight = geometry.size.height < 720

            ZStack {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    actionHeader(step: step)
                        .padding(.horizontal, 20)
                        // The action content intentionally stays inside the
                        // safe area. Add a visible breathing-space inset above
                        // the header instead of drawing it into the status bar.
                        .padding(.top, 14)
                        .padding(.bottom, compactHeight ? 4 : 10)

                    Spacer(minLength: compactHeight ? 4 : 10)

                    MealActionStackDeck(
                        step: step,
                        accentIndex: currentStepIndex,
                        deckHeight: actionDeckHeight(for: geometry.size.height),
                        content: {
                            stepInteractiveContent(step)
                        }
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, compactHeight ? 18 : 24)

                    Text(step.instruction)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(compactHeight ? 2 : 4)
                        .minimumScaleFactor(0.85)
                        .padding(.horizontal, 28)
                        .padding(.top, compactHeight ? 10 : 18)

                    if let minutes = step.estimatedMinutes {
                        Label(
                            "About \(minutes) min",
                            systemImage: "clock"
                        )
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.top, compactHeight ? 4 : 8)
                    }

                    Spacer(minLength: compactHeight ? 8 : 16)

                    actionControls
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)
                }
                // GeometryReader already receives the safe-area-sized region
                // because this foreground no longer ignores the safe area.
                // A small explicit top inset makes the page feel intentional
                // on both Dynamic Island and older notch devices.
                .padding(.top, 6)
            }
            .contentShape(Rectangle())
            .simultaneousGesture(actionPagingGesture)
        }
    }


    func actionDeckHeight(
        for availableHeight: CGFloat
    ) -> CGFloat {
        min(
            330,
            max(
                270,
                availableHeight * 0.40
            )
        )
    }


    func actionHeader(
        step: ActivityMealActionStep
    ) -> some View {

        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("STEP \(currentStepIndex + 1) OF \(actionSteps.count)")
                    .font(.caption2.weight(.bold))
                    .tracking(1.1)
                    .foregroundStyle(.secondary)

                Text(step.title)
                    .font(.title2.weight(.bold))

                if completedStepIDs.contains(step.id) {
                    Label("Completed", systemImage: "checkmark.circle.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.green)
                } else if skippedStepIDs.contains(step.id) {
                    Label("Skipped", systemImage: "arrow.down.circle")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.orange)
                }
            }

            Spacer()

            Button {
                persistDraft()
                withAnimation(.snappy(duration: 0.24)) {
                    experienceState = .welcome
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.headline.weight(.bold))
                    .frame(width: 40, height: 40)
                    .background(.thinMaterial, in: Circle())
            }
        }
    }


    @ViewBuilder
    func stepInteractiveContent(
        _ step: ActivityMealActionStep
    ) -> some View {

        switch step.kind {

        case .confirmMeal:
            VStack(spacing: 16) {
                Image(systemName: "fork.knife.circle.fill")
                    .font(.system(size: 48))

                Text(suggestedMealName)
                    .font(.title3.weight(.bold))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)

                Button {
                    mealConfirmed.toggle()
                    persistDraft()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: mealConfirmed ? "checkmark.square.fill" : "square")
                            .font(.title3)
                            .foregroundStyle(mealConfirmed ? Color.green : Color.secondary)
                        Text(mealConfirmed ? "Meal confirmed" : "Confirm this suggested meal")
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Button {
                    presentedSheet = .browseMeals
                } label: {
                    Label("Browse Meals", systemImage: "magnifyingglass")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }

        case .chooseSource:
            VStack(spacing: 10) {
                ForEach(ActivityMealSource.allCases) { option in
                    Button {
                        source = option
                        rebuildForSourceChange()
                        persistDraft()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: option.systemImage)
                                .frame(width: 26)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(option.title)
                                    .fontWeight(.bold)
                                Text(option.subtitle)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.leading)
                                    .lineLimit(2)
                            }
                            Spacer()
                            if source == option {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }
                        }
                        .padding(10)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                }
            }

        case .recipe:
            VStack(spacing: 14) {
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 42))

                Text(selectedRecipe.title)
                    .font(.title3.weight(.bold))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                Text("About \(selectedRecipe.estimatedMinutes) min • \(selectedRecipe.instructions.count) steps")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack(spacing: 10) {
                    Button {
                        presentedSheet = .recipeDetails
                    } label: {
                        Label("View", systemImage: "doc.text.magnifyingglass")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    Button {
                        presentedSheet = .browseRecipes
                    } label: {
                        Label("Browse Recipes", systemImage: "books.vertical.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }

        case .ingredients:
            VStack(spacing: 14) {
                Image(systemName: "list.bullet.clipboard.fill")
                    .font(.system(size: 42))

                Text("\(ingredients.count) ingredients in the current recipe")
                    .font(.headline)
                    .multilineTextAlignment(.center)

                Button {
                    presentedSheet = .ingredients
                } label: {
                    Label("View / Edit Ingredients", systemImage: "pencil")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Toggle("I already have the ingredients", isOn: $ingredientsReady)
                    .onChange(of: ingredientsReady) { ready in
                        if ready {
                            groceriesNeeded = false
                        }
                        rebuildForSourceChange()
                    }

                Toggle("Source missing ingredients", isOn: $groceriesNeeded)
                    .disabled(ingredientsReady)
                    .onChange(of: groceriesNeeded) { _ in
                        rebuildForSourceChange()
                    }
            }

        case .shopping:
            VStack(spacing: 14) {
                Image(systemName: "cart.fill")
                    .font(.system(size: 42))

                if ingredientStoreName.isEmpty {
                    Text("Choose what you need and where to get it.")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                } else {
                    Text("Store: \(ingredientStoreName)")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                }

                Button {
                    presentedSheet = .shoppingList
                } label: {
                    Label("Shopping List", systemImage: "checklist")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button {
                    presentedSheet = .ingredientStores
                } label: {
                    Label("Relevant Stores", systemImage: "storefront.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }

        case let .recipeInstruction(index):
            if selectedRecipe.instructions.indices.contains(index) {
                let recipeStep = selectedRecipe.instructions[index]
                VStack(spacing: 14) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 38))
                        .foregroundStyle(.orange)

                    Text(recipeStep.title)
                        .font(.title3.weight(.bold))
                        .multilineTextAlignment(.center)

                    Text(recipeStep.detail)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    if let seconds = recipeStep.timerSeconds,
                       seconds > 0 {
                        MealInstructionTimerView(totalSeconds: seconds)
                    }
                }
            } else {
                Text("Recipe instruction unavailable")
                    .foregroundStyle(.secondary)
            }

        case .venue:
            VStack(spacing: 14) {
                Image(systemName: "storefront.fill")
                    .font(.system(size: 42))

                Text(venueName)
                    .font(.title3.weight(.bold))
                    .multilineTextAlignment(.center)

                if !venueLocation.isEmpty {
                    Text(venueLocation)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                Text(venueHours)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(venueAvailable ? Color.green : Color.orange)

                Button {
                    presentedSheet = .venues
                } label: {
                    Label("Browse Restaurants / Stores", systemImage: "magnifyingglass")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }

        case .availability:
            VStack(spacing: 12) {
                Image(systemName: venueAvailable ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(venueAvailable ? Color.green : Color.orange)
                Text(venueAvailable ? "Meal source is available" : "Choose another restaurant or store")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                Text(venueHours)
                    .foregroundStyle(.secondary)
            }

        case .order:
            VStack(spacing: 14) {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 10),
                        GridItem(.flexible(), spacing: 10)
                    ],
                    spacing: 10
                ) {
                    ForEach(ActivityMealFulfillmentMode.allCases) { mode in
                        Button {
                            fulfillmentMode = mode
                            persistDraft()
                        } label: {
                            VStack(spacing: 7) {
                                Image(systemName: fulfillmentSystemImage(for: mode))
                                    .font(.title3.weight(.semibold))
                                Text(mode.title)
                                    .font(.caption.weight(.bold))
                            }
                            .frame(maxWidth: .infinity, minHeight: 66)
                            .foregroundStyle(fulfillmentMode == mode ? Color.white : Color.primary)
                            .background(
                                fulfillmentMode == mode ? Color.accentColor : Color.secondary.opacity(0.10),
                                in: RoundedRectangle(cornerRadius: 14)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }

                if let url = fulfillmentURL(for: fulfillmentMode) {
                    Link(destination: url) {
                        Label(
                            fulfillmentLinkTitle(for: fulfillmentMode),
                            systemImage: "arrow.up.right.square"
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }

        case .host:
            VStack(spacing: 14) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 42))

                Text(hostName)
                    .font(.title3.weight(.bold))
                    .multilineTextAlignment(.center)

                Button {
                    presentedSheet = .friends
                } label: {
                    Label("Choose Friend / Host", systemImage: "person.2.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }

        case .invitation:
            VStack(spacing: 14) {
                Image(systemName: "envelope.open.fill")
                    .font(.system(size: 44))

                Toggle("Invitation confirmed", isOn: $invitationConfirmed)

                Text(invitationConfirmed ? "Time and location confirmed." : "Contact the host before traveling.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if selectedFriend?.chatAvailable == true {
                    Button {
                        presentedSheet = .friendChat
                    } label: {
                        Label("Chat with \(hostName)", systemImage: "message.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }

        case .contribution:
            VStack(spacing: 14) {
                Image(systemName: "gift.fill")
                    .font(.system(size: 42))

                Text(contributionItems.isEmpty ? "Nothing selected yet" : contributionItems.joined(separator: ", "))
                    .font(.subheadline.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .lineLimit(3)

                Button {
                    presentedSheet = .contributionItems
                } label: {
                    Label("View / Edit Items", systemImage: "square.and.pencil")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }

        case .travel:
            VStack(spacing: 12) {
                Image(systemName: "location.fill")
                    .font(.system(size: 42))

                TextField("Meal address", text: $eventLocation)
                    .textFieldStyle(.roundedBorder)

                if !eventLocation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    HStack(spacing: 10) {
                        if let appleURL = appleMapsURL(for: eventLocation) {
                            Link(destination: appleURL) {
                                Label("Apple Maps", systemImage: "map.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                        }

                        if let googleURL = googleMapsURL(for: eventLocation) {
                            Link(destination: googleURL) {
                                Label("Google Maps", systemImage: "map")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
            }

        case .serve:
            mealInstructionChecklist([
                "Confirm the meal is ready",
                "Plate or unwrap the meal",
                "Set drinks, sides and utensils",
                "Sit down and get ready to eat"
            ])

        case .enjoy:
            VStack(spacing: 16) {
                Image(systemName: "face.smiling.inverse")
                    .font(.system(size: 54))
                    .foregroundStyle(.green)
                Text("Enjoy \(suggestedMealName)")
                    .font(.title2.weight(.bold))
                    .multilineTextAlignment(.center)

                Button {
                    finishMeal()
                } label: {
                    Label("Done", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }


    func mealInstructionChecklist(
        _ items: [String]
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                HStack(alignment: .top, spacing: 10) {
                    Text("\(index + 1)")
                        .font(.caption.weight(.bold))
                        .frame(width: 24, height: 24)
                        .background(.thinMaterial, in: Circle())
                    Text(item)
                        .font(.subheadline)
                    Spacer()
                }
            }
        }
    }


    var actionControls: some View {
        Button {
            skipCurrentStepForward()
        } label: {
            Label("Skip Step", systemImage: "forward.end.fill")
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
        }
        .buttonStyle(.bordered)
        .disabled(currentStep.kind == .enjoy)
    }


    var actionPagingGesture: some Gesture {

        DragGesture(minimumDistance: 38)
            .onEnded { value in
                // Finger moves upward to scroll down/forward. Pass 5.28
                // treats that forward gesture as completion of the current
                // step. Explicit skipping is now only done with Skip Step.
                if value.translation.height < -70 {
                    completeCurrentStep()
                } else if value.translation.height > 70 {
                    moveBackward()
                }
            }
    }
}


// =====================================================
// MARK: - Action Steps
// =====================================================

private extension ActivityMealExperienceView {

    var actionSteps: [ActivityMealActionStep] {

        var steps: [ActivityMealActionStep] = [
            step(
                "confirm-meal",
                title: "Confirm your meal",
                eyebrow: "Meal",
                instruction: "Confirm the suggested meal or browse for another meal before continuing.",
                icon: "fork.knife.circle.fill",
                kind: .confirmMeal,
                minutes: 1
            ),
            step(
                "choose-source",
                title: "Choose the meal source",
                eyebrow: "Source",
                instruction: "The remaining steps change based on how this meal will be sourced.",
                icon: source.systemImage,
                kind: .chooseSource,
                minutes: 1
            )
        ]

        switch source {
        case .homeMade:
            steps += homeMadeSteps
        case .restaurantOrStore:
            steps += restaurantStoreSteps
        case .invited:
            steps += invitedSteps
        }

        steps.append(
            step(
                "enjoy",
                title: "Enjoy the meal",
                eyebrow: "Finish",
                instruction: "When you are actually eating the meal, tap Done to complete the ActivityMeal.",
                icon: "face.smiling.inverse",
                kind: .enjoy,
                minutes: mealContent?.meal?.estimatedTimeMinutes
            )
        )

        return steps
    }


    var homeMadeSteps: [ActivityMealActionStep] {
        var result: [ActivityMealActionStep] = [
            step(
                "recipe",
                title: "Choose a recipe",
                eyebrow: "Home-made",
                instruction: "Review the selected recipe or browse for another one.",
                icon: "book.closed.fill",
                kind: .recipe,
                minutes: 2
            ),
            step(
                "ingredients",
                title: "Check ingredients",
                eyebrow: "Home-made",
                instruction: "Review and edit the ingredient list, then decide whether anything still needs to be sourced.",
                icon: "list.bullet.clipboard.fill",
                kind: .ingredients,
                minutes: 3
            )
        ]

        if groceriesNeeded && !ingredientsReady {
            result.append(
                step(
                    "shopping",
                    title: "Source ingredients",
                    eyebrow: "Home-made",
                    instruction: "Manage your shopping list and choose a relevant store for the missing ingredients.",
                    icon: "cart.fill",
                    kind: .shopping,
                    minutes: 20
                )
            )
        }

        for (index, instruction) in selectedRecipe.instructions.enumerated() {
            result.append(
                step(
                    "recipe-instruction-\(index)-\(instruction.id)",
                    title: instruction.title,
                    eyebrow: "Recipe Step \(index + 1)",
                    instruction: instruction.detail,
                    icon: instruction.timerSeconds == nil ? "fork.knife" : "timer",
                    kind: .recipeInstruction(index),
                    minutes: instruction.timerSeconds.map { max(1, Int(ceil(Double($0) / 60.0))) },
                    timerSeconds: instruction.timerSeconds
                )
            )
        }

        result.append(
            step(
                "serve-home",
                title: "Plate and serve",
                eyebrow: "Home-made",
                instruction: "Finish the recipe, plate the meal and get ready to eat.",
                icon: "circle.grid.2x2.fill",
                kind: .serve,
                minutes: 3
            )
        )

        return result
    }


    var restaurantStoreSteps: [ActivityMealActionStep] {
        [
            step(
                "venue",
                title: "Choose restaurant or store",
                eyebrow: "Restaurant / Store",
                instruction: "Browse restaurants or stores and select the place that will provide the meal.",
                icon: "storefront.fill",
                kind: .venue,
                minutes: 2
            ),
            step(
                "availability",
                title: "Confirm availability",
                eyebrow: "Restaurant / Store",
                instruction: "Check whether the selected place is open and whether the meal is available.",
                icon: "clock.badge.checkmark",
                kind: .availability,
                minutes: 1
            ),
            step(
                "order",
                title: "Choose how to get it",
                eyebrow: "Fulfillment",
                instruction: "Choose dine in, takeout, delivery or store pickup, then use the relevant fulfillment link.",
                icon: "bag.fill",
                kind: .order,
                minutes: 3
            ),
            step(
                "serve-restaurant",
                title: "Get ready to eat",
                eyebrow: "Serve",
                instruction: "Receive, unwrap or plate the meal and prepare to eat.",
                icon: "fork.knife",
                kind: .serve,
                minutes: 2
            )
        ]
    }


    var invitedSteps: [ActivityMealActionStep] {
        [
            step(
                "host",
                title: "Confirm host or event",
                eyebrow: "Hosted",
                instruction: "Choose the friend or host responsible for the meal.",
                icon: "person.2.fill",
                kind: .host,
                minutes: 2
            ),
            step(
                "invitation",
                title: "Confirm the invitation",
                eyebrow: "Hosted",
                instruction: "Confirm the invitation and chat with the host when a conversation is available.",
                icon: "envelope.open.fill",
                kind: .invitation,
                minutes: 2
            ),
            step(
                "contribution",
                title: "What should you bring?",
                eyebrow: "Hosted",
                instruction: "Review and edit anything you are expected to bring.",
                icon: "gift.fill",
                kind: .contribution,
                minutes: 3
            ),
            step(
                "travel-host",
                title: "Travel to the meal",
                eyebrow: "Hosted",
                instruction: "Add or edit the meal address, then open directions when you are ready to travel.",
                icon: "location.fill",
                kind: .travel,
                minutes: 15
            ),
            step(
                "serve-host",
                title: "Join the table",
                eyebrow: "Hosted",
                instruction: "The host manages most preparation. Help if asked, then get ready to eat.",
                icon: "person.3.fill",
                kind: .serve,
                minutes: 3
            )
        ]
    }


    func step(
        _ id: String,
        title: String,
        eyebrow: String,
        instruction: String,
        icon: String,
        kind: ActivityMealActionStep.Kind,
        minutes: Int?,
        timerSeconds: Int? = nil
    ) -> ActivityMealActionStep {
        ActivityMealActionStep(
            id: id,
            title: title,
            eyebrow: eyebrow,
            instruction: instruction,
            systemImage: icon,
            kind: kind,
            estimatedMinutes: minutes,
            timerSeconds: timerSeconds
        )
    }


    var currentStep: ActivityMealActionStep {
        let safeIndex = min(max(0, currentStepIndex), max(0, actionSteps.count - 1))
        return actionSteps[safeIndex]
    }
}


// =====================================================
// MARK: - Progression
// =====================================================

private extension ActivityMealExperienceView {

    func completeCurrentStep() {
        completedStepIDs.insert(currentStep.id)
        skippedStepIDs.remove(currentStep.id)

        if currentStep.kind == .enjoy || currentStepIndex >= actionSteps.count - 1 {
            finishMeal()
            return
        }

        withAnimation(.snappy(duration: 0.28)) {
            currentStepIndex += 1
        }
        persistDraft()
    }


    func skipCurrentStepForward() {
        guard currentStepIndex < actionSteps.count - 1 else { return }

        if !completedStepIDs.contains(currentStep.id) {
            skippedStepIDs.insert(currentStep.id)
        }

        withAnimation(.snappy(duration: 0.26)) {
            currentStepIndex += 1
        }
        persistDraft()
    }


    func moveBackward() {
        guard currentStepIndex > 0 else {
            withAnimation(.snappy(duration: 0.24)) {
                experienceState = .welcome
            }
            return
        }

        withAnimation(.snappy(duration: 0.26)) {
            currentStepIndex -= 1
        }
        persistDraft()
    }


    func rebuildForSourceChange() {
        let maxIndex = max(0, actionSteps.count - 1)
        currentStepIndex = min(currentStepIndex, maxIndex)
    }
}


// =====================================================
// MARK: - Draft + Completion
// =====================================================

private extension ActivityMealExperienceView {

    var mealContent: ActivityNodeContent? {
        guard case let .activity(content) = draft.content,
              content.resolvedActivityType == .meal else {
            return nil
        }
        return content
    }


    var activityTitle: String {
        mealContent?.title.isEmpty == false
            ? (mealContent?.title ?? "Meal")
            : "Meal"
    }


    var startTimeBinding: Binding<String> {
        Binding(
            get: { mealContent?.startTime ?? "" },
            set: { newValue in
                updateMealContent { $0.startTime = newValue }
            }
        )
    }


    var endTimeBinding: Binding<String> {
        Binding(
            get: { mealContent?.endTime ?? "" },
            set: { newValue in
                updateMealContent { $0.endTime = newValue }
            }
        )
    }


    func updateMealContent(
        _ mutation: (inout ActivityNodeContent) -> Void
    ) {
        guard case var .activity(content) = draft.content else { return }
        mutation(&content)
        draft.content = .activity(content)
    }


    func persistDraft() {
        updateMealContent { content in
            if var meal = content.meal {
                meal.title = suggestedMealName
                meal.executionPlan = currentExecutionPlan
                content.meal = meal
            }
        }
        synchronizeNodeTimeFromStartTime()
        onUpdate(draft)
    }


    func finishMeal() {
        updateMealContent { content in
            content.status = "Completed"
            if var meal = content.meal {
                meal.title = suggestedMealName
                meal.executionPlan = currentExecutionPlan
                content.meal = meal
            }
        }
        synchronizeNodeTimeFromStartTime()
        onCompleted(draft)
        dismiss()
    }


    var currentExecutionPlan: ActivityMealExecutionPlanNodeSummary {
        ActivityMealExecutionPlanNodeSummary(
            selectedMealName: suggestedMealName,
            source: source.rawValue,
            currentStepID: currentStep.id,
            completedStepIDs: Array(completedStepIDs).sorted(),
            skippedStepIDs: Array(skippedStepIDs).sorted(),
            isPaused: false,
            recipeName: selectedRecipe.title,
            ingredientsReady: ingredientsReady,
            groceriesNeeded: groceriesNeeded,
            venueName: venueName,
            venueLocation: venueLocation,
            venueHours: venueHours,
            venueAvailable: venueAvailable,
            fulfillmentMode: fulfillmentMode.rawValue,
            hostName: hostName,
            eventLocation: eventLocation,
            invitationConfirmed: invitationConfirmed,
            contribution: contributionItems.joined(separator: ", "),
            mealConfirmed: mealConfirmed,
            ingredients: ingredients,
            shoppingList: shoppingList,
            ingredientStoreName: ingredientStoreName,
            selectedHostID: selectedHostID,
            contributionItems: contributionItems
        )
    }


    func restorePersistedStepIfNeeded() {
        guard let stepID = pendingRestoredStepID,
              let index = actionSteps.firstIndex(where: { $0.id == stepID }) else {
            pendingRestoredStepID = nil
            return
        }

        currentStepIndex = index
        pendingRestoredStepID = nil
    }


    func synchronizeNodeTimeFromStartTime() {
        guard let startTime = parseActivityTime(startTimeBinding.wrappedValue) else {
            return
        }

        switch draft.placement {
        case let .roadVertex(vertexID):
            if let vertex = roadGraph.vertex(id: vertexID) {
                draft.setPlacement(
                    .coordinate(
                        MapCoordinate(
                            time: startTime,
                            progress: vertex.coordinate.progress
                        )
                    )
                )
            } else {
                draft.setTime(startTime)
            }

        case .coordinate:
            draft.setTime(startTime)
        }
    }


    func parseActivityTime(_ value: String) -> DayTime? {
        let cleaned = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return nil }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)

        for format in ["h:mm a", "hh:mm a", "h:mm:ss a", "hh:mm:ss a", "H:mm", "HH:mm", "H:mm:ss", "HH:mm:ss"] {
            formatter.dateFormat = format
            guard let date = formatter.date(from: cleaned) else { continue }

            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = formatter.timeZone
            let components = calendar.dateComponents([.hour, .minute, .second], from: date)

            return DayTime(
                secondsFromMidnight: TimeInterval(
                    (components.hour ?? 0) * 3600
                    + (components.minute ?? 0) * 60
                    + (components.second ?? 0)
                )
            )
        }

        return nil
    }


    var recipeSummaryText: String {
        let count = mealContent?.meal?.meals?.first?.recipeCount ?? 0
        let duration = mealContent?.meal?.estimatedTimeMinutes ?? 0
        if count > 0 {
            return "\(count) recipe option\(count == 1 ? "" : "s") available • estimated meal time \(duration) min"
        }
        return duration > 0
            ? "Estimated meal time: \(duration) min"
            : "Review the recipe before starting."
    }


    var ingredientSummaryText: String {
        let count = mealContent?.meal?.meals?.first?.ingredientCount ?? 0
        return count > 0
            ? "This meal currently references \(count) ingredient\(count == 1 ? "" : "s")."
            : "Review the recipe and confirm every required ingredient."
    }


    var fulfillmentSystemImage: String {
        switch fulfillmentMode {
        case .dineIn: return "fork.knife"
        case .takeout: return "takeoutbag.and.cup.and.straw.fill"
        case .delivery: return "location.fill"
        case .storePickup: return "cart.fill"
        }
    }


    var fulfillmentDetail: String {
        switch fulfillmentMode {
        case .dineIn:
            return "Travel to \(venueName), arrive while it is open, order the meal, and eat there."
        case .takeout:
            return "Order ahead, travel to \(venueName), pick up the meal, then take it to where you plan to eat."
        case .delivery:
            return "Place the delivery order, track it, receive the meal, then prepare to eat."
        case .storePickup:
            return "Reserve or buy the ready-made meal at \(venueName), pick it up, then bring it to where you plan to eat."
        }
    }


    var travelDestination: String {
        source == .invited
            ? (eventLocation.isEmpty ? hostName : eventLocation)
            : (venueLocation.isEmpty ? venueName : venueLocation)
    }
}


// =====================================================
// MARK: - Action Data + Sheets
// =====================================================

private extension ActivityMealExperienceView {

    var mealBrowseChoices: [ActivityMealBrowseChoice] {
        var values: [ActivityMealBrowseChoice] = []

        for meal in mealContent?.meal?.meals ?? [] {
            values.append(
                ActivityMealBrowseChoice(
                    id: meal.mealID,
                    title: meal.title,
                    subtitle: meal.estimatedTimeMinutes > 0
                        ? "About \(meal.estimatedTimeMinutes) min • \(meal.priceRange ?? "")"
                        : "Suggested meal",
                    imageURL: meal.imageURL
                )
            )
        }

        let fallbackNames = [
            suggestedMealName,
            "Cheeseburger",
            "Chicken Burrito Bowl",
            "Grilled Chicken Salad",
            "Pasta Primavera",
            "Breakfast Sandwich"
        ]

        for name in fallbackNames where !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            guard !values.contains(where: { $0.title.caseInsensitiveCompare(name) == .orderedSame }) else {
                continue
            }
            values.append(
                ActivityMealBrowseChoice(
                    id: "fallback-\(slug(name))",
                    title: name,
                    subtitle: "Suggested for this meal window",
                    imageURL: nil
                )
            )
        }

        return values
    }


    var recipeOptions: [ActivityMealRecipeOption] {
        makeRecipeOptions(for: suggestedMealName)
    }


    var selectedRecipe: ActivityMealRecipeOption {
        recipeOptions.first(where: { $0.title == recipeName })
            ?? recipeOptions[0]
    }


    func makeRecipeOptions(
        for mealName: String
    ) -> [ActivityMealRecipeOption] {

        let meal = mealName.isEmpty ? "Meal" : mealName

        return [
            ActivityMealRecipeOption(
                id: "classic-\(slug(meal))",
                title: "Classic \(meal)",
                subtitle: "Balanced standard method",
                estimatedMinutes: 30,
                ingredients: [
                    "Main ingredients for \(meal)",
                    "Salt and pepper",
                    "Cooking oil or butter",
                    "Fresh garnish or finishing ingredient"
                ],
                instructions: [
                    ActivityMealRecipeInstruction(
                        id: "organize",
                        title: "Organize the ingredients",
                        detail: "Measure the recipe ingredients and arrange them in the order they will be used.",
                        timerSeconds: nil
                    ),
                    ActivityMealRecipeInstruction(
                        id: "preheat",
                        title: "Preheat the cooking surface",
                        detail: "Bring the pan, oven or grill to the recipe temperature before cooking.",
                        timerSeconds: 300
                    ),
                    ActivityMealRecipeInstruction(
                        id: "cook-main",
                        title: "Cook the main components",
                        detail: "Cook the primary ingredients until they reach the recipe's target doneness.",
                        timerSeconds: 480
                    ),
                    ActivityMealRecipeInstruction(
                        id: "assemble",
                        title: "Assemble the meal",
                        detail: "Combine the cooked components, sauces and toppings in the recipe order.",
                        timerSeconds: nil
                    ),
                    ActivityMealRecipeInstruction(
                        id: "rest",
                        title: "Rest and finish",
                        detail: "Let the meal rest briefly, then add final seasoning or garnish.",
                        timerSeconds: 120
                    )
                ]
            ),
            ActivityMealRecipeOption(
                id: "quick-\(slug(meal))",
                title: "Quick \(meal)",
                subtitle: "Fewer steps for a faster meal",
                estimatedMinutes: 18,
                ingredients: [
                    "Quick-prep ingredients for \(meal)",
                    "Seasoning blend",
                    "Cooking oil",
                    "Ready-to-use sauce or topping"
                ],
                instructions: [
                    ActivityMealRecipeInstruction(
                        id: "quick-combine",
                        title: "Combine the ingredients",
                        detail: "Gather the quick-prep ingredients and combine anything that can be prepared together.",
                        timerSeconds: nil
                    ),
                    ActivityMealRecipeInstruction(
                        id: "quick-cook",
                        title: "Cook",
                        detail: "Cook over the recommended heat, turning or stirring as needed.",
                        timerSeconds: 600
                    ),
                    ActivityMealRecipeInstruction(
                        id: "quick-finish",
                        title: "Finish and serve",
                        detail: "Add the sauce or topping, check seasoning and plate immediately.",
                        timerSeconds: nil
                    )
                ]
            ),
            ActivityMealRecipeOption(
                id: "oven-\(slug(meal))",
                title: "Oven \(meal)",
                subtitle: "Hands-off oven-forward method",
                estimatedMinutes: 40,
                ingredients: [
                    "Oven-ready ingredients for \(meal)",
                    "Seasoning",
                    "Oil or butter",
                    "Finishing garnish"
                ],
                instructions: [
                    ActivityMealRecipeInstruction(
                        id: "oven-preheat",
                        title: "Preheat the oven",
                        detail: "Preheat the oven and prepare the baking tray or dish.",
                        timerSeconds: 600
                    ),
                    ActivityMealRecipeInstruction(
                        id: "oven-arrange",
                        title: "Arrange the meal",
                        detail: "Season and arrange the ingredients in the baking dish in a single even layer.",
                        timerSeconds: nil
                    ),
                    ActivityMealRecipeInstruction(
                        id: "oven-bake",
                        title: "Bake",
                        detail: "Bake until the meal is cooked through and browned as desired.",
                        timerSeconds: 1200
                    ),
                    ActivityMealRecipeInstruction(
                        id: "oven-rest",
                        title: "Rest",
                        detail: "Remove from the oven and rest before serving.",
                        timerSeconds: 180
                    )
                ]
            )
        ]
    }


    var ingredientStores: [ActivityMealStoreOption] {
        [
            ActivityMealStoreOption(
                id: "whole-foods",
                name: "Whole Foods Market",
                address: "Nearby location",
                distanceMiles: 1.2,
                hours: "Open until 10:00 PM",
                isOpen: true
            ),
            ActivityMealStoreOption(
                id: "safeway",
                name: "Safeway",
                address: "Nearby location",
                distanceMiles: 2.0,
                hours: "Open until 11:00 PM",
                isOpen: true
            ),
            ActivityMealStoreOption(
                id: "trader-joes",
                name: "Trader Joe's",
                address: "Nearby location",
                distanceMiles: 2.6,
                hours: "Open until 9:00 PM",
                isOpen: true
            ),
            ActivityMealStoreOption(
                id: "target-grocery",
                name: "Target Grocery",
                address: "Nearby location",
                distanceMiles: 3.4,
                hours: "Closed",
                isOpen: false
            )
        ]
    }


    var venueOptions: [ActivityMealVenueOption] {
        [
            ActivityMealVenueOption(
                id: "burger-king",
                name: "Burger King",
                address: "Nearest Burger King",
                distanceMiles: 1.1,
                hours: "Open until 11:00 PM",
                isOpen: true,
                isStore: false
            ),
            ActivityMealVenueOption(
                id: "shake-shack",
                name: "Shake Shack",
                address: "Nearest Shake Shack",
                distanceMiles: 2.4,
                hours: "Open until 10:00 PM",
                isOpen: true,
                isStore: false
            ),
            ActivityMealVenueOption(
                id: "whole-foods-ready",
                name: "Whole Foods Prepared Foods",
                address: "Nearest Whole Foods Market",
                distanceMiles: 1.2,
                hours: "Open until 10:00 PM",
                isOpen: true,
                isStore: true
            ),
            ActivityMealVenueOption(
                id: "target-ready",
                name: "Target Grocery",
                address: "Nearest Target",
                distanceMiles: 3.4,
                hours: "Open until 10:00 PM",
                isOpen: true,
                isStore: true
            )
        ]
    }


    var friendOptions: [ActivityMealFriendOption] {
        [
            ActivityMealFriendOption(
                id: "friend-alex",
                name: "Alex",
                subtitle: "Friend • chat available",
                chatAvailable: true
            ),
            ActivityMealFriendOption(
                id: "friend-jordan",
                name: "Jordan",
                subtitle: "Friend • chat available",
                chatAvailable: true
            ),
            ActivityMealFriendOption(
                id: "friend-taylor",
                name: "Taylor",
                subtitle: "Friend",
                chatAvailable: false
            )
        ]
    }


    var selectedFriend: ActivityMealFriendOption? {
        if let selectedHostID,
           let friend = friendOptions.first(where: { $0.id == selectedHostID }) {
            return friend
        }
        return friendOptions.first(where: { $0.name == hostName })
    }


    func selectMeal(
        _ meal: ActivityMealBrowseChoice
    ) {
        suggestedMealName = meal.title
        mealConfirmed = true

        let firstRecipe = makeRecipeOptions(for: meal.title)[0]
        recipeName = firstRecipe.title
        ingredients = firstRecipe.ingredients
        shoppingList = firstRecipe.ingredients
        completedStepIDs.remove("confirm-meal")
        rebuildForSourceChange()
        persistDraft()
    }


    func selectRecipe(
        _ recipe: ActivityMealRecipeOption
    ) {
        recipeName = recipe.title
        ingredients = recipe.ingredients
        shoppingList = recipe.ingredients
        rebuildForSourceChange()
        persistDraft()
    }


    func selectIngredientStore(
        _ store: ActivityMealStoreOption
    ) {
        ingredientStoreName = store.name
        persistDraft()
    }


    func selectVenue(
        _ venue: ActivityMealVenueOption
    ) {
        venueName = venue.name
        venueLocation = venue.address
        venueHours = venue.hours
        venueAvailable = venue.isOpen
        persistDraft()
    }


    func selectFriend(
        _ friend: ActivityMealFriendOption
    ) {
        selectedHostID = friend.id
        hostName = friend.name
        persistDraft()
    }


    @ViewBuilder
    func actionSheetContent(
        _ sheet: ActivityMealPresentedSheet
    ) -> some View {
        switch sheet {
        case .browseMeals:
            MealBrowserSheet(
                meals: mealBrowseChoices,
                onSelect: { meal in
                    selectMeal(meal)
                    presentedSheet = nil
                }
            )

        case .recipeDetails:
            MealRecipeDetailsSheet(recipe: selectedRecipe)

        case .browseRecipes:
            MealRecipeBrowserSheet(
                recipes: recipeOptions,
                selectedRecipeID: selectedRecipe.id,
                onSelect: { recipe in
                    selectRecipe(recipe)
                    presentedSheet = nil
                }
            )

        case .ingredients:
            EditableMealListSheet(
                title: "Ingredients",
                subtitle: selectedRecipe.title,
                addPlaceholder: "Add ingredient",
                items: $ingredients
            )
            .onDisappear {
                persistDraft()
            }

        case .shoppingList:
            EditableMealListSheet(
                title: "Shopping List",
                subtitle: ingredientStoreName.isEmpty ? "Missing ingredients" : ingredientStoreName,
                addPlaceholder: "Add shopping item",
                items: $shoppingList
            )
            .onDisappear {
                persistDraft()
            }

        case .ingredientStores:
            MealStoreBrowserSheet(
                stores: ingredientStores,
                selectedName: ingredientStoreName,
                onSelect: { store in
                    selectIngredientStore(store)
                    presentedSheet = nil
                }
            )

        case .venues:
            MealVenueBrowserSheet(
                venues: venueOptions,
                selectedName: venueName,
                onSelect: { venue in
                    selectVenue(venue)
                    presentedSheet = nil
                }
            )

        case .friends:
            MealFriendBrowserSheet(
                friends: friendOptions,
                selectedID: selectedHostID,
                onSelect: { friend in
                    selectFriend(friend)
                    presentedSheet = nil
                }
            )

        case .friendChat:
            NavigationStack {
                ChatsView()
                    .navigationTitle("Chat with \(hostName)")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") {
                                presentedSheet = nil
                            }
                        }
                    }
            }

        case .contributionItems:
            EditableMealListSheet(
                title: "What should you bring?",
                subtitle: hostName,
                addPlaceholder: "Add item",
                items: $contributionItems
            )
            .onDisappear {
                contribution = contributionItems.joined(separator: ", ")
                persistDraft()
            }
        }
    }


    func fulfillmentSystemImage(
        for mode: ActivityMealFulfillmentMode
    ) -> String {
        switch mode {
        case .dineIn: return "fork.knife"
        case .takeout: return "takeoutbag.and.cup.and.straw.fill"
        case .delivery: return "car.side.fill"
        case .storePickup: return "cart.fill"
        }
    }


    func fulfillmentLinkTitle(
        for mode: ActivityMealFulfillmentMode
    ) -> String {
        switch mode {
        case .delivery:
            return "Open DoorDash"
        case .dineIn:
            return "View Restaurant Details"
        case .takeout:
            return "View Takeout Location"
        case .storePickup:
            return "View Store Details"
        }
    }


    func fulfillmentURL(
        for mode: ActivityMealFulfillmentMode
    ) -> URL? {
        switch mode {
        case .delivery:
            let query = urlEncoded("\(venueName) \(suggestedMealName)")
            return URL(string: "https://www.doordash.com/search/store/\(query)")
        case .dineIn, .takeout, .storePickup:
            return appleMapsURL(for: venueLocation.isEmpty ? venueName : venueLocation)
        }
    }


    func appleMapsURL(
        for address: String
    ) -> URL? {
        let query = urlEncoded(address)
        guard !query.isEmpty else { return nil }
        return URL(string: "https://maps.apple.com/?q=\(query)")
    }


    func googleMapsURL(
        for address: String
    ) -> URL? {
        let query = urlEncoded(address)
        guard !query.isEmpty else { return nil }
        return URL(string: "https://www.google.com/maps/search/?api=1&query=\(query)")
    }


    func urlEncoded(
        _ value: String
    ) -> String {
        value.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
    }


    func slug(
        _ value: String
    ) -> String {
        value
            .lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .filter { $0.isLetter || $0.isNumber || $0 == "-" }
    }
}


// =====================================================
// MARK: - Reference-inspired Stacked Card Deck
// =====================================================

private struct MealActionStackDeck<Content: View>: View {

    let step: ActivityMealActionStep
    let accentIndex: Int
    let deckHeight: CGFloat
    let content: Content

    init(
        step: ActivityMealActionStep,
        accentIndex: Int,
        deckHeight: CGFloat = 330,
        @ViewBuilder content: () -> Content
    ) {
        self.step = step
        self.accentIndex = accentIndex
        self.deckHeight = deckHeight
        self.content = content()
    }

    var body: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.orange.opacity(0.50))
                .frame(height: max(240, deckHeight - 30))
                .offset(y: -36)
                .padding(.horizontal, 32)

            RoundedRectangle(cornerRadius: 24)
                .fill(Color.cyan.opacity(0.50))
                .frame(height: max(240, deckHeight - 30))
                .offset(y: -24)
                .padding(.horizontal, 20)

            RoundedRectangle(cornerRadius: 24)
                .fill(Color.purple.opacity(0.40))
                .frame(height: max(240, deckHeight - 30))
                .offset(y: -12)
                .padding(.horizontal, 10)

            VStack(spacing: 18) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(step.eyebrow.uppercased())
                            .font(.caption2.weight(.bold))
                            .tracking(1)
                            .foregroundStyle(.secondary)
                        Text(step.title)
                            .font(.title3.weight(.bold))
                    }
                    Spacer()
                    Image(systemName: step.systemImage)
                        .font(.title2.weight(.bold))
                }

                Divider()

                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(22)
            .frame(maxWidth: .infinity)
            .frame(height: deckHeight)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 26))
            .overlay {
                RoundedRectangle(cornerRadius: 26)
                    .stroke(.primary.opacity(0.08), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.12), radius: 18, y: 8)
        }
        .padding(.top, 38)
    }
}


// =====================================================
// MARK: - Action Support Sheets
// =====================================================

private struct MealBrowserSheet: View {

    let meals: [ActivityMealBrowseChoice]
    let onSelect: (ActivityMealBrowseChoice) -> Void

    @State private var searchText = ""
    @Environment(\.dismiss) private var dismiss

    private var filteredMeals: [ActivityMealBrowseChoice] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return meals }
        return meals.filter {
            $0.title.localizedCaseInsensitiveContains(query)
            || $0.subtitle.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        NavigationStack {
            List(filteredMeals) { meal in
                Button {
                    onSelect(meal)
                } label: {
                    HStack(spacing: 14) {
                        MealBrowseThumbnail(urlString: meal.imageURL)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(meal.title)
                                .font(.headline)
                            Text(meal.subtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            }
            .searchable(text: $searchText, prompt: "Search meals")
            .navigationTitle("Browse Meals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}


private struct MealBrowseThumbnail: View {

    let urlString: String?

    var body: some View {
        Group {
            if let urlString,
               let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case let .success(image):
                        image.resizable().scaledToFill()
                    case .empty:
                        ProgressView()
                    case .failure:
                        placeholder
                    @unknown default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .frame(width: 54, height: 54)
        .background(.secondary.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var placeholder: some View {
        Image(systemName: "fork.knife")
            .font(.title3)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}


private struct MealRecipeDetailsSheet: View {

    let recipe: ActivityMealRecipeOption
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(recipe.title)
                            .font(.largeTitle.bold())
                        Text(recipe.subtitle)
                            .foregroundStyle(.secondary)
                        Label(
                            "About \(recipe.estimatedMinutes) minutes",
                            systemImage: "clock"
                        )
                        .font(.subheadline.weight(.semibold))
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Ingredients")
                            .font(.title2.bold())
                        ForEach(recipe.ingredients, id: \.self) { ingredient in
                            Label(ingredient, systemImage: "circle.fill")
                                .font(.subheadline)
                        }
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        Text("Instructions")
                            .font(.title2.bold())

                        ForEach(Array(recipe.instructions.enumerated()), id: \.element.id) { index, instruction in
                            HStack(alignment: .top, spacing: 12) {
                                Text("\(index + 1)")
                                    .font(.caption.bold())
                                    .frame(width: 28, height: 28)
                                    .background(.thinMaterial, in: Circle())

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(instruction.title)
                                        .font(.headline)
                                    Text(instruction.detail)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    if let seconds = instruction.timerSeconds {
                                        Label(
                                            durationText(seconds),
                                            systemImage: "timer"
                                        )
                                        .font(.caption.weight(.semibold))
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(20)
            }
            .navigationTitle("Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func durationText(
        _ seconds: Int
    ) -> String {
        let minutes = seconds / 60
        let remainder = seconds % 60
        return remainder == 0
            ? "\(minutes) min"
            : "\(minutes)m \(remainder)s"
    }
}


private struct MealRecipeBrowserSheet: View {

    let recipes: [ActivityMealRecipeOption]
    let selectedRecipeID: String
    let onSelect: (ActivityMealRecipeOption) -> Void

    @State private var searchText = ""
    @Environment(\.dismiss) private var dismiss

    private var filteredRecipes: [ActivityMealRecipeOption] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return recipes }
        return recipes.filter {
            $0.title.localizedCaseInsensitiveContains(query)
            || $0.subtitle.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        NavigationStack {
            List(filteredRecipes) { recipe in
                Button {
                    onSelect(recipe)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "book.closed.fill")
                            .font(.title3)
                            .frame(width: 38, height: 38)
                            .background(.secondary.opacity(0.10), in: RoundedRectangle(cornerRadius: 10))

                        VStack(alignment: .leading, spacing: 4) {
                            Text(recipe.title)
                                .font(.headline)
                            Text(recipe.subtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(recipe.estimatedMinutes) min • \(recipe.instructions.count) steps")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                        if selectedRecipeID == recipe.id {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            }
            .searchable(text: $searchText, prompt: "Search recipes")
            .navigationTitle("Browse Recipes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}


private struct EditableMealListSheet: View {

    let title: String
    let subtitle: String
    let addPlaceholder: String
    @Binding var items: [String]

    @State private var newItem = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if !subtitle.isEmpty {
                    Section {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Items") {
                    ForEach(items.indices, id: \.self) { index in
                        HStack(spacing: 8) {
                            TextField("Item", text: $items[index])
                            Button(role: .destructive) {
                                guard items.indices.contains(index) else { return }
                                items.remove(at: index)
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                    .onDelete { offsets in
                        items.remove(atOffsets: offsets)
                    }
                }

                Section("Add") {
                    HStack {
                        TextField(addPlaceholder, text: $newItem)
                            .submitLabel(.done)
                            .onSubmit(addNewItem)
                        Button("Add") {
                            addNewItem()
                        }
                        .disabled(newItem.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func addNewItem() {
        let value = newItem.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return }
        items.append(value)
        newItem = ""
    }
}


private struct MealStoreBrowserSheet: View {

    let stores: [ActivityMealStoreOption]
    let selectedName: String
    let onSelect: (ActivityMealStoreOption) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(stores) { store in
                Button {
                    onSelect(store)
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "storefront.fill")
                            .font(.title3)
                            .frame(width: 38, height: 38)
                            .background(.secondary.opacity(0.10), in: RoundedRectangle(cornerRadius: 10))

                        VStack(alignment: .leading, spacing: 4) {
                            Text(store.name)
                                .font(.headline)
                            Text(store.address)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            HStack(spacing: 8) {
                                Text(String(format: "%.1f mi", store.distanceMiles))
                                Text(store.isOpen ? "Open" : "Closed")
                                    .foregroundStyle(store.isOpen ? Color.green : Color.red)
                                Text(store.hours)
                            }
                            .font(.caption2.weight(.semibold))
                        }

                        Spacer()
                        if selectedName == store.name {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                    }
                    .padding(.vertical, 5)
                }
                .buttonStyle(.plain)
            }
            .navigationTitle("Relevant Stores")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}


private struct MealVenueBrowserSheet: View {

    let venues: [ActivityMealVenueOption]
    let selectedName: String
    let onSelect: (ActivityMealVenueOption) -> Void

    @State private var searchText = ""
    @Environment(\.dismiss) private var dismiss

    private var filteredVenues: [ActivityMealVenueOption] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return venues }
        return venues.filter {
            $0.name.localizedCaseInsensitiveContains(query)
            || $0.address.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        NavigationStack {
            List(filteredVenues) { venue in
                Button {
                    onSelect(venue)
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: venue.isStore ? "cart.fill" : "fork.knife")
                            .font(.title3)
                            .frame(width: 38, height: 38)
                            .background(.secondary.opacity(0.10), in: RoundedRectangle(cornerRadius: 10))

                        VStack(alignment: .leading, spacing: 4) {
                            Text(venue.name)
                                .font(.headline)
                            Text(venue.address)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            HStack(spacing: 8) {
                                Text(String(format: "%.1f mi", venue.distanceMiles))
                                Text(venue.isOpen ? "Open" : "Closed")
                                    .foregroundStyle(venue.isOpen ? Color.green : Color.red)
                                Text(venue.hours)
                            }
                            .font(.caption2.weight(.semibold))
                        }

                        Spacer()
                        if selectedName == venue.name {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                    }
                    .padding(.vertical, 5)
                }
                .buttonStyle(.plain)
            }
            .searchable(text: $searchText, prompt: "Search restaurants and stores")
            .navigationTitle("Restaurants & Stores")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}


private struct MealFriendBrowserSheet: View {

    let friends: [ActivityMealFriendOption]
    let selectedID: String?
    let onSelect: (ActivityMealFriendOption) -> Void

    @State private var searchText = ""
    @Environment(\.dismiss) private var dismiss

    private var filteredFriends: [ActivityMealFriendOption] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return friends }
        return friends.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        NavigationStack {
            List(filteredFriends) { friend in
                Button {
                    onSelect(friend)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 38))
                        VStack(alignment: .leading, spacing: 3) {
                            Text(friend.name)
                                .font(.headline)
                            Text(friend.subtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if selectedID == friend.id {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                    }
                    .padding(.vertical, 3)
                }
                .buttonStyle(.plain)
            }
            .searchable(text: $searchText, prompt: "Search friends")
            .navigationTitle("Friends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}


private struct MealInstructionTimerView: View {

    let totalSeconds: Int

    @State private var remainingSeconds: Int
    @State private var isRunning = false

    init(totalSeconds: Int) {
        self.totalSeconds = max(1, totalSeconds)
        _remainingSeconds = State(initialValue: max(1, totalSeconds))
    }

    var body: some View {
        VStack(spacing: 10) {
            Text(timerText)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .monospacedDigit()

            HStack(spacing: 10) {
                Button {
                    isRunning.toggle()
                } label: {
                    Label(isRunning ? "Pause Timer" : "Start Timer", systemImage: isRunning ? "pause.fill" : "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button {
                    isRunning = false
                    remainingSeconds = totalSeconds
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .frame(width: 42)
                }
                .buttonStyle(.bordered)
            }
        }
        .task(id: isRunning) {
            guard isRunning else { return }

            while isRunning && remainingSeconds > 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard !Task.isCancelled, isRunning else { return }
                remainingSeconds -= 1
            }

            if remainingSeconds <= 0 {
                isRunning = false
            }
        }
    }

    private var timerText: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}


// =====================================================
// MARK: - Meal Background Image
// =====================================================

private struct MealExperienceBackgroundImage: View {

    let kind: GameNodeKind
    let image: GameNodeImage?

    var body: some View {
        Group {
            switch image {
            case let .asset(name):
                if let uiImage = UIImage(named: name) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    placeholder
                }

            case let .remote(urlString):
                if let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case let .success(image):
                            image.resizable().scaledToFill()
                        case .empty:
                            ZStack {
                                placeholder
                                ProgressView().tint(.white)
                            }
                        case .failure:
                            placeholder
                        @unknown default:
                            placeholder
                        }
                    }
                } else {
                    placeholder
                }

            case .systemSymbol, nil:
                placeholder
            }
        }
        .ignoresSafeArea()
    }

    private var placeholder: some View {
        Image(uiImage: GameNodePlaceholderImage.image(for: kind, size: 900))
            .resizable()
            .scaledToFill()
    }
}
