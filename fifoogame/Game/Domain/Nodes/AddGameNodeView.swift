//
//  AddGameNodeView.swift
//  fifoogame
//
//  Creation flow for new path stops.
//

import SwiftUI
import Foundation
import UIKit
import PhotosUI
import AVKit
import Vision
import UniformTypeIdentifiers


struct AddGameNodeView: View {

    let initialCoordinate: MapCoordinate
    let roadGraph: RoadGraph
    let onAdd: (GameMapNode) -> Void

    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Spacer()
                    Text("Add Stop to Path")
                        .font(.title)
                        .foregroundStyle(.white)
                        .padding(.vertical)
                    Spacer()
                }

                Spacer()

                HStack {
                    Spacer()
                    AddGameNodeEmojiButton(addType: .meal, emoji: "🍲")
                    Spacer()
                    AddGameNodeEmojiButton(addType: .workout, emoji: "🏋🏻‍♂️")
                    Spacer()
                }

                Spacer()

                HStack {
                    Spacer()
                    AddGameNodeEmojiButton(addType: .task, emoji: "🤹")
                    Spacer()
                }

                Spacer()

                HStack {
                    Spacer()
                    AddGameNodeEmojiButton(addType: .tip, emoji: "📢")
                    Spacer()
                    AddGameNodeEmojiButton(addType: .request, emoji: "✋")
                    Spacer()
                }

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
            .background(Color(red: 26 / 255, green: 38 / 255, blue: 50 / 255))
            .navigationTitle("|||||||||||||||")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: AddGameNodeType.self) { addType in
                NewGameNodeEditorScreen(
                    addType: addType,
                    initialCoordinate: initialCoordinate,
                    roadGraph: roadGraph,
                    onAdd: onAdd
                )
            }
        }
    }
}


private struct AddGameNodeEmojiButton: View {

    let addType: AddGameNodeType
    let emoji: String

