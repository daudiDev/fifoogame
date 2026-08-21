//
//  WorkoutSessionManager.swift
//  Learn Canvas
//
//  Created by Daudi Sagala on 8/12/26.
//
import Foundation
import Observation


@MainActor
@Observable
final class WorkoutSessionManager {

    static let shared = WorkoutSessionManager()

    private let socketManager = SocketManager.shared

    private let pedometer = PedometerManager.shared

    private let voiceManager = WorkoutVoiceManager.shared

    // MARK: - Workout

    /// SocketManager owns the workout.
    ///
    /// WorkoutSessionManager only performs business
    /// logic against that workout.
    var workout: Workout {

        get {
            socketManager.workout
        }

        set {
            socketManager.workout =
                newValue
        }
    }


    private init() {}
}


// MARK: - Load / Clear

extension WorkoutSessionManager {

    func loadWorkout(
        _ workout: Workout
    ) {

        socketManager.workout =
            workout
    }


    func clearWorkout() {

        socketManager.workout =
            Workout(
                id: UUID(),
                name: "",
                description: "",
                exercises: [],
                status: .notStarted,
                startedAt: nil,
                endedAt: nil,
                pausedAt: nil,
                resumedAt: nil,
                pausePeriods: [],
                currentWorkoutExerciseID: nil,
                createdAt: Date(),
                updatedAt: Date()
            )
    }
}


// MARK: - Start Workout

extension WorkoutSessionManager {

    func startWorkout() {

        var updatedWorkout =
            socketManager.workout

        guard updatedWorkout.status ==
                .notStarted
        else {
            return
        }

        let now = Date()

        updatedWorkout.status =
            .active

        updatedWorkout.startedAt =
            now

        updatedWorkout.updatedAt =
            now

        if updatedWorkout
            .currentWorkoutExerciseID == nil {

            updatedWorkout
                .currentWorkoutExerciseID =
                    updatedWorkout
                        .exercises
                        .first?
                        .workoutExerciseId
        }

        let exerciseID =
            updatedWorkout
                .currentWorkoutExerciseID

        socketManager.workout =
            updatedWorkout

        if let exerciseID {

            startExercise(
                id: exerciseID
            )
        }
    }
}


// MARK: - Pause Workout

extension WorkoutSessionManager {

    func pauseWorkout() {

        var updatedWorkout =
            socketManager.workout

        guard updatedWorkout.status ==
                .active
        else {
            return
        }

        let now = Date()

        let exerciseID =
            updatedWorkout
                .currentWorkoutExerciseID

        updatedWorkout.status =
            .paused

        updatedWorkout.pausedAt =
            now

        updatedWorkout.updatedAt =
            now

        updatedWorkout
            .pausePeriods
            .append(
                WorkoutPausePeriod(
                    startedAt: now
                )
            )

        socketManager.workout =
            updatedWorkout
        
        // MARK: - Voice
            voiceManager.speak(
                "Workout paused."
            )

        if let exerciseID {

            pauseExercise(
                id: exerciseID
            )
        }
    }
}


// MARK: - Resume Workout

extension WorkoutSessionManager {

    func resumeWorkout() {

        var updatedWorkout =
            socketManager.workout

        guard updatedWorkout.status ==
                .paused
        else {
            return
        }

        let now = Date()

        updatedWorkout.status =
            .active

        updatedWorkout.resumedAt =
            now

        updatedWorkout.updatedAt =
            now

        if let index =
                updatedWorkout
                    .pausePeriods
                    .indices
                    .last,
           updatedWorkout
                .pausePeriods[index]
                .endedAt == nil {

            updatedWorkout
                .pausePeriods[index]
                .endedAt =
                    now
        }

        let exerciseID =
            updatedWorkout
                .currentWorkoutExerciseID

        socketManager.workout =
            updatedWorkout
        
        
        // MARK: - Voice

        voiceManager.speak(
            "Workout resumed."
        )

        if let exerciseID {

            resumeExercise(
                id: exerciseID
            )
        }
    }
}


// MARK: - End / Complete Workout

extension WorkoutSessionManager {

    func endWorkout() {

        var updatedWorkout =
            socketManager.workout

        guard updatedWorkout.status !=
                .ended,
              updatedWorkout.status !=
                .completed
        else {
            return
        }

        if let id =
                updatedWorkout
                    .currentWorkoutExerciseID,
           let index =
                exerciseIndex(
                    for: id,
                    in: updatedWorkout
                ),
           updatedWorkout
                .exercises[index]
                .status ==
                .active,
           updatedWorkout
                .exercises[index]
                .tracksSteps {

            savePedometerSegment(
                toExerciseAt: index,
                workout:
                    &updatedWorkout
            )

            pedometer.stopTracking()
        }

        let now = Date()

        updatedWorkout.status =
            .ended

        updatedWorkout.endedAt =
            now

        updatedWorkout.updatedAt =
            now

        socketManager.workout =
        updatedWorkout
        
        // MARK: - Voice
        voiceManager.speak(
               """
               You have completed \(updatedWorkout.name).
               """,
               interruptCurrentSpeech: false
        )
        
    }


