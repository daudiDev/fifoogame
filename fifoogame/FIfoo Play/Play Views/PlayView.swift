//
//  PlayView.swift
//  Fifoo Play
//
//  Created by Daudi Sagala on 8/10/26.
//


import SwiftUI
import AVKit

// MARK: - Main Workout Feed

struct PlayView: View {

    @Binding var isShowingPlay: Bool
    
    private let session = WorkoutSessionManager.shared
    private let socketManager = SocketManager.shared
    private let soundManager = WorkoutSoundManager.shared

    @Environment(\.scenePhase)
    private var scenePhase

    // MARK: - Paging

    @State private var currentExerciseIndex: Int = 0
    @State private var pageDragOffset: CGFloat = 0
    @State private var isPageTransitioning = false

    // MARK: - Countdown

    @State private var autoPlaySecondsRemaining: Int = 0
    @State private var countdownGeneration: Int = 0

    private let defaultExerciseDuration: TimeInterval = 120

    // MARK: - Workout UI

    @State private var showWorkoutStatusOverlay = true
    @State private var showWorkoutCompletionView = false
    @State private var showProgressView = false
    
    @State private var autoplayFinishedExerciseID: UUID?

    // MARK: - Body

    var body: some View {

        GeometryReader { geometry in

            ZStack {

                Color.black
                    .ignoresSafeArea()


                // MARK: Exercise Pager

                exercisePager(
                    geometry: geometry
                )
                .zIndex(1)

                // MARK: Exercise Overlay

                if let currentExercise,
                   !showWorkoutCompletionView {

                    PlayOverlay(
                        geometry: geometry,
                        workoutExercise: currentExercise,
                        autoPlaySecondsRemaining:
                            autoPlaySecondsRemaining,

                        onCompleteExercise: {

                            completeButtonTapped(
                                pageHeight:
                                    geometry.size.height
                            )
                        },

                        onPauseExercise: {

                            pauseCurrentExercise()
                        },

                        onResumeExercise: {

                            resumeCurrentExercise()
                        },

                        onExitWorkout: {

                            pauseWorkoutForExit()
                            
                        },
                        
                        liveMessages: socketManager.liveMessages
                        
                    )
                    .zIndex(20)
                }


                // MARK: Workout Status

                if showWorkoutStatusOverlay {

                    WorkoutStatusOverlay(
                        geometry: geometry,
                        showWorkoutStatusOverlay:
                            $showWorkoutStatusOverlay, isShowingPlay: $isShowingPlay
                    )
                    .zIndex(50)
                }


                // MARK: Workout Completed

                if showWorkoutCompletionView {

                    WorkoutCompletedView(
                        workout: session.workout,

                        onFinished: {

                            showWorkoutCompletionView = false
                            showProgressView = true
                        }
                    )
                    .transition(
                        .scale
                            .combined(with: .opacity)
                    )
                    .zIndex(100)
                }
            } //zs

            // Attaching the gesture to the parent means the
            // vertical swipe can begin almost anywhere on screen,
            // including over the overlay.
            .simultaneousGesture(
                pageDragGesture(
                    pageHeight: geometry.size.height
                )
            )
            .onChange(
                of: autoplayFinishedExerciseID
            ) { _, exerciseID in

                guard let exerciseID else {
                    return
                }

                guard exerciseID ==
                        currentExercise?.workoutExerciseId else {

                    autoplayFinishedExerciseID = nil
                    return
                }

                autoplayFinishedExerciseID = nil

                advanceToNextExercise(
                    reason: .autoplay,
                    pageHeight: geometry.size.height
                )
            }
            
        }
        .ignoresSafeArea()

        // MARK: Progress Report

        .fullScreenCover(
            isPresented: $showProgressView
        ) {

            WorkoutProgressReportView(
                showProgressView: $showProgressView
            )
        }

        // MARK: Initial Setup

        .onAppear {

            initializeWorkout()
        }

        // MARK: Workout Started / Resumed / Paused

        .onChange(
            of: session.workout.status
        ) { oldStatus, newStatus in

            handleWorkoutStatusChange(
                from: oldStatus,
                to: newStatus
            )
        }

        // MARK: Status Overlay Closed

        .onChange(
            of: showWorkoutStatusOverlay
        ) { _, isShowing in

            if !isShowing,
               session.workout.status == .active {

                activateCurrentExerciseIfNeeded()
            }
        }

        // MARK: App Lifecycle

        .onChange(
            of: scenePhase
        ) { _, newPhase in

            handleScenePhase(newPhase)
        }

        // MARK: Countdown Task

        .task(
            id: CountdownTaskID(
                exerciseID: currentExercise?.workoutExerciseId,
                workoutStatus: session.workout.status,
                exerciseStatus: currentExercise?.status,
                generation: countdownGeneration
            )
        ) {

            await runExerciseCountdown()
        }
        
        
    }
}


