//
//  PlayOverlay.swift
//  Fifoo Play
//
//  Created by Daudi Sagala on 8/11/26.
//


import SwiftUI

// MARK: - Play Overlay

struct PlayOverlay: View {
    
    private let socketManager = SocketManager.shared
    private let pedometer = PedometerManager.shared

    let geometry: GeometryProxy
    let workoutExercise: WorkoutExercise

    let autoPlaySecondsRemaining: Int

    let onCompleteExercise: () -> Void
    let onPauseExercise: () -> Void
    let onResumeExercise: () -> Void
    let onExitWorkout: () -> Void

    @State private var showProgressView = false
    
    @State private var showInstructionsView = false
    
    let liveMessages: [WorkoutLiveMessage]
    
    // MARK: Mood Emoji
    @State private var showEmojiPicker = false

    var body: some View {

        VStack(spacing: 0) {

            // MARK: Header

            header

            // MARK: Exercise Details

            exerciseDetails

            Spacer()

            // MARK: Controls
            instructionsButton
            
            Spacer()
            
            WorkoutLiveOverlay( geometry: geometry, messages: liveMessages)

            
            bottomControls
            
        }
        .padding(.top, 50)
        .padding(.bottom)
        .frame(
            width: geometry.size.width,
            height: geometry.size.height
        )
        .allowsHitTesting(true)
    }
}


// MARK: - Header

private extension PlayOverlay {

    var header: some View {

        HStack(spacing: 12) {
            
            // MARK: Voice Mute / Unmute
            voiceMuteButton
            
            Spacer()

            Text(
                workoutExercise.name
            )
            .font(.title)
            .fontWeight(.heavy)
            .foregroundStyle(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .shadow(
                color: .black.opacity(0.25),
                radius: 2,
                x: 0,
                y: 1
            )

            Spacer()

            Button {

                onExitWorkout()

            } label: {

                Image(
                    systemName: "xmark"
                )
                .font(
                    .system(
                        size: 21,
                        weight: .bold
                    )
                )
                .foregroundStyle(.red)
                .frame(
                    width: 44,
                    height: 44
                )
                .background(
                    Circle()
                        .fill(
                            .ultraThickMaterial
                        )
                )
                .shadow(
                    color:
                        .black.opacity(0.3),
                    radius: 2,
                    x: 1,
                    y: 1
                )
            }
        }
        .padding(.horizontal, 25)
        .padding(.bottom, 16)
    }
}


// MARK: - Exercise Details

private extension PlayOverlay {