    func completeWorkout() {

        var updatedWorkout =
            socketManager.workout

        let now = Date()

        updatedWorkout.status =
            .completed

        updatedWorkout.endedAt =
            now

        updatedWorkout.updatedAt =
            now

        socketManager.workout = updatedWorkout
        
        // MARK: - Voice
        voiceManager.speak(
               """
               You have completed \(updatedWorkout.name).
               """,
               interruptCurrentSpeech: false
        )
        
    }
}


// MARK: - Start Exercise

extension WorkoutSessionManager {

    func startExercise(
        id: UUID
    ) {

        var updatedWorkout =
            socketManager.workout

        guard let index =
                exerciseIndex(
                    for: id,
                    in: updatedWorkout
                )
        else {
            return
        }

        guard updatedWorkout
            .exercises[index]
            .status ==
                .notStarted
        else {
            return
        }

        let now = Date()

        updatedWorkout
            .exercises[index]
            .status =
                .active

        updatedWorkout
            .exercises[index]
            .startedAt =
                now

        updatedWorkout
            .currentWorkoutExerciseID =
                id

        updatedWorkout.updatedAt =
            now

        socketManager.workout =
            updatedWorkout
        
        
        // MARK: Voice

        let exercise =
            updatedWorkout.exercises[index]

        voiceManager.speak(
            "Starting \(exercise.name). \(exercise.description ?? " ")"
        )

        if updatedWorkout
            .exercises[index]
            .tracksSteps {

            pedometer.startTracking(
                from: now
            )
        }
        
        
        
    }
}


// MARK: - Pause Exercise

extension WorkoutSessionManager {

    func pauseExercise(
        id: UUID
    ) {

        var updatedWorkout =
            socketManager.workout

        guard let index =
                exerciseIndex(
                    for: id,
                    in: updatedWorkout
                )
        else {
            return
        }

        guard updatedWorkout
            .exercises[index]
            .status ==
                .active
        else {
            return
        }

        let now = Date()

        if updatedWorkout
            .exercises[index]
            .tracksSteps {

            savePedometerSegment(
                toExerciseAt: index,
                workout:
                    &updatedWorkout
            )

            pedometer.stopTracking()
        }

        updatedWorkout
            .exercises[index]
            .status =
                .paused

        updatedWorkout
            .exercises[index]
            .pausedAt =
                now

        updatedWorkout
            .exercises[index]
            .pausePeriods
            .append(
                WorkoutExercisePausePeriod(
                    startedAt: now
                )
            )

        updatedWorkout.updatedAt =
            now

        socketManager.workout =
            updatedWorkout
        
        // MARK: Voice
        
        let exercise =
        updatedWorkout.exercises[index]
        
        voiceManager.speak(
            "\(exercise.name) paused."
        )
        
    }
}


// MARK: - Resume Exercise

extension WorkoutSessionManager {

    func resumeExercise(
        id: UUID
    ) {

        var updatedWorkout =
            socketManager.workout

        guard let index =
                exerciseIndex(
                    for: id,
                    in: updatedWorkout
                )
        else {
            return
        }

        guard updatedWorkout
            .exercises[index]
            .status ==
                .paused
        else {
            return
        }

        let now = Date()

        updatedWorkout
            .exercises[index]
            .status =
                .active

        updatedWorkout
            .exercises[index]
            .resumedAt =
                now

        if let pauseIndex =
                updatedWorkout
                    .exercises[index]
                    .pausePeriods
                    .indices
                    .last,
           updatedWorkout
                .exercises[index]
                .pausePeriods[pauseIndex]
                .endedAt == nil {

            updatedWorkout
                .exercises[index]
                .pausePeriods[pauseIndex]
                .endedAt =
                    now
        }

        updatedWorkout
            .currentWorkoutExerciseID =
                id

        updatedWorkout.updatedAt =
            now

        socketManager.workout =
            updatedWorkout
        
        
        // MARK: Voice

        let exercise =
            updatedWorkout.exercises[index]

        voiceManager.speak(
            "Resuming \(exercise.name)."
        )

        if updatedWorkout
            .exercises[index]
            .tracksSteps {

            pedometer.startTracking(
                from: now
            )
        }
    }
}


// MARK: - Complete Exercise

extension WorkoutSessionManager {