// MARK: - Exercise Pager
private extension PlayView {

    @ViewBuilder
    func exercisePager(
        geometry: GeometryProxy
    ) -> some View {

        ZStack {

            // MARK: Current Page

            if let currentExercise {

                WorkoutExercisePageView(
                    geometry: geometry,
                    workoutExercise: currentExercise,
                    isWorkoutPaused:
                        session.workout.status == .paused
                )
                // IMPORTANT:
                // Forces SwiftUI to create a completely new
                // page when the exercise changes.
                .id(
                    currentExercise.workoutExerciseId
                )
                .frame(
                    width: geometry.size.width,
                    height: geometry.size.height
                )
                .offset(
                    y: pageDragOffset
                )
                .zIndex(2)
            }


            // MARK: Next Page

            if let nextExercise {

                WorkoutExercisePageView(
                    geometry: geometry,
                    workoutExercise: nextExercise,
                    isWorkoutPaused:
                        session.workout.status == .paused
                )
                // IMPORTANT:
                // The next exercise also has its own identity.
                .id(
                    nextExercise.workoutExerciseId
                )
                .frame(
                    width: geometry.size.width,
                    height: geometry.size.height
                )
                .offset(
                    y:
                        geometry.size.height
                        + pageDragOffset
                )
                .zIndex(1)
            }
        }
        .frame(
            width: geometry.size.width,
            height: geometry.size.height
        )
        .clipped()
        .background(Color.black)
    }
}


// MARK: - TikTok Style Drag Gesture

private extension PlayView {

    func pageDragGesture(
        pageHeight: CGFloat
    ) -> some Gesture {

        DragGesture(
            minimumDistance: 8,
            coordinateSpace: .local
        )

        .onChanged { value in

            guard canManuallyAdvance else {
                return
            }

            guard !isPageTransitioning else {
                return
            }

            let horizontalMovement =
                abs(value.translation.width)

            let verticalMovement =
                abs(value.translation.height)

            // Ignore horizontal gestures so the exercise
            // details ScrollView still behaves normally.
            guard verticalMovement >
                    horizontalMovement else {
                return
            }

            // IMPORTANT:
            //
            // Only accept upward movement.
            //
            // Positive Y = dragging downward.
            // Negative Y = dragging upward.
            //
            // min(0, ...) prevents the previous exercise
            // from ever appearing.
            pageDragOffset = min(
                0,
                value.translation.height
            )
        }

        .onEnded { value in

            guard !isPageTransitioning else {
                return
            }

            let horizontalMovement =
                abs(value.translation.width)

            let verticalMovement =
                abs(value.translation.height)

            guard verticalMovement >
                    horizontalMovement else {

                snapCurrentPageBack()
                return
            }

            guard canManuallyAdvance else {

                snapCurrentPageBack()
                return
            }

            // Downward swipe:
            // absolutely no backwards navigation.
            guard value.translation.height < 0 else {

                snapCurrentPageBack()
                return
            }

            let distanceThreshold =
                pageHeight * 0.18

            let actualDistance =
                abs(value.translation.height)

            let predictedDistance =
                abs(
                    value.predictedEndTranslation.height
                )

            let shouldAdvance =
                actualDistance >= distanceThreshold
                ||
                predictedDistance >=
                    pageHeight * 0.35

            if shouldAdvance {

                advanceToNextExercise(
                    reason: .manualSwipe,
                    pageHeight: pageHeight
                )

            } else {

                snapCurrentPageBack()
            }
        }
    }


    func snapCurrentPageBack() {

        withAnimation(
            .snappy(
                duration: 0.28,
                extraBounce: 0
            )
        ) {

            pageDragOffset = 0
        }
    }
}


// MARK: - Advance Exercise

private extension PlayView {

    enum ExerciseAdvanceReason {

