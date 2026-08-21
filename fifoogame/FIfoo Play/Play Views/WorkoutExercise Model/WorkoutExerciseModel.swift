//
//  WorkoutExerciseModel.swift
//  Learn Canvas
//
//  Created by Daudi Sagala on 8/11/26.
//

import Foundation
import SwiftUI

// MARK: - Workout Exercise
struct WorkoutExercise: Identifiable, Codable, Hashable {
    
    var id: UUID {
        workoutExerciseId
    }
    
    let exerciseId: UUID
    let workoutExerciseId: UUID
    
    var name: String
    
    var media: ExerciseMedia?
    
    var exerciseCategory: ExerciseCategory
    var equipment: [Equipment]
    
    var sets: Int?
    var reps: Int?
    
    var duration: Double?
    var durationUnit: DurationUnit?
    
    // Minimum number of seconds the user should perform this exercise
    // before a swipe asks whether it was completed or skipped.
    var minDuration: TimeInterval?
    
    var distance: Double?
    var distanceUnit: DistanceUnit?
    
    var status: WorkoutExerciseStatus
    
    var weight: Double?
    
    // MARK: - Pedometer / Step Tracking
     
     /// Whether this exercise should collect pedometer data.
     var tracksSteps: Bool
     
     /// Optional prescribed step goal.
     var targetSteps: Int?
     
     /// Actual steps recorded during this exercise.
     var stepsCompleted: Int
     
     /// Distance reported by the pedometer for this exercise.
     /// Store internally in meters for consistency.
     var pedometerDistanceMeters: Double
     
     /// Floors climbed during the exercise, if available.
     var floorsAscended: Int
     
     /// Floors descended during the exercise, if available.
     var floorsDescended: Int
     
     /// Current/average cadence, if you choose to persist it.
     /// Steps per minute.
     var averageCadence: Double?
     
     /// Average walking/running pace.
     /// Seconds per meter, matching CMPedometer semantics.
     var averagePace: Double?
    
    
    // MARK: - Exercise Lifecycle
    
    var startedAt: Date?
    var pausedAt: Date?
    var resumedAt: Date?
    var completedAt: Date?
    
    var pausePeriods: [WorkoutExercisePausePeriod]

    var instructions: ExerciseInstructions?
    
    var isWorkoutBreak: Bool?
    
    var description: String?
    
    init(
        exerciseId: UUID,
        workoutExerciseId: UUID = UUID(),
        name: String,
        media: ExerciseMedia? = nil,
        exerciseCategory: ExerciseCategory,
        equipment: [Equipment] = [],
        sets: Int? = nil,
        reps: Int? = nil,
        duration: Double? = nil,
        durationUnit: DurationUnit? = nil,
        minDuration: TimeInterval? = nil,
        distance: Double? = nil,
        distanceUnit: DistanceUnit? = nil,
        status: WorkoutExerciseStatus = .notStarted,
        weight: Double? = nil,
        tracksSteps: Bool = false,
        targetSteps: Int? = nil,
        stepsCompleted: Int = 0,
        pedometerDistanceMeters: Double = 0,
        floorsAscended: Int = 0,
        floorsDescended: Int = 0,
        averageCadence: Double? = nil,
        averagePace: Double? = nil,
        startedAt: Date? = nil,
        pausedAt: Date? = nil,
        resumedAt: Date? = nil,
        completedAt: Date? = nil,
        pausePeriods: [WorkoutExercisePausePeriod] = [],
        instructions: ExerciseInstructions? = nil,
        isWorkoutBreak: Bool? = nil,
        description: String? = nil
        
    ) {
        self.exerciseId = exerciseId
        self.workoutExerciseId = workoutExerciseId
        self.name = name
        self.media = media
        self.exerciseCategory = exerciseCategory
        self.equipment = equipment
        self.sets = sets
        self.reps = reps
        self.duration = duration
        self.durationUnit = durationUnit
        self.minDuration = minDuration
        self.distance = distance
        self.distanceUnit = distanceUnit
        self.status = status
        self.weight = weight
        self.tracksSteps = tracksSteps
        self.targetSteps = targetSteps
        self.stepsCompleted = stepsCompleted
        self.pedometerDistanceMeters = pedometerDistanceMeters
        self.floorsAscended = floorsAscended
        self.floorsDescended = floorsDescended
        self.averageCadence = averageCadence
        self.averagePace = averagePace
        self.startedAt = startedAt
        self.pausedAt = pausedAt
        self.resumedAt = resumedAt
        self.completedAt = completedAt
        self.pausePeriods = pausePeriods
        self.instructions = instructions
        self.isWorkoutBreak = isWorkoutBreak
        self.description = description
        
    }
}