    func completeExercise(
        id: UUID
    ) {

        var updatedWorkout =
            socketManager.workout

        guard let index =
                exerciseIndex(
                    for: id,
                    in: updatedWorkout
                )
        else {
            return
        }

        let now = Date()

        if updatedWorkout
            .exercises[index]
            .tracksSteps,
           updatedWorkout
            .exercises[index]
            .status ==
                .active {

            savePedometerSegment(
                toExerciseAt: index,
                workout:
                    &updatedWorkout
            )

            pedometer.stopTracking()
        }

        updatedWorkout
            .exercises[index]
            .status =
                .completed

        updatedWorkout
            .exercises[index]
            .completedAt =
                now

        updatedWorkout.updatedAt =
            now

        finishWorkoutIfNeeded(
            workout:
                &updatedWorkout,
            at: now
        )

        socketManager.workout =
            updatedWorkout
        
    }
}


// MARK: - Skip Exercise

extension WorkoutSessionManager {

    func skipExercise(
        id: UUID
    ) {

        var updatedWorkout =
            socketManager.workout

        guard let index =
                exerciseIndex(
                    for: id,
                    in: updatedWorkout
                )
        else {
            return
        }

        let now = Date()

        if updatedWorkout
            .exercises[index]
            .tracksSteps,
           updatedWorkout
            .exercises[index]
            .status ==
                .active {

            savePedometerSegment(
                toExerciseAt: index,
                workout:
                    &updatedWorkout
            )

            pedometer.stopTracking()
        }

        updatedWorkout
            .exercises[index]
            .status =
                .skipped

        updatedWorkout
            .exercises[index]
            .completedAt =
                nil

        updatedWorkout.updatedAt =
            now

        finishWorkoutIfNeeded(
            workout:
                &updatedWorkout,
            at: now
        )

        socketManager.workout =
            updatedWorkout
        
    }
}


// MARK: - Progress

extension WorkoutSessionManager {

    func workoutProgress() -> Double {

        let workout =
            socketManager.workout

        guard !workout
            .exercises
            .isEmpty
        else {
            return 0
        }

        let finished =
            workout
                .exercises
                .filter {

                    $0.status ==
                        .completed
                    ||
                    $0.status ==
                        .skipped
                }
                .count

        return Double(finished)
            / Double(
                workout.exercises.count
            )
    }
}


// MARK: - Helpers

private extension WorkoutSessionManager {

    func exerciseIndex(
        for id: UUID,
        in workout: Workout
    ) -> Int? {

        workout
            .exercises
            .firstIndex {

                $0.workoutExerciseId ==
                    id
            }
    }


    func finishWorkoutIfNeeded(
        workout: inout Workout,
        at date: Date
    ) {

        let allFinished =
            workout
                .exercises
                .allSatisfy {

                    $0.status ==
                        .completed
                    ||
                    $0.status ==
                        .skipped
                }

        guard allFinished else {
            return
        }

        workout.status =
            .completed

        workout.endedAt =
            date

        workout.updatedAt =
            date
        
        // MARK: - Voice
        voiceManager.speak(
               """
               You have completed \(workout.name).
               Preparing the workout summary.
               """,
               interruptCurrentSpeech: false
        )
        
    }


    func savePedometerSegment(
        toExerciseAt index: Int,
        workout: inout Workout
    ) {

        guard workout
            .exercises
            .indices
            .contains(index)
        else {
            return
        }

        let snapshot =
            pedometer.snapshot


        // Steps

        workout
            .exercises[index]
            .stepsCompleted +=
                snapshot.steps


        // Distance

        workout
            .exercises[index]
            .pedometerDistanceMeters +=
                snapshot.distanceMeters


        // Floors

        workout
            .exercises[index]
            .floorsAscended +=
                snapshot.floorsAscended

        workout
            .exercises[index]
            .floorsDescended +=
                snapshot.floorsDescended


        // Cadence

        if let cadence =
            snapshot.cadence {

            workout
                .exercises[index]
                .averageCadence =
                    cadence
        }


        // Pace

        if let pace =
            snapshot.pace {

            workout
                .exercises[index]
                .averagePace =
                    pace
        }


        // Workout totals

        workout.totalSteps +=
            snapshot.steps

        workout
            .totalPedometerDistanceMeters +=
                snapshot.distanceMeters

        workout
            .totalFloorsAscended +=
                snapshot.floorsAscended

        workout
            .totalFloorsDescended +=
                snapshot.floorsDescended
    }
}

private extension WorkoutSessionManager {

    func speakWorkoutStarted(
        _ workout: Workout
    ) {

        var speech =
            "Starting \(workout.name)."

        let description =
        workout.description?
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

        if ((description?.isEmpty) == nil) {

            speech +=
            " \(description ?? "Enjoy!") "
        }

        voiceManager.speak(
            speech
        )
    }
}