        case manualSwipe
        case doneButton
        case autoplay
    }


    func advanceToNextExercise(
        reason: ExerciseAdvanceReason,
        pageHeight: CGFloat
    ) {

        guard !isPageTransitioning else {
            return
        }

        guard let exercise =
                currentExercise
        else {
            return
        }


        // MARK: Decide Exercise Status

        switch reason {

        case .manualSwipe:

            updateExerciseStatusForManualSwipe(
                exercise
            )

        case .doneButton:

            session.completeExercise(
                id:
                    exercise.workoutExerciseId
            )

        case .autoplay:

            session.completeExercise(
                id:
                    exercise.workoutExerciseId
            )
        }


        // MARK: Workout Completion

        let progress =
            session.workoutProgress()

        if progress >= 1.0 {

            handleWorkoutCompleted()
            return
        }


        guard nextExercise != nil else {

            handleWorkoutCompleted()
            return
        }


        // MARK: Transition

        isPageTransitioning =
            true

        countdownGeneration += 1


        // MARK: Swish Sound

        if (reason == .doneButton) {
            
            soundManager.playLevelUp()
            
        } else if (reason == .autoplay) {
            
            soundManager.playLevelUp()
            
        } else {
            
            soundManager.playSwish()
            
        }


        // MARK: Animate New Exercise

        withAnimation(
            .snappy(
                duration: 0.42,
                extraBounce: 0
            ),
            completionCriteria:
                .logicallyComplete
        ) {

            pageDragOffset =
                -pageHeight

        } completion: {

            finishExercisePageTransition()
        }
    }


    func finishExercisePageTransition() {

        let newIndex =
            currentExerciseIndex + 1

        guard session.workout
            .exercises
            .indices
            .contains(newIndex)
        else {

            pageDragOffset = 0
            isPageTransitioning = false

            return
        }


        // The previous animation is already finished.
        //
        // Now replace the page hierarchy without performing
        // another visual animation.
        var transaction =
            Transaction()

        transaction.animation = nil
        transaction.disablesAnimations = true


        withTransaction(transaction) {

            currentExerciseIndex =
                newIndex

            pageDragOffset = 0
        }


        // Allow SwiftUI to finish replacing A/B with B/C
        // before allowing another transition.
        Task { @MainActor in

            await Task.yield()

            isPageTransitioning = false

            activateCurrentExerciseIfNeeded(
                resetCountdown: true
            )
        }
    }
}


// MARK: - Manual Swipe Status Decision

private extension PlayView {

    func updateExerciseStatusForManualSwipe(
        _ exercise: WorkoutExercise
    ) {

        guard exercise.status == .active ||
                exercise.status == .paused else {
            return
        }

        let elapsed =
            elapsedTime(
                for: exercise
            )

        let minimumDuration =
            max(
                0,
                exercise.minDuration ?? 0
            )

        print(
            """
            Leaving exercise manually:
            \(exercise.name)
            elapsed: \(elapsed)
            minDuration: \(minimumDuration)
            """
        )

        // Requirement:
        //
        // Once the user has performed the exercise for at
        // least minDuration, count it as completed.
        //
        // Otherwise it is skipped.
        if elapsed >= minimumDuration {

            session.completeExercise(
                id: exercise.workoutExerciseId
            )

        } else {

            session.skipExercise(
                id: exercise.workoutExerciseId
            )
        }
    }


    func elapsedTime(
        for exercise: WorkoutExercise
    ) -> TimeInterval {

        let total =
            exercise.durationInSeconds
            ?? defaultExerciseDuration

        return max(
            0,
            total -
            Double(autoPlaySecondsRemaining)
        )
    }
}


// MARK: - Done Button

private extension PlayView {

    func completeButtonTapped(
        pageHeight: CGFloat
    ) {

        guard currentExercise?.status ==
                .active else {
            return
        }

        advanceToNextExercise(
            reason: .doneButton,
            pageHeight: pageHeight
        )
    }
}


// MARK: - Pause / Resume

private extension PlayView {

    func pauseCurrentExercise() {

        guard let exercise =
                currentExercise else {
            return
        }

        guard exercise.status ==
                .active else {
            return
        }

        session.pauseExercise(
            id: exercise.workoutExerciseId
        )

        // IMPORTANT:
        //
        // DO NOT RESET
        // autoPlaySecondsRemaining.
        //
        // We simply cancel the running countdown task.
        countdownGeneration += 1
    }