    var exerciseDetails: some View {

        ScrollView(
            .horizontal,
            showsIndicators: false
        ) {

            HStack(
                alignment: .center,
                spacing: 12
            ) {

                // MARK: Countdown

                AutoPlayCountdownCard(
                    secondsRemaining:
                        autoPlaySecondsRemaining,
                    isPaused: isPaused,
                    width:
                        geometry.size.width
                        * 0.23
                )


                // MARK: Steps

                if workoutExercise.tracksSteps {

                    ExerciseDetailCard(
                        title: "STEPS",
                        value:
                            "\(liveExerciseSteps)",
                        unit: stepsUnit,
                        width:
                            geometry.size.width
                            * 0.20
                    )


                    // MARK: Covered Distance

                    ExerciseDetailCard(
                        title: "COVERED",
                        value:
                            formattedPedometerMiles,
                        unit: "mi",
                        width:
                            geometry.size.width
                            * 0.20
                    )
                }


                // MARK: Reps

                if let reps =
                    workoutExercise.reps {

                    ExerciseDetailCard(
                        title: "REPS",
                        value: "\(reps)",
                        unit:
                            reps == 1
                            ? "rep"
                            : "reps",
                        width:
                            geometry.size.width
                            * 0.20
                    )
                }


                // MARK: Distance Goal

                if let distance =
                    workoutExercise.distance,
                   let unit =
                    workoutExercise.distanceUnit {

                    ExerciseDetailCard(
                        title: "GOAL",
                        value:
                            formatNumber(
                                distance
                            ),
                        unit: unit.rawValue,
                        width:
                            geometry.size.width
                            * 0.20
                    )
                }


                // MARK: Duration

                if let duration =
                    workoutExercise.duration,
                   let unit =
                    workoutExercise.durationUnit {

                    ExerciseDetailCard(
                        title: "DURATION",
                        value:
                            formatNumber(
                                duration
                            ),
                        unit: unit.rawValue,
                        width:
                            geometry.size.width
                            * 0.20
                    )
                }


                // MARK: Weight

                if let weight =
                    workoutExercise.weight {

                    ExerciseDetailCard(
                        title: "WEIGHT",
                        value:
                            formatNumber(
                                weight
                            ),
                        unit: "lbs",
                        width:
                            geometry.size.width
                            * 0.20
                    )
                }


                // MARK: Equipment

                if !workoutExercise
                    .equipment.isEmpty,
                   workoutExercise
                    .equipment != [.none] {

                    EquipmentDetailCard(
                        equipment:
                            workoutExercise
                                .equipment,
                        width:
                            geometry.size.width
                            * 0.28
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom)
        }
    }
}

// MARK: - Instructions Button
private extension PlayOverlay {
    
    var instructionsButton: some View {
        
        VStack {
            // MARK: Instructions
            
            if hasInstructions {
                
                VStack(alignment: .center, spacing: 5) {
                    
                    Text("New to \(workoutExercise.name)?")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .shadow(
                            color: .black.opacity(0.25),
                            radius: 2,
                            x: 0,
                            y: 1
                        )
                    
                    HStack {
                        
                        Spacer()
                        
                        Button {
                            
                            onPauseExercise()
                            showInstructionsView = true
                            
                        } label: {
                            
                            HStack {
                                Text("View Demo")
                                    .font(.system( size: 18, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                            .padding(10)
                            .padding(.horizontal, 25)
                            .background(RoundedRectangle(cornerRadius: 10).fill(.blue).shadow(color:.black.opacity(0.3), radius: 1, x: 1, y: 1))
                            
                                
                            
                        }
                        .sheet(
                            isPresented:
                                $showInstructionsView
                        ) {
                            
                            if let instructions =
                                workoutExercise.instructions {
                                
                                ExerciseInstructionsView(
                                    exerciseName:
                                        workoutExercise.name,
                                    instructions:
                                        instructions
                                )
                                .onDisappear {
                                    
                                    onResumeExercise()
                                    
                                }
                            }
                        }
                        
                        Spacer()
                    }
                    
                }//vs
                
            } //iff
            
        }
        
    }
    
    var hasInstructions: Bool {
        
        guard let instructions =
                workoutExercise.instructions else {
            return false
        }
        
        return instructions.demoVideoURL != nil || !instructions.steps.isEmpty
    }
    
}


// MARK: - Bottom Controls

private extension PlayOverlay {

    var bottomControls: some View {

        HStack(
            alignment: .center,
            spacing: 25
        ) {

            // MARK: Progress

            Button {

                showProgressView = true

            } label: {

                WorkoutCircularProgressBar(
                    progress:
                        socketManager.workoutProgress()
                )
            }
            .sheet(
                isPresented:
                    $showProgressView
            ) {

                WorkoutProgressReportView(
                    showProgressView:
                        $showProgressView
                )
            }


            // MARK: Exercise Controls

            exerciseControl
            
            emojiButton
            
        }
        .padding(.horizontal)
    }


    @ViewBuilder
    var exerciseControl: some View {

        switch workoutExercise.status {

        case .completed:

            statusButton(
                title: "COMPLETED",
                foregroundColor: .white,
                backgroundColor:
                    .gray.opacity(0.75)
            )


        case .skipped:

            statusButton(
                title: "SKIPPED",
                foregroundColor: .white,
                backgroundColor:
                    .orange.opacity(0.8)
            )


        case .paused:

            resumeButton


        case .active:

            // IMPORTANT:
            //
            // The workout itself may be paused while the
            // exercise model still reports .active.
            if socketManager.workout.status ==
                .paused {

                resumeButton

            } else {

                activeControls
            }


        case .notStarted:

            if socketManager.workout.status ==
                .paused {

                resumeButton

            } else {

                EmptyView()
            }
        }
    }
}


// MARK: - Active Controls

private extension PlayOverlay {

    var activeControls: some View {

        HStack(spacing: 20) {

            Button {

                onCompleteExercise()

            } label: {

                controlButtonLabel(
                    title: "DONE",
                    foregroundColor: .blue,
                    width: 100
                )
            }


            Button {

                onPauseExercise()

            } label: {

                controlButtonLabel(
                    title: "PAUSE",
                    foregroundColor: .blue,
                    width: 100
                )
            }
        }
    }


    var resumeButton: some View {

        Button {

            onResumeExercise()

        } label: {

            controlButtonLabel(
                title: "RESUME",
                foregroundColor: .orange,
                width: 200
            )
        }
    }
}


// MARK: - Button Appearance

private extension PlayOverlay {

    func controlButtonLabel(
        title: String,
        foregroundColor: Color,
        width: CGFloat
    ) -> some View {

        Text(title)
            .font(
                .system(
                    size: 24,
                    weight: .heavy,
                    design: .rounded
                )
            )
            .foregroundStyle(
                foregroundColor
            )
            .frame(
                width: width,
                height: 40
            )
            .padding(7)
            .background(
                RoundedRectangle(
                    cornerRadius: 20
                )
                .fill(
                    .ultraThickMaterial
                )
                .shadow(
                    color:
                        .black.opacity(0.3),
                    radius: 1,
                    x: 1,
                    y: 1
                )
            )
    }


    func statusButton(
        title: String,
        foregroundColor: Color,
        backgroundColor: Color
    ) -> some View {

        Text(title)
            .font(
                .system(
                    size: 24,
                    weight: .heavy,
                    design: .rounded
                )
            )
            .foregroundStyle(
                foregroundColor
            )
            .frame(
                width: 200,
                height: 40
            )
            .padding(7)
            .background(
                RoundedRectangle(
                    cornerRadius: 20
                )
                .fill(
                    backgroundColor
                )
                .shadow(
                    color:
                        .black.opacity(0.3),
                    radius: 1,
                    x: 1,
                    y: 1
                )
            )
    }
}


// MARK: - Pause State

private extension PlayOverlay {

    var isPaused: Bool {

        workoutExercise.status == .paused
        ||
        socketManager.workout.status == .paused
    }
}


// MARK: - Steps

private extension PlayOverlay {

    var liveExerciseSteps: Int {

        if workoutExercise.status ==
            .active,
           socketManager.workout.status ==
            .active {

            return
                workoutExercise
                    .stepsCompleted
                +
                pedometer.steps
        }

        return workoutExercise
            .stepsCompleted
    }


    var stepsUnit: String {

        if let target =
            workoutExercise.targetSteps {

            return "of \(target)"
        }

        return "steps"
    }
}


// MARK: - Pedometer Distance

private extension PlayOverlay {

    var livePedometerDistanceMeters: Double {

        if workoutExercise.status ==
            .active,
           socketManager.workout.status ==
            .active {

            return
                workoutExercise
                    .pedometerDistanceMeters
                +
                pedometer.distanceMeters
        }

        return workoutExercise
            .pedometerDistanceMeters
    }


    var livePedometerDistanceMiles: Double {

        livePedometerDistanceMeters
        / 1609.344
    }


    var formattedPedometerMiles: String {

        livePedometerDistanceMiles
            .formatted(
                .number.precision(
                    .fractionLength(2)
                )
            )
    }
}


// MARK: - Number Formatting

private extension PlayOverlay {

    func formatNumber(
        _ number: Double
    ) -> String {

        if number
            .truncatingRemainder(
                dividingBy: 1
            ) == 0 {

            return String(
                Int(number)
            )
        }

        return number.formatted(
            .number.precision(
                .fractionLength(0...1)
            )
        )
    }
}


// MARK: - Auto Play Countdown Card

struct AutoPlayCountdownCard: View {

    let secondsRemaining: Int
    let isPaused: Bool
    let width: CGFloat

    var body: some View {

        VStack(
            alignment: .center,
            spacing: 0
        ) {

            HStack(spacing: 4) {

                if isPaused {

                    Image(
                        systemName:
                            "pause.fill"
                    )
                    .font(
                        .system(
                            size: 9,
                            weight: .bold
                        )
                    )
                }

                Text(
                    isPaused
                    ? "PAUSED"
                    : "COUNTDOWN"
                )
                .font(
                    .system(
                        size: 10,
                        weight: .bold,
                        design: .rounded
                    )
                )
            }
            .foregroundStyle(.white)
            .padding(
                .vertical,
                4
            )
            .padding(
                .horizontal,
                9
            )
            .background(
                Capsule()
                    .fill(
                        .black.opacity(
                            0.35
                        )
                    )
            )


            Text(formattedTime)
                .font(
                    .system(
                        size:
                            countdownFontSize,
                        weight: .black,
                        design: .rounded
                    )
                )
                .monospacedDigit()
                .foregroundStyle(.white)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .padding(.top, 5)
                .padding(.bottom, -5)


            Text(timeUnitText)
                .font(
                    .system(
                        size: 12,
                        weight: .bold,
                        design: .rounded
                    )
                )
                .foregroundStyle(
                    .white.opacity(0.85)
                )
        }
        .frame(width: width)
        .padding()
        .background(
            RoundedRectangle(
                cornerRadius: 15
            )
            .fill(
                isPaused
                ? .orange
                : .green
            )
            .shadow(
                color:
                    .black.opacity(0.3),
                radius: 1,
                x: 1,
                y: 1
            )
        )
    }


    private var formattedTime: String {

        let seconds =
            max(
                0,
                secondsRemaining
            )

        let hours =
            seconds / 3600

        let minutes =
            (seconds % 3600)
            / 60

        let remainingSeconds =
            seconds % 60

        if hours > 0 {

            return String(
                format:
                    "%d:%02d:%02d",
                hours,
                minutes,
                remainingSeconds
            )
        }

        if minutes > 0 {

            return String(
                format:
                    "%02d:%02d",
                minutes,
                remainingSeconds
            )
        }

        return "\(remainingSeconds)"
    }


    private var timeUnitText: String {

        let seconds =
            max(
                0,
                secondsRemaining
            )

        if seconds >= 3600 {

            return "h : min : sec"
        }

        if seconds >= 60 {

            return "min : sec"
        }

        return "sec"
    }


    private var countdownFontSize: CGFloat {

        let seconds =
            max(
                0,
                secondsRemaining
            )

        if seconds >= 3600 {
            return 30
        }

        if seconds >= 60 {
            return 36
        }

        return 44
    }
}


// MARK: - Exercise Detail Card

struct ExerciseDetailCard: View {

    let title: String
    let value: String
    let unit: String
    let width: CGFloat

    var body: some View {

        VStack(
            alignment: .center,
            spacing: 0
        ) {

            Text(title)
                .font(
                    .system(
                        size: 12,
                        weight: .bold,
                        design: .rounded
                    )
                )
                .foregroundStyle(.white)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .padding(
                    .vertical,
                    3
                )
                .padding(
                    .horizontal,
                    8
                )
                .background(
                    RoundedRectangle(
                        cornerRadius: 10
                    )
                    .fill(.gray)
                )


            Text(value)
                .font(
                    .system(
                        size: 42,
                        weight: .heavy,
                        design: .rounded
                    )
                )
                .foregroundStyle(.gray)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .padding(
                    .bottom,
                    -7
                )


            Text(unit)
                .font(
                    .system(
                        size: 14,
                        weight: .bold,
                        design: .rounded
                    )
                )
                .foregroundStyle(.gray)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
        }
        .frame(width: width)
        .padding()
        .background(
            RoundedRectangle(
                cornerRadius: 15
            )
            .fill(
                .ultraThickMaterial
            )
            .shadow(
                color:
                    .black.opacity(0.3),
                radius: 1,
                x: 1,
                y: 1
            )
        )
    }
}


// MARK: - Equipment Detail Card

struct EquipmentDetailCard: View {

    let equipment: [Equipment]
    let width: CGFloat

    var body: some View {

        VStack(
            alignment: .center,
            spacing: 8
        ) {

            Text("EQUIPMENT")
                .font(
                    .system(
                        size: 12,
                        weight: .bold,
                        design: .rounded
                    )
                )
                .foregroundStyle(.white)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .padding(
                    .vertical,
                    3
                )
                .padding(
                    .horizontal,
                    8
                )
                .background(
                    RoundedRectangle(
                        cornerRadius: 10
                    )
                    .fill(.gray)
                )


            Image(
                systemName:
                    "dumbbell.fill"
            )
            .font(
                .system(size: 30)
            )
            .foregroundStyle(.gray)


            Text(
                equipment
                    .map {
                        $0.rawValue
                    }
                    .joined(
                        separator: ", "
                    )
            )
            .font(
                .system(
                    size: 14,
                    weight: .bold,
                    design: .rounded
                )
            )
            .foregroundStyle(.gray)
            .minimumScaleFactor(0.5)
            .lineLimit(1)
        }
        .frame(width: width)
        .padding()
        .background(
            RoundedRectangle(
                cornerRadius: 15
            )
            .fill(
                .ultraThickMaterial
            )
            .shadow(
                color:
                    .black.opacity(0.3),
                radius: 1,
                x: 1,
                y: 1
            )
        )
    }
}

// MARK: - Emoji Button

private extension PlayOverlay {

    var emojiButton: some View {

        Button {

            showEmojiPicker = true

        } label: {

            VStack(
                spacing: 2
            ) {

                Image(
                    systemName:
                        "face.smiling.fill"
                )
                .font(
                    .system(
                        size: 24,
                        weight: .bold
                    )
                )

                Text("MOOD")
                    .font(
                        .system(
                            size: 9,
                            weight: .bold
                        )
                    )
            }
            .foregroundStyle(.orange)
            .frame(
                width: 54,
                height: 54
            )
            .background {

                Circle()
                    .fill(
                        .ultraThickMaterial
                    )
                    .shadow(
                        color:
                            .black.opacity(0.3),
                        radius: 2,
                        x: 1,
                        y: 1
                    )
            }
        }
        .popover(
            isPresented:
                $showEmojiPicker,
            arrowEdge:
                .bottom
        ) {

            WorkoutMoodEmojiPicker { emoji in

                sendMoodReaction(
                    emoji
                )

                showEmojiPicker =
                    false
            }
            .presentationCompactAdaptation(
                .popover
            )
        }
    }
}


// MARK: - Live Reaction
private extension PlayOverlay {

    func sendMoodReaction(
        _ emoji: String
    ) {

        socketManager.sendWorkoutReaction(
            emoji: emoji
        )
    }
}

// MARK: - Voice Mute Button

private extension PlayOverlay {

    var voiceMuteButton: some View {

        Button {

            socketManager.toggleWorkoutVoiceMute()

        } label: {

            Image(
                systemName:
                    socketManager.isWorkoutVoiceMuted
                    ? "speaker.slash.fill"
                    : "speaker.wave.2.fill"
            )
            .font(
                .system(
                    size: 21,
                    weight: .bold
                )
            )
            .foregroundStyle(
                socketManager.isWorkoutVoiceMuted
                ? .gray
                : .blue
            )
            .frame(
                width: 44,
                height: 44
            )
            .background {

                Circle()
                    .fill(
                        .ultraThickMaterial
                    )
                    .shadow(
                        color:
                            .black.opacity(0.3),
                        radius: 2,
                        x: 1,
                        y: 1
                    )
            }
        }

        // Accessibility

        .accessibilityLabel(
            socketManager.isWorkoutVoiceMuted
            ? "Unmute workout voice"
            : "Mute workout voice"
        )
    }
}