    var body: some View {
        NavigationLink(value: addType) {
            Text(emoji)
                .font(.system(size: 70))
                .frame(width: 124, height: 124)
                .background(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .fill(.ultraThickMaterial)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .stroke(.primary.opacity(0.08), lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 6)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(addType.displayName)
    }
}


// =====================================================
// MARK: - Add Stop Router
// =====================================================

private struct NewGameNodeEditorScreen: View {

    let addType: AddGameNodeType
    let initialCoordinate: MapCoordinate
    let roadGraph: RoadGraph
    let onAdd: (GameMapNode) -> Void

    @State private var didRecordTypeSelection = false

    var body: some View {
        Group {
            switch addType {
            case .meal:
                AddMealStopFlow(
                    initialCoordinate: initialCoordinate,
                    roadGraph: roadGraph,
                    onAdd: onAdd
                )

            case .workout:
                AddWorkoutStopFlow(
                    initialCoordinate: initialCoordinate,
                    roadGraph: roadGraph,
                    onAdd: onAdd
                )

            case .task:
                AddTaskStopView(
                    initialCoordinate: initialCoordinate,
                    roadGraph: roadGraph,
                    onAdd: onAdd
                )

            case .tip, .request:
                AddPostStopView(
                    addType: addType,
                    initialCoordinate: initialCoordinate,
                    roadGraph: roadGraph,
                    onAdd: onAdd
                )
            }
        }
        .onAppear {
            guard !didRecordTypeSelection else { return }
            didRecordTypeSelection = true

            SocketManager.shared.nodeCreationTypeSelected(
                addType: addType,
                coordinate: initialCoordinate
            )
        }
    }
}


// =====================================================
// MARK: - Meal Creation
// =====================================================

private struct AddMealStopFlow: View {

    let initialCoordinate: MapCoordinate
    let roadGraph: RoadGraph
    let onAdd: (GameMapNode) -> Void

    @State private var selectedMeal: ActivityMealBrowseChoice?
    @State private var selectedPhoto: AddStopLocalMedia?
    @State private var searchText = ""
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var isAnalyzingPhoto = false
    @State private var mediaErrorMessage: String?

    var body: some View {
        Group {
            if let selectedMeal {
                AddMealReviewView(
                    meal: selectedMeal,
                    localPhoto: selectedPhoto,
                    initialCoordinate: initialCoordinate,
                    roadGraph: roadGraph,
                    onBack: {
                        self.selectedMeal = nil
                        self.selectedPhoto = nil
                    },
                    onAdd: onAdd
                )
            } else {
                mealBrowser
            }
        }
        .alert(
            "Unable to Read Meal Photo",
            isPresented: Binding(
                get: { mediaErrorMessage != nil },
                set: { if !$0 { mediaErrorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(mediaErrorMessage ?? "Please choose another image.")
        }
    }

    private var mealBrowser: some View {
        List {
            Section {
                PhotosPicker(selection: $photoPickerItem, matching: .images) {
                    HStack(spacing: 14) {
                        Image(systemName: "camera.viewfinder")
                            .font(.title2)
                            .frame(width: 36, height: 36)
                            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10))

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Add a Meal Photo")
                                .fontWeight(.semibold)
                            Text("Fifoo will suggest a meal title from the image. You can review and edit it before saving.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .disabled(isAnalyzingPhoto)

                if isAnalyzingPhoto {
                    HStack {
                        ProgressView()
                        Text("Detecting meal…")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if !trimmedSearchText.isEmpty && !hasExactMealMatch {
                Section("Use Search") {
                    Button {
                        selectedPhoto = nil
                        selectedMeal = ActivityMealBrowseChoice(
                            id: "custom-\(UUID().uuidString)",
                            title: trimmedSearchText,
                            subtitle: "Custom meal",
                            imageURL: nil
                        )
                    } label: {
                        Label("Use “\(trimmedSearchText)”", systemImage: "plus.circle.fill")
                    }
                }
            }

            Section("Suggested Meals") {
                ForEach(filteredMeals) { meal in
                    Button {
                        selectedPhoto = nil
                        selectedMeal = meal
                    } label: {
                        HStack(spacing: 12) {
                            AddStopRemoteThumbnail(urlString: meal.imageURL)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(meal.title)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text(meal.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .navigationTitle("Browse Meals")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search meals")
        .onChange(of: photoPickerItem) { _, newItem in
            guard let newItem else { return }
            Task { await loadMealPhoto(newItem) }
        }
    }

    private var trimmedSearchText: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var filteredMeals: [ActivityMealBrowseChoice] {
        let all = AddStopMealCatalog.options
        guard !trimmedSearchText.isEmpty else { return all }

        return all.filter {
            $0.title.localizedCaseInsensitiveContains(trimmedSearchText)
            || $0.subtitle.localizedCaseInsensitiveContains(trimmedSearchText)
        }
    }

    private var hasExactMealMatch: Bool {
        AddStopMealCatalog.options.contains {
            $0.title.caseInsensitiveCompare(trimmedSearchText) == .orderedSame
        }
    }

    @MainActor
    private func loadMealPhoto(_ item: PhotosPickerItem) async {
        isAnalyzingPhoto = true
        defer { isAnalyzingPhoto = false }

        do {
            let media = try await AddStopMediaLoader.load(item, kind: .image)
            let detectedTitle = await AddStopMealPhotoAnalyzer.suggestedTitle(from: media.data)

            selectedPhoto = media
            selectedMeal = ActivityMealBrowseChoice(
                id: "photo-\(UUID().uuidString)",
                title: detectedTitle,
                subtitle: "Detected from meal photo • Review before saving",
                imageURL: nil
            )
            photoPickerItem = nil
        } catch {
            mediaErrorMessage = error.localizedDescription
        }
    }
}


private struct AddMealReviewView: View {

    let meal: ActivityMealBrowseChoice
    let localPhoto: AddStopLocalMedia?
    let initialCoordinate: MapCoordinate
    let roadGraph: RoadGraph
    let onBack: () -> Void
    let onAdd: (GameMapNode) -> Void

    @State private var mealTitle: String
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var isSaving = false
    @State private var saveErrorMessage: String?

    init(
        meal: ActivityMealBrowseChoice,
        localPhoto: AddStopLocalMedia?,
        initialCoordinate: MapCoordinate,
        roadGraph: RoadGraph,
        onBack: @escaping () -> Void,
        onAdd: @escaping (GameMapNode) -> Void
    ) {
        self.meal = meal
        self.localPhoto = localPhoto
        self.initialCoordinate = initialCoordinate
        self.roadGraph = roadGraph
        self.onBack = onBack
        self.onAdd = onAdd

        let start = addStopReferenceDate(for: initialCoordinate.time)
        _mealTitle = State(initialValue: meal.title)
        _startDate = State(initialValue: start)
        _endDate = State(initialValue: start.addingTimeInterval(45 * 60))
    }

    var body: some View {
        Form {
            Section("Selected Meal") {
                HStack(spacing: 14) {
                    if let localPhoto,
                       let image = localPhoto.previewImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 88, height: 88)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    } else {
                        AddStopRemoteThumbnail(urlString: meal.imageURL, size: 88)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(meal.subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if localPhoto != nil {
                            Label("AI suggested title", systemImage: "sparkles")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                TextField("Meal title", text: $mealTitle)
                    .textInputAutocapitalization(.words)
            }

            Section("Time") {
                DatePicker("Start", selection: $startDate, displayedComponents: .hourAndMinute)
                DatePicker("End", selection: $endDate, displayedComponents: .hourAndMinute)

                if endDate <= startDate {
                    Text("End time must be after start time.")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            if localPhoto != nil {
                Section {
                    Text("The selected photo is uploaded to Cloudinary when you save. The detected meal name is only a suggestion and remains editable.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Meal Details")
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Back", action: onBack)
                    .disabled(isSaving)
            }

            ToolbarItem(placement: .confirmationAction) {
                Button(isSaving ? "Saving…" : "Save") {
                    Task { await save() }
                }
                .fontWeight(.semibold)
                .disabled(!canSave || isSaving)
            }
        }
        .alert(
            "Could Not Add Meal",
            isPresented: Binding(
                get: { saveErrorMessage != nil },
                set: { if !$0 { saveErrorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(saveErrorMessage ?? "Please try again.")
        }
    }

    private var canSave: Bool {
        !mealTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && endDate > startDate
    }

    @MainActor
    private func save() async {
        guard canSave else { return }
        isSaving = true
        defer { isSaving = false }

        do {
            let startTime = addStopDayTime(from: startDate)
            let endTime = addStopDayTime(from: endDate)
            var draft = GameNodeFactory.make(addType: .meal, coordinate: initialCoordinate)
            draft = addStopMoveNode(draft, to: startTime, roadGraph: roadGraph)

            guard case var .activity(content) = draft.content else {
                throw AddStopCreationError.invalidDraft
            }

            let cleanedTitle = mealTitle.trimmingCharacters(in: .whitespacesAndNewlines)
            let durationMinutes = max(1, Int((endDate.timeIntervalSince(startDate) / 60).rounded()))

            var remoteImageURL = meal.imageURL
            if let localPhoto {
                remoteImageURL = try await AddStopCloudinaryUploader.upload(localPhoto)
            }

            var summary = content.meal ?? ActivityMealNodeSummary(
                suggestedMealID: UUID().uuidString,
                title: cleanedTitle,
                estimatedTimeMinutes: durationMinutes,
                priceRange: ""
            )

            summary.title = cleanedTitle
            summary.estimatedTimeMinutes = durationMinutes
            summary.imageURL = remoteImageURL
            summary.meals = [
                ActivityMealItemNodeSummary(
                    mealID: meal.id,
                    title: cleanedTitle,
                    imageURL: remoteImageURL,
                    estimatedTimeMinutes: durationMinutes,
                    priceRange: summary.priceRange,
                    recipeCount: 0,
                    ingredientCount: 0,
                    sourceCount: 0
                )
            ]

            content.title = cleanedTitle
            content.startTime = startTime.displayClockString
            content.endTime = endTime.displayClockString
            content.meal = summary
            content.workout = nil
            content.task = nil

            if let remoteImageURL,
               !remoteImageURL.isEmpty {
                content.image = .remote(urlString: remoteImageURL)
            }

            draft.content = .activity(content)
            try addStopFinalize(draft, roadGraph: roadGraph, onAdd: onAdd)
        } catch {
            saveErrorMessage = error.localizedDescription
        }
    }
}


private enum AddStopMealCatalog {

    static let options: [ActivityMealBrowseChoice] = [
        ActivityMealBrowseChoice(
            id: "meal-breakfast-sandwich",
            title: "Breakfast Sandwich",
            subtitle: "Egg, cheese and breakfast protein • about 20 min",
            imageURL: "https://picsum.photos/seed/fifoo-breakfast-sandwich/500/500"
        ),
        ActivityMealBrowseChoice(
            id: "meal-chicken-burrito-bowl",
            title: "Chicken Burrito Bowl",
            subtitle: "Rice, chicken, beans and toppings • about 35 min",
            imageURL: "https://picsum.photos/seed/fifoo-burrito-bowl/500/500"
        ),
        ActivityMealBrowseChoice(
            id: "meal-grilled-chicken-salad",
            title: "Grilled Chicken Salad",
            subtitle: "Greens, vegetables and grilled chicken • about 25 min",
            imageURL: "https://picsum.photos/seed/fifoo-chicken-salad/500/500"
        ),
        ActivityMealBrowseChoice(
            id: "meal-cheeseburger",
            title: "Cheeseburger",
            subtitle: "Burger, cheese and sides • about 30 min",
            imageURL: "https://picsum.photos/seed/fifoo-cheeseburger/500/500"
        ),
        ActivityMealBrowseChoice(
            id: "meal-pasta-primavera",
            title: "Pasta Primavera",
            subtitle: "Pasta with seasonal vegetables • about 30 min",
            imageURL: "https://picsum.photos/seed/fifoo-pasta/500/500"
        ),
        ActivityMealBrowseChoice(
            id: "meal-salmon-rice",
            title: "Salmon & Rice",
            subtitle: "Salmon, rice and vegetables • about 40 min",
            imageURL: "https://picsum.photos/seed/fifoo-salmon-rice/500/500"
        )
    ]
}


// =====================================================
// MARK: - Workout Creation
// =====================================================

private struct AddWorkoutStopFlow: View {

    let initialCoordinate: MapCoordinate
    let roadGraph: RoadGraph
    let onAdd: (GameMapNode) -> Void

    @State private var selectedWorkout: ActivityWorkoutBrowseOption?
    @State private var searchText = ""

    var body: some View {
        Group {
            if let selectedWorkout {
                AddWorkoutReviewView(
                    option: selectedWorkout,
                    initialCoordinate: initialCoordinate,
                    roadGraph: roadGraph,
                    onBack: { self.selectedWorkout = nil },
                    onAdd: onAdd
                )
            } else {
                workoutBrowser
            }
        }
    }

    private var workoutBrowser: some View {
        List {
            let classes = filteredWorkouts.filter { $0.summary.resolvedWorkoutType == .guidedClass }
            let independent = filteredWorkouts.filter { $0.summary.resolvedWorkoutType == .independent }

            if !classes.isEmpty {
                Section("Workout Classes") {
                    ForEach(classes) { option in
                        workoutRow(option)
                    }
                }
            }

            if !independent.isEmpty {
                Section("Independent Workouts") {
                    ForEach(independent) { option in
                        workoutRow(option)
                    }
                }
            }
        }
        .navigationTitle("Browse Workouts")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search workouts")
    }

    @ViewBuilder
    private func workoutRow(_ option: ActivityWorkoutBrowseOption) -> some View {
        Button {
            selectedWorkout = option
        } label: {
            HStack(spacing: 12) {
                AddStopRemoteThumbnail(urlString: option.summary.imageURLs?.first)

                VStack(alignment: .leading, spacing: 4) {
                    Text(option.summary.title)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(workoutSubtitle(option.summary))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var filteredWorkouts: [ActivityWorkoutBrowseOption] {
        let cleaned = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return ActivityWorkoutBrowseCatalog.options }

        return ActivityWorkoutBrowseCatalog.options.filter { option in
            let summary = option.summary
            return summary.title.localizedCaseInsensitiveContains(cleaned)
                || summary.categories.contains(where: { $0.localizedCaseInsensitiveContains(cleaned) })
                || summary.location.localizedCaseInsensitiveContains(cleaned)
                || (summary.trainer?.name.localizedCaseInsensitiveContains(cleaned) ?? false)
        }
    }

    private func workoutSubtitle(_ workout: ActivityWorkoutNodeSummary) -> String {
        var pieces: [String] = []
        pieces.append(workout.resolvedWorkoutType.displayName)
        if !workout.durationText.isEmpty { pieces.append(workout.durationText) }
        if workout.resolvedWorkoutType == .guidedClass,
           !workout.selectedWorkoutTime.isEmpty {
            pieces.append(workout.selectedWorkoutTime)
        }
        return pieces.joined(separator: " • ")
    }
}


private struct AddWorkoutReviewView: View {

    let option: ActivityWorkoutBrowseOption
    let initialCoordinate: MapCoordinate
    let roadGraph: RoadGraph
    let onBack: () -> Void
    let onAdd: (GameMapNode) -> Void

    @State private var startDate: Date
    @State private var endDate: Date
    @State private var saveErrorMessage: String?

    init(
        option: ActivityWorkoutBrowseOption,
        initialCoordinate: MapCoordinate,
        roadGraph: RoadGraph,
        onBack: @escaping () -> Void,
        onAdd: @escaping (GameMapNode) -> Void
    ) {
        self.option = option
        self.initialCoordinate = initialCoordinate
        self.roadGraph = roadGraph
        self.onBack = onBack
        self.onAdd = onAdd

        let summary = option.summary
        let startDayTime: DayTime
        if summary.resolvedWorkoutType == .guidedClass,
           let fixed = addStopParseClockString(summary.selectedWorkoutTime) {
            startDayTime = fixed
        } else {
            startDayTime = initialCoordinate.time
        }

        let start = addStopReferenceDate(for: startDayTime)
        let duration = summary.durationInSeconds > 0
            ? TimeInterval(summary.durationInSeconds)
            : 45 * 60

        _startDate = State(initialValue: start)
        _endDate = State(initialValue: start.addingTimeInterval(duration))
    }

    var body: some View {
        Form {
            Section("Selected Workout") {
                HStack(spacing: 14) {
                    AddStopRemoteThumbnail(urlString: option.summary.imageURLs?.first, size: 90)
                    VStack(alignment: .leading, spacing: 5) {
                        Text(option.summary.title)
                            .font(.headline)
                        Text(option.summary.resolvedWorkoutType.displayName)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }

                if let description = option.summary.description,
                   !description.isEmpty {
                    Text(description)
                        .font(.callout)
                }

                if !option.summary.location.isEmpty {
                    LabeledContent("Location", value: option.summary.location)
                }
                if !option.summary.durationText.isEmpty {
                    LabeledContent("Duration", value: option.summary.durationText)
                }
                if let trainer = option.summary.trainer,
                   !trainer.name.isEmpty {
                    LabeledContent("Trainer", value: trainer.name)
                }
                if !option.summary.categories.isEmpty {
                    LabeledContent("Categories", value: option.summary.categories.joined(separator: ", "))
                }
            }

            Section("Time") {
                if option.summary.resolvedWorkoutType == .guidedClass {
                    LabeledContent("Start", value: addStopDayTime(from: startDate).displayClockString)
                    LabeledContent("End", value: addStopDayTime(from: endDate).displayClockString)

                    Text("Workout class times are fixed. Go back and choose another class if you need a different time.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    DatePicker("Start", selection: $startDate, displayedComponents: .hourAndMinute)
                    DatePicker("End", selection: $endDate, displayedComponents: .hourAndMinute)

                    if endDate <= startDate {
                        Text("End time must be after start time.")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
        }
        .navigationTitle("Workout Details")
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Back", action: onBack)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }
                    .fontWeight(.semibold)
                    .disabled(option.summary.resolvedWorkoutType == .independent && endDate <= startDate)
            }
        }
        .alert(
            "Could Not Add Workout",
            isPresented: Binding(
                get: { saveErrorMessage != nil },
                set: { if !$0 { saveErrorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(saveErrorMessage ?? "Please try again.")
        }
    }

    private func save() {
        do {
            var draft = GameNodeFactory.make(addType: .workout, coordinate: initialCoordinate)
            draft = activityWorkoutApplyingSelection(option, to: draft, roadGraph: roadGraph)

            if option.summary.resolvedWorkoutType == .independent {
                let startTime = addStopDayTime(from: startDate)
                let endTime = addStopDayTime(from: endDate)
                draft = activityWorkoutUpdatingIndependentSchedule(
                    draft,
                    to: startTime,
                    roadGraph: roadGraph
                )

                if case var .activity(content) = draft.content {
                    content.endTime = endTime.displayClockString
                    draft.content = .activity(content)
                }
            }

            try addStopFinalize(draft, roadGraph: roadGraph, onAdd: onAdd)
        } catch {
            saveErrorMessage = error.localizedDescription
        }
    }
}


// =====================================================
// MARK: - Task Creation
// =====================================================

private struct AddTaskStopView: View {

    let initialCoordinate: MapCoordinate
    let roadGraph: RoadGraph
    let onAdd: (GameMapNode) -> Void

    @State private var title = ""
    @State private var taskDescription = ""
    @State private var location = ""
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var localImages: [AddStopLocalMedia] = []
    @State private var isLoadingMedia = false
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(
        initialCoordinate: MapCoordinate,
        roadGraph: RoadGraph,
        onAdd: @escaping (GameMapNode) -> Void
    ) {
        self.initialCoordinate = initialCoordinate
        self.roadGraph = roadGraph
        self.onAdd = onAdd

        let start = addStopReferenceDate(for: initialCoordinate.time)
        _startDate = State(initialValue: start)
        _endDate = State(initialValue: start.addingTimeInterval(60 * 60))
    }

    var body: some View {
        Form {
            Section("Task") {
                TextField("Task title", text: $title)
                TextField("Description", text: $taskDescription, axis: .vertical)
                    .lineLimit(3...8)
                TextField("Location", text: $location)
            }

            Section("Time") {
                DatePicker("Start", selection: $startDate, displayedComponents: .hourAndMinute)
                DatePicker("End", selection: $endDate, displayedComponents: .hourAndMinute)

                if endDate <= startDate {
                    Text("End time must be after start time.")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            Section("Images") {
                PhotosPicker(
                    selection: $pickerItems,
                    maxSelectionCount: 8,
                    matching: .images
                ) {
                    Label("Upload Images", systemImage: "photo.on.rectangle.angled")
                }

                if isLoadingMedia {
                    HStack {
                        ProgressView()
                        Text("Preparing images…")
                            .foregroundStyle(.secondary)
                    }
                }

                if !localImages.isEmpty {
                    AddStopImagePreviewStrip(
                        media: localImages,
                        onRemove: removeLocalImage
                    )
                } else {
                    Text("Selected images are previewed here and uploaded to Cloudinary when the task is saved.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("New Task")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(isSaving ? "Saving…" : "Save") {
                    Task { await save() }
                }
                .fontWeight(.semibold)
                .disabled(!canSave || isSaving || isLoadingMedia)
            }
        }
        .onChange(of: pickerItems) { _, newItems in
            Task { await loadImages(newItems) }
        }
        .alert(
            "Could Not Add Task",
            isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "Please try again.")
        }
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && endDate > startDate
    }

    @MainActor
    private func loadImages(_ items: [PhotosPickerItem]) async {
        isLoadingMedia = true
        defer { isLoadingMedia = false }

        do {
            localImages = try await AddStopMediaLoader.load(items, kind: .image)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func removeLocalImage(_ id: UUID) {
        localImages.removeAll { $0.id == id }
    }

    @MainActor
    private func save() async {
        guard canSave else { return }
        isSaving = true
        defer { isSaving = false }

        do {
            let uploadedImageURLs = try await AddStopCloudinaryUploader.upload(localImages)
            let startTime = addStopDayTime(from: startDate)
            let endTime = addStopDayTime(from: endDate)

            var draft = GameNodeFactory.make(addType: .task, coordinate: initialCoordinate)
            draft = addStopMoveNode(draft, to: startTime, roadGraph: roadGraph)

            guard case var .activity(content) = draft.content else {
                throw AddStopCreationError.invalidDraft
            }

            let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
            content.title = cleanTitle
            content.startTime = startTime.displayClockString
            content.endTime = endTime.displayClockString
            content.location = location.trimmingCharacters(in: .whitespacesAndNewlines)
            content.description = taskDescription.trimmingCharacters(in: .whitespacesAndNewlines)

            var task = content.task ?? ActivityTaskNodeSummary(
                activityTaskID: UUID().uuidString,
                taskID: UUID().uuidString,
                title: cleanTitle,
                description: taskDescription
            )
            task.title = cleanTitle
            task.description = taskDescription.trimmingCharacters(in: .whitespacesAndNewlines)
            task.imageURLs = uploadedImageURLs
            content.task = task

            if let first = uploadedImageURLs.first {
                content.image = .remote(urlString: first)
            }

            draft.content = .activity(content)
            try addStopFinalize(draft, roadGraph: roadGraph, onAdd: onAdd)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}


// =====================================================
// MARK: - Tip / Request Creation
// =====================================================

private struct AddPostStopView: View {

    let addType: AddGameNodeType
    let initialCoordinate: MapCoordinate
    let roadGraph: RoadGraph
    let onAdd: (GameMapNode) -> Void

    @State private var subject = ""
    @State private var selectedImageItems: [PhotosPickerItem] = []
    @State private var selectedVideoItems: [PhotosPickerItem] = []
    @State private var localImages: [AddStopLocalMedia] = []
    @State private var localVideos: [AddStopLocalMedia] = []
    @State private var isLoadingMedia = false
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        Form {
            postTypeSection
            subjectSection
            imageSection
            videoSection
            loadingSection
        }
        .navigationTitle("New \(addType.displayName)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(isSaving ? "Saving…" : "Save") {
                    Task { await save() }
                }
                .fontWeight(.semibold)
                .disabled(!canSave || isSaving || isLoadingMedia)
            }
        }
        .onChange(of: selectedImageItems) { _, items in
            Task { await loadMedia(images: items, videos: selectedVideoItems) }
        }
        .onChange(of: selectedVideoItems) { _, items in
            Task { await loadMedia(images: selectedImageItems, videos: items) }
        }
        .alert(
            "Could Not Add \(addType.displayName)",
            isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "Please try again.")
        }
    }

    @ViewBuilder
    private var postTypeSection: some View {
        Section("Post Type") {
            LabeledContent("Type", value: addType.displayName)
        }
    }

    @ViewBuilder
    private var subjectSection: some View {
        Section("Subject") {
            TextField("Subject", text: $subject, axis: .vertical)
                .lineLimit(2...8)
        }
    }

    @ViewBuilder
    private var imageSection: some View {
        Section("Images") {
            PhotosPicker(
                selection: $selectedImageItems,
                maxSelectionCount: 8,
                matching: .images
            ) {
                Label("Upload Images", systemImage: "photo.on.rectangle.angled")
            }

            if localImages.isEmpty {
                Text("No image URLs are entered manually. Choose images here to preview them before upload.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                AddStopImagePreviewStrip(
                    media: localImages,
                    onRemove: removeLocalImage
                )
            }
        }
    }

    @ViewBuilder
    private var videoSection: some View {
        Section("Videos") {
            PhotosPicker(
                selection: $selectedVideoItems,
                maxSelectionCount: 4,
                matching: .videos
            ) {
                Label("Upload Videos", systemImage: "video.badge.plus")
            }

            if localVideos.isEmpty {
                Text("Videos are previewed locally, then uploaded to Cloudinary when you save.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                AddStopVideoPreviewList(
                    media: localVideos,
                    onRemove: removeLocalVideo
                )
            }
        }
    }

    @ViewBuilder
    private var loadingSection: some View {
        if isLoadingMedia {
            Section {
                HStack {
                    ProgressView()
                    Text("Preparing media…")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var canSave: Bool {
        !subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func removeLocalImage(_ id: UUID) {
        localImages.removeAll { item in
            item.id == id
        }
    }

    private func removeLocalVideo(_ id: UUID) {
        localVideos.removeAll { item in
            item.id == id
        }
    }

    @MainActor
    private func loadMedia(
        images: [PhotosPickerItem],
        videos: [PhotosPickerItem]
    ) async {
        isLoadingMedia = true
        defer { isLoadingMedia = false }

        do {
            localImages = try await AddStopMediaLoader.load(images, kind: .image)
            localVideos = try await AddStopMediaLoader.load(videos, kind: .video)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func save() async {
        guard canSave else { return }
        isSaving = true
        defer { isSaving = false }

        do {
            let imageURLs = try await AddStopCloudinaryUploader.upload(localImages)
            let videoURLs = try await AddStopCloudinaryUploader.upload(localVideos)

            var draft = GameNodeFactory.make(addType: addType, coordinate: initialCoordinate)

            guard case var .post(content) = draft.content,
                  var snapshot = content.snapshot else {
                throw AddStopCreationError.invalidDraft
            }

            snapshot.subject = subject.trimmingCharacters(in: .whitespacesAndNewlines)
            snapshot.postImageURLs = imageURLs
            snapshot.postVideoURLs = videoURLs
            snapshot.postMediaCount = imageURLs.count + videoURLs.count

            if let firstImage = imageURLs.first {
                snapshot.postMainMediaURL = firstImage
                snapshot.postMainMediaType = "image"
            } else if let firstVideo = videoURLs.first {
                snapshot.postMainMediaURL = firstVideo
                snapshot.postMainMediaType = "video"
            } else {
                snapshot.postMainMediaURL = ""
                snapshot.postMainMediaType = ""
            }

            content.snapshot = snapshot
            draft.content = .post(content)
            try addStopFinalize(draft, roadGraph: roadGraph, onAdd: onAdd)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}


// =====================================================
// MARK: - Local Media + Preview
// =====================================================

private enum AddStopLocalMediaKind: String {
    case image
    case video
}


private struct AddStopLocalMedia: Identifiable, @unchecked Sendable {
    let id = UUID()
    let kind: AddStopLocalMediaKind
    let data: Data
    let filename: String
    let mimeType: String
    let previewImage: UIImage?
    let temporaryURL: URL?
}


private enum AddStopMediaLoader {

    static func load(
        _ items: [PhotosPickerItem],
        kind: AddStopLocalMediaKind
    ) async throws -> [AddStopLocalMedia] {
        var output: [AddStopLocalMedia] = []
        for item in items {
            output.append(try await load(item, kind: kind))
        }
        return output
    }

    static func load(
        _ item: PhotosPickerItem,
        kind: AddStopLocalMediaKind
    ) async throws -> AddStopLocalMedia {
        guard let data = try await item.loadTransferable(type: Data.self),
              !data.isEmpty else {
            throw AddStopCreationError.unreadableMedia
        }

        let contentType = item.supportedContentTypes.first
        let fallbackExtension = kind == .image ? "jpg" : "mov"
        let fileExtension = contentType?.preferredFilenameExtension ?? fallbackExtension
        let mimeType = contentType?.preferredMIMEType
            ?? (kind == .image ? "image/jpeg" : "video/quicktime")
        let filename = "fifoo-\(UUID().uuidString).\(fileExtension)"

        if kind == .image {
            guard let image = UIImage(data: data) else {
                throw AddStopCreationError.unreadableMedia
            }

            return AddStopLocalMedia(
                kind: kind,
                data: data,
                filename: filename,
                mimeType: mimeType,
                previewImage: image,
                temporaryURL: nil
            )
        }

        let temporaryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(filename)
        try data.write(to: temporaryURL, options: .atomic)

        return AddStopLocalMedia(
            kind: kind,
            data: data,
            filename: filename,
            mimeType: mimeType,
            previewImage: nil,
            temporaryURL: temporaryURL
        )
    }
}


private struct AddStopImagePreviewStrip: View {

    let media: [AddStopLocalMedia]
    let onRemove: (UUID) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(media) { item in
                    if let image = item.previewImage {
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 110, height: 110)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                            Button {
                                onRemove(item.id)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title3)
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(.white, .black.opacity(0.72))
                            }
                            .buttonStyle(.plain)
                            .padding(5)
                        }
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }
}


private struct AddStopVideoPreviewList: View {

    let media: [AddStopLocalMedia]
    let onRemove: (UUID) -> Void

    var body: some View {
        VStack(spacing: 12) {
            ForEach(media) { item in
                AddStopVideoPreviewRow(
                    media: item,
                    onRemove: onRemove
                )
            }
        }
    }
}


private struct AddStopVideoPreviewRow: View {

    let media: AddStopLocalMedia
    let onRemove: (UUID) -> Void

    var body: some View {
        Group {
            if let url = media.temporaryURL {
                VStack(alignment: .trailing, spacing: 8) {
                    AddStopVideoPreview(url: url)

                    Button(
                        role: .destructive,
                        action: removeVideo
                    ) {
                        Text("Remove")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                }
            }
        }
    }

    private func removeVideo() {
        onRemove(media.id)
    }
}


private struct AddStopVideoPreview: View {

    let url: URL
    @State private var player: AVPlayer

    init(url: URL) {
        self.url = url
        _player = State(initialValue: AVPlayer(url: url))
    }

    var body: some View {
        VideoPlayer(player: player)
            .frame(height: 210)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .onDisappear { player.pause() }
    }
}


private struct AddStopRemoteThumbnail: View {

    let urlString: String?
    var size: CGFloat = 62

    var body: some View {
        Group {
            if let urlString,
               let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: max(10, size * 0.18), style: .continuous))
    }

    private var placeholder: some View {
        ZStack {
            Color.secondary.opacity(0.12)
            Image(systemName: "fork.knife")
                .foregroundStyle(.secondary)
        }
    }
}


// =====================================================
// MARK: - Meal Photo AI Detection
// =====================================================

private enum AddStopMealPhotoAnalyzer {

    /// Uses Apple's on-device Vision image classifier to seed a meal title.
    /// The result is intentionally editable because generic image classifiers
    /// can identify a broad dish category rather than the exact recipe.
    static func suggestedTitle(from data: Data) async -> String {
        guard let image = UIImage(data: data),
              let cgImage = image.cgImage else {
            return "Meal from Photo"
        }

        return await withCheckedContinuation { continuation in
            let request = VNClassifyImageRequest { request, _ in
                let observations = (request.results as? [VNClassificationObservation]) ?? []

                let preferred = observations.first { observation in
                    observation.confidence >= 0.08
                    && !ignoredVisionLabels.contains(
                        normalizedVisionLabel(observation.identifier).lowercased()
                    )
                } ?? observations.first

                let title = preferred
                    .map { normalizedVisionLabel($0.identifier) }
                    .flatMap { $0.isEmpty ? nil : $0 }
                    ?? "Meal from Photo"

                continuation.resume(returning: title)
            }

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(returning: "Meal from Photo")
            }
        }
    }

    private static let ignoredVisionLabels: Set<String> = [
        "food",
        "dish",
        "plate",
        "tableware",
        "meal",
        "ingredient"
    ]

    private static func normalizedVisionLabel(_ identifier: String) -> String {
        let first = identifier
            .split(separator: ",")
            .first
            .map(String.init)
            ?? identifier

        return first
            .replacingOccurrences(of: "_", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .capitalized
    }
}


// =====================================================
// MARK: - Cloudinary Upload
// =====================================================

private struct AddStopCloudinaryConfiguration {

    let cloudName: String
    let unsignedUploadPreset: String

    static var current: AddStopCloudinaryConfiguration? {
        let info = Bundle.main.infoDictionary ?? [:]
        let environment = ProcessInfo.processInfo.environment

        let cloudName = (
            environment["CLOUDINARY_CLOUD_NAME"]
            ?? info["CLOUDINARY_CLOUD_NAME"] as? String
            ?? ""
        )
        .trimmingCharacters(in: .whitespacesAndNewlines)

        let uploadPreset = (
            environment["CLOUDINARY_UNSIGNED_UPLOAD_PRESET"]
            ?? info["CLOUDINARY_UNSIGNED_UPLOAD_PRESET"] as? String
            ?? ""
        )
        .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cloudName.isEmpty,
              !uploadPreset.isEmpty else {
            return nil
        }

        return AddStopCloudinaryConfiguration(
            cloudName: cloudName,
            unsignedUploadPreset: uploadPreset
        )
    }
}


private enum AddStopCloudinaryUploader {

    static func upload(_ media: [AddStopLocalMedia]) async throws -> [String] {
        var urls: [String] = []
        for item in media {
            urls.append(try await upload(item))
        }
        return urls
    }

    static func upload(_ media: AddStopLocalMedia) async throws -> String {
        guard let configuration = AddStopCloudinaryConfiguration.current else {
            throw AddStopCreationError.cloudinaryNotConfigured
        }

        let resourceType = media.kind == .video ? "video" : "image"
        guard let endpoint = URL(
            string: "https://api.cloudinary.com/v1_1/\(configuration.cloudName)/\(resourceType)/upload"
        ) else {
            throw AddStopCreationError.cloudinaryUploadFailed("Invalid Cloudinary cloud name.")
        }

        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue(
            "multipart/form-data; boundary=\(boundary)",
            forHTTPHeaderField: "Content-Type"
        )

        var body = Data()
        body.addMultipartText(
            name: "upload_preset",
            value: configuration.unsignedUploadPreset,
            boundary: boundary
        )
        body.addMultipartFile(
            name: "file",
            filename: media.filename,
            mimeType: media.mimeType,
            data: media.data,
            boundary: boundary
        )
        body.appendString("--\(boundary)--\r\n")
        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw AddStopCreationError.cloudinaryUploadFailed("Cloudinary returned an invalid response.")
        }

        let decoded = try? JSONDecoder().decode(AddStopCloudinaryUploadResponse.self, from: data)

        guard (200..<300).contains(http.statusCode) else {
            let message = decoded?.error?.message
                ?? "Cloudinary upload failed with status \(http.statusCode)."
            throw AddStopCreationError.cloudinaryUploadFailed(message)
        }

        guard let secureURL = decoded?.secureURL ?? decoded?.url,
              !secureURL.isEmpty else {
            throw AddStopCreationError.cloudinaryUploadFailed("Cloudinary did not return a media URL.")
        }

        return secureURL
    }
}


private struct AddStopCloudinaryUploadResponse: Decodable {
    struct UploadError: Decodable {
        let message: String
    }

    let secureURL: String?
    let url: String?
    let error: UploadError?

    enum CodingKeys: String, CodingKey {
        case secureURL = "secure_url"
        case url
        case error
    }
}


private extension Data {

    mutating func appendString(_ string: String) {
        guard let data = string.data(using: .utf8) else { return }
        append(data)
    }

    mutating func addMultipartText(
        name: String,
        value: String,
        boundary: String
    ) {
        appendString("--\(boundary)\r\n")
        appendString("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n")
        appendString("\(value)\r\n")
    }

    mutating func addMultipartFile(
        name: String,
        filename: String,
        mimeType: String,
        data: Data,
        boundary: String
    ) {
        appendString("--\(boundary)\r\n")
        appendString("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename)\"\r\n")
        appendString("Content-Type: \(mimeType)\r\n\r\n")
        append(data)
        appendString("\r\n")
    }
}


// =====================================================
// MARK: - Shared Creation Helpers
// =====================================================

private enum AddStopCreationError: LocalizedError {
    case invalidDraft
    case unreadableMedia
    case cloudinaryNotConfigured
    case cloudinaryUploadFailed(String)
    case validationFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidDraft:
            return "The new stop could not be prepared."
        case .unreadableMedia:
            return "The selected image or video could not be read."
        case .cloudinaryNotConfigured:
            return "Cloudinary is not configured. Add CLOUDINARY_CLOUD_NAME and CLOUDINARY_UNSIGNED_UPLOAD_PRESET to Info.plist or the app environment."
        case .cloudinaryUploadFailed(let message):
            return message
        case .validationFailed(let message):
            return message
        }
    }
}


private func addStopFinalize(
    _ node: GameMapNode,
    roadGraph: RoadGraph,
    onAdd: (GameMapNode) -> Void
) throws {
    let normalized = GameNodeNormalizer.normalize(node)
    let validation = GameNodeValidator.validate(normalized, roadGraph: roadGraph)

    guard validation.isValid else {
        let messages = validation.issues.map(\.message).joined(separator: "\n")
        throw AddStopCreationError.validationFailed(
            messages.isEmpty ? "The new stop is not valid yet." : messages
        )
    }

    onAdd(normalized)
}


private func addStopMoveNode(
    _ node: GameMapNode,
    to time: DayTime,
    roadGraph: RoadGraph
) -> GameMapNode {
    var updated = node

    switch updated.placement {
    case let .roadVertex(vertexID):
        if let vertex = roadGraph.vertex(id: vertexID) {
            updated.setPlacement(
                .coordinate(
                    MapCoordinate(
                        time: time,
                        progress: vertex.coordinate.progress
                    )
                )
            )
        } else {
            updated.setTime(time)
        }

    case let .coordinate(coordinate):
        updated.setPlacement(
            .coordinate(
                MapCoordinate(
                    time: time,
                    progress: coordinate.progress
                )
            )
        )
    }

    return updated
}


private func addStopDayTime(from date: Date) -> DayTime {
    DayTime.from(date: date, timeZone: .current)
}


private func addStopReferenceDate(for time: DayTime) -> Date {
    var calendar = Calendar.current
    calendar.timeZone = .current
    let startOfDay = calendar.startOfDay(for: Date())
    return startOfDay.addingTimeInterval(time.secondsFromMidnight)
}


private func addStopParseClockString(_ value: String) -> DayTime? {
    let cleaned = value.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !cleaned.isEmpty else { return nil }

    let formats = ["h:mm a", "h a", "HH:mm", "H:mm"]
    for format in formats {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = format

        if let date = formatter.date(from: cleaned.uppercased()) {
            return addStopDayTime(from: date)
        }
    }

    return nil
}