    func resumeCurrentExercise() {

        guard let exercise =
                currentExercise else {
            return
        }

        // MARK: Resume Workout First

        // This fixes the previous bug where resumeExercise()
        // could make the exercise active while the workout
        // remained paused.
        //
        // The countdown requires BOTH to be active.
        if session.workout.status == .paused {

            session.resumeWorkout()
        }


        // MARK: Resume Exercise

        if exercise.status == .paused {

            session.resumeExercise(
                id: exercise.workoutExerciseId
            )
        }


        // If the manager's resumeWorkout() already resumes
        // the exercise, this check prevents duplicate work.
        if currentExercise?.status == .paused {

            session.resumeExercise(
                id: exercise.workoutExerciseId
            )
        }


        // IMPORTANT:
        //
        // autoPlaySecondsRemaining is intentionally NOT
        // changed here.
        //
        // 74 seconds before pause -> resumes at 74 seconds.
        countdownGeneration += 1
    }
}


// MARK: - Countdown

private extension PlayView {

    func runExerciseCountdown() async {

        guard let exercise =
                currentExercise else {
            return
        }

        let exerciseID =
            exercise.workoutExerciseId

        // BOTH must be active.
        guard session.workout.status ==
                .active else {
            return
        }

        guard exercise.status ==
                .active else {
            return
        }


        // The countdown value is initialized when an exercise
        // becomes current. We do NOT initialize it here every
        // time the task restarts, because doing so would destroy
        // pause/resume state.
        while autoPlaySecondsRemaining > 0 {

            do {

                try await Task.sleep(
                    for: .seconds(1)
                )

            } catch {

                return
            }

            guard !Task.isCancelled else {
                return
            }

            guard session.workout.status ==
                    .active else {
                return
            }

            guard
                currentExercise?
                    .workoutExerciseId
                    == exerciseID
            else {
                return
            }

            guard currentExercise?.status ==
                    .active else {
                return
            }

            autoPlaySecondsRemaining -= 1
        }


        // MARK: Countdown Finished

        guard !Task.isCancelled else {
            return
        }

        guard session.workout.status ==
                .active else {
            return
        }

        guard
            currentExercise?
                .workoutExerciseId
                == exerciseID
        else {
            return
        }

        guard currentExercise?.status ==
                .active else {
            return
        }

        // Need geometry height to perform page transition.
        //
        // Setting this flag triggers the dedicated autoplay
        // transition through the overlay GeometryReader path.
        autoplayFinishedExerciseID =
            exerciseID
    }
}

// MARK: - Current / Next Exercise

private extension PlayView {

    var currentExercise: WorkoutExercise? {

        guard session.workout.exercises.indices.contains(
            currentExerciseIndex
        ) else {
            return nil
        }

        return session.workout.exercises[
            currentExerciseIndex
        ]
    }


    var nextExercise: WorkoutExercise? {

        let index =
            currentExerciseIndex + 1

        guard session.workout.exercises.indices.contains(
            index
        ) else {
            return nil
        }

        return session.workout.exercises[
            index
        ]
    }


    var canManuallyAdvance: Bool {

        guard !showWorkoutCompletionView else {
            return false
        }

        guard !showWorkoutStatusOverlay else {
            return false
        }

        guard !isPageTransitioning else {
            return false
        }

        guard nextExercise != nil else {
            return false
        }

        guard session.workout.status ==
                .active else {
            return false
        }

        guard currentExercise?.status ==
                .active else {
            return false
        }

        return true
    }
}


// MARK: - Initialize Workout

private extension PlayView {

    func initializeWorkout() {


        currentExerciseIndex =
            initialExerciseIndex()

        showWorkoutStatusOverlay =
            session.workout.status != .active

        initializeCountdownForCurrentExercise()

        if session.workout.status ==
            .active {

            activateCurrentExerciseIfNeeded()
        }
    }


    func initialExerciseIndex() -> Int {

        guard let currentID =
                session.workout
                    .currentWorkoutExerciseID
        else {
            return 0
        }

        return session.workout.exercises
            .firstIndex {

                $0.workoutExerciseId ==
                    currentID

            } ?? 0
    }
}


// MARK: - Activate Exercise

private extension PlayView {