// MARK: - Exercise Media

struct ExerciseMedia: Codable, Hashable {
    
    var mediaType: MediaType
    var url: URL
    
    enum MediaType: String, Codable, CaseIterable {
        case image
        case video
    }
}

// MARK: - Workout Exercise Status

enum WorkoutExerciseStatus: String, Codable, CaseIterable {
    case active = "Active"
    case notStarted = "Not Started"
    case paused = "Paused"
    case completed = "Completed"
    case skipped = "Skipped"
}

// MARK: - Duration Unit

enum DurationUnit: String, Codable, CaseIterable {
    case seconds
    case minutes
    case hours
}

extension WorkoutExercise {
    
    var durationInSeconds: TimeInterval? {
        
        guard let duration else {
            return nil
        }
        
        switch durationUnit {
            
        case .seconds:
            return duration
            
        case .minutes:
            return duration * 60
            
        case .hours:
            return duration * 3600
            
        case .none:
            return nil
        }
    }
}

extension WorkoutExercise {
    
    var stepProgress: Double {
        
        guard let targetSteps,
              targetSteps > 0 else {
            return 0
        }
        
        return min(
            Double(stepsCompleted) /
            Double(targetSteps),
            1
        )
    }
    
    
    var pedometerDistanceMiles: Double {
        pedometerDistanceMeters / 1609.344
    }
    
    
    var pedometerDistanceKilometers: Double {
        pedometerDistanceMeters / 1000
    }
}

struct WorkoutExercisePausePeriod: Identifiable, Codable, Hashable {
    
    let id: UUID
    
    var startedAt: Date
    var endedAt: Date?
    
    init(
        id: UUID = UUID(),
        startedAt: Date = .now,
        endedAt: Date? = nil
    ) {
        self.id = id
        self.startedAt = startedAt
        self.endedAt = endedAt
    }
}

struct ExerciseInstructions: Codable, Hashable {

    let demoVideoURL: URL?
    let steps: [ExerciseInstructionStep]

    init(
        demoVideoURL: URL? = nil,
        steps: [ExerciseInstructionStep] = []
    ) {
        self.demoVideoURL = demoVideoURL
        self.steps = steps
    }
}

struct ExerciseInstructionStep: Identifiable, Codable, Hashable {

    let id: UUID

    /// Position/order of this instruction.
    let stepNumber: Int

    /// Main instruction shown to the user.
    let instruction: String

    /// Optional extra explanation or coaching cue.
    let detail: String?

    /// Optional image specifically demonstrating this step.
    let imageURL: URL?

    /// Optional video specifically demonstrating this step.
    let videoURL: URL?


    init(
        id: UUID = UUID(),
        stepNumber: Int,
        instruction: String,
        detail: String? = nil,
        imageURL: URL? = nil,
        videoURL: URL? = nil
    ) {
        self.id = id
        self.stepNumber = stepNumber
        self.instruction = instruction
        self.detail = detail
        self.imageURL = imageURL
        self.videoURL = videoURL
    }
}

enum ExerciseCategory: String, Codable, CaseIterable {
    case strength
    case cardio
    case mobility
    case flexibility
    case balance
    case plyometric
    case warmup
    case cooldown
    case rehabilitation
}

enum Equipment: String, Codable, CaseIterable {
    case none
    case barbell
    case dumbbell
    case kettlebell
    case resistanceBand
    case cable
    case machine
    case bench
    case pullUpBar
    case medicineBall
    case stabilityBall
    case treadmill
    case bicycle
    case rowingMachine
    case jumpRope
}

enum DistanceUnit: String, Codable, CaseIterable {
    case meters
    case kilometers
    case feet
    case yards
    case miles
}