    func activateCurrentExerciseIfNeeded(
        resetCountdown: Bool = false
    ) {

        guard let exercise =
                currentExercise else {
            return
        }

        session.workout
            .currentWorkoutExerciseID =
                exercise.workoutExerciseId

        if resetCountdown {

            initializeCountdownForCurrentExercise()
        }

        switch exercise.status {

        case .notStarted:

            session.startExercise(
                id: exercise.workoutExerciseId
            )

        case .paused:

            if session.workout.status ==
                .active {

                session.resumeExercise(
                    id: exercise.workoutExerciseId
                )
            }

        case .active:

            break

        case .completed,
             .skipped:

            break
        }

        countdownGeneration += 1
    }


    func initializeCountdownForCurrentExercise() {

        guard let exercise =
                currentExercise else {

            autoPlaySecondsRemaining = 0
            return
        }

        autoPlaySecondsRemaining =
            Int(
                exercise.durationInSeconds
                ?? defaultExerciseDuration
            )
    }
}


// MARK: - Workout Status Changes

private extension PlayView {

    func handleWorkoutStatusChange(
        from oldStatus: WorkoutStatus,
        to newStatus: WorkoutStatus
    ) {

        switch newStatus {

        case .active:

            activateCurrentExerciseIfNeeded()

            // Restart task using whatever countdown
            // value currently remains.
            countdownGeneration += 1

        case .paused:

            // Stop timer but preserve countdown value.
            countdownGeneration += 1

        case .completed:

            autoPlaySecondsRemaining = 0
            countdownGeneration += 1

        default:

            countdownGeneration += 1
        }
    }
}


// MARK: - App Lifecycle

private extension PlayView {

    func handleScenePhase(
        _ phase: ScenePhase
    ) {

        switch phase {

        case .active:

            break

        case .inactive,
             .background:

            if session.workout.status ==
                .active {

                session.pauseWorkout()
            }

            // Preserve timer value.
            countdownGeneration += 1

        @unknown default:

            break
        }
    }
}


// MARK: - Workout Completed

private extension PlayView {

    func handleWorkoutCompleted() {

        countdownGeneration += 1
        autoPlaySecondsRemaining = 0

        if session.workout.status !=
            .completed {

            session.completeWorkout()
        }

        withAnimation(
            .spring(
                response: 0.5,
                dampingFraction: 0.82
            )
        ) {

            showWorkoutCompletionView = true
        }
    }
}


// MARK: - Exit Workout

private extension PlayView {

    func pauseWorkoutForExit() {

        if session.workout.status ==
            .active {

            session.pauseWorkout()
        }

        countdownGeneration += 1

        // Add dismiss/navigation here.
        
        isShowingPlay = false
        
    }
}


// MARK: - Countdown Task Identity

private extension PlayView {

    struct CountdownTaskID: Equatable {

        let exerciseID: UUID?
        let workoutStatus: WorkoutStatus
        let exerciseStatus:
            WorkoutExerciseStatus?

        let generation: Int
    }
}


// MARK: - Exercise Page

struct WorkoutExercisePageView: View {

    var geometry: GeometryProxy
    let workoutExercise: WorkoutExercise
    var isWorkoutPaused: Bool

    var body: some View {

        ZStack {

            Color.black
                .ignoresSafeArea()

            if let media =
                workoutExercise.media {

                switch media.mediaType {

                case .image:

                    FullScreenImageView(
                        geometry: geometry,
                        url: media.url
                    )

                case .video:

                    FullScreenVideoView(
                        url: media.url, isActive: false //MARK: todo - not tested
                    )
                }

            } else {

                NoExerciseMediaView(
                    workoutExercise:
                        workoutExercise
                )
            }
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
        .clipped()
    }
}


// MARK: - No Media

struct NoExerciseMediaView: View {

    let workoutExercise: WorkoutExercise

    var body: some View {

        ZStack {

            Color.black

            VStack {

                Spacer()

                Image(
                    systemName:
                        "figure.strengthtraining.traditional"
                )
                .font(
                    .system(size: 70)
                )
                .foregroundStyle(
                    .white.opacity(0.7)
                )

                Text(
                    workoutExercise.name
                )
                .font(
                    .title2.bold()
                )
                .foregroundStyle(
                    .white.opacity(0.9)
                )
                .padding(.top)

                Spacer()
            }
        }
    }
}


