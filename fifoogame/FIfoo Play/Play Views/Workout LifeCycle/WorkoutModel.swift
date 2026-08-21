//
//  WorkoutModel.swift
//  Learn Canvas
//
//  Created by Daudi Sagala on 8/11/26.
//

import Foundation
import SwiftUI

// MARK: - Workout

struct Workout: Identifiable, Codable, Hashable {
    
    let id: UUID
    
    var name: String
    var description: String?
    
    // MARK: Exercises
    
    var exercises: [WorkoutExercise]
    
    // MARK: Lifecycle
    
    var status: WorkoutStatus
    
    var startedAt: Date?
    var endedAt: Date?
    
    var pausedAt: Date?
    var resumedAt: Date?
    
    /// Every pause/resume cycle.
    var pausePeriods: [WorkoutPausePeriod]

    var currentWorkoutExerciseID: UUID?
    
    // MARK: - Workout Pedometer Summary
     
     var totalSteps: Int
     
     /// Total pedometer distance accumulated across the workout.
     /// Stored in meters.
     var totalPedometerDistanceMeters: Double
     
     var totalFloorsAscended: Int
     var totalFloorsDescended: Int
    
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        name: String,
        description: String? = nil,
        exercises: [WorkoutExercise],
        status: WorkoutStatus = .notStarted,
        startedAt: Date? = nil,
        endedAt: Date? = nil,
        pausedAt: Date? = nil,
        resumedAt: Date? = nil,
        pausePeriods: [WorkoutPausePeriod] = [],
        currentWorkoutExerciseID: UUID? = nil,
        totalSteps: Int = 0,
        totalPedometerDistanceMeters: Double = 0,
        totalFloorsAscended: Int = 0,
        totalFloorsDescended: Int = 0,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.exercises = exercises
        self.status = status
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.pausedAt = pausedAt
        self.resumedAt = resumedAt
        self.pausePeriods = pausePeriods
        self.currentWorkoutExerciseID = currentWorkoutExerciseID
        self.totalSteps = totalSteps
        self.totalPedometerDistanceMeters = totalPedometerDistanceMeters
        self.totalFloorsAscended = totalFloorsAscended
        self.totalFloorsDescended = totalFloorsDescended
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

enum WorkoutStatus: String, Codable, CaseIterable {
    case notStarted = "Not Started"
    case active = "Active"
    case paused = "Paused"
    case completed = "Completed"
    case ended = "Ended"
}

struct WorkoutPausePeriod: Identifiable, Codable, Hashable {
    
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

extension Workout {
    
    // MARK: - Current Exercise
    
    var currentExercise: WorkoutExercise? {
        
        guard let currentWorkoutExerciseID else {
            return nil
        }
        
        return exercises.first {
            $0.workoutExerciseId ==
            currentWorkoutExerciseID
        }
    }
    
    
    // MARK: - Completed
    
    var completedExerciseCount: Int {
        
        exercises.filter {
            $0.status == .completed
        }
        .count
    }
    
    
    // MARK: - Remaining
    
    var remainingExerciseCount: Int {
        
        exercises.filter {
            $0.status != .completed
        }
        .count
    }
    
    
    // MARK: - Progress
    
    var progress: Double {
        
        guard !exercises.isEmpty else {
            return 0
        }
        
        return Double(completedExerciseCount) /
               Double(exercises.count)
    }
    
    
    var progressPercentage: Int {
        Int(progress * 100)
    }
    
    
    // MARK: - Elapsed Time
    
    var totalElapsedTime: TimeInterval {
        
        guard let startedAt else {
            return 0
        }
        
        let endDate =
            endedAt ?? Date()
        
        return max(
            0,
            endDate.timeIntervalSince(startedAt)
        )
    }
    
    
    // MARK: - Paused Time
    
    var totalPausedTime: TimeInterval {
        
        pausePeriods.reduce(0) { total, period in
            
            let end =
                period.endedAt ?? Date()
            
            return total +
                max(
                    0,
                    end.timeIntervalSince(
                        period.startedAt
                    )
                )
        }
    }
    
    
    // MARK: - Active Time
    
    var totalActiveTime: TimeInterval {
        
        max(
            0,
            totalElapsedTime - totalPausedTime
        )
    }
}

extension Workout {
    
    var pedometerDistanceMiles: Double {
        totalPedometerDistanceMeters / 1609.344
    }
    
    var pedometerDistanceKilometers: Double {
        totalPedometerDistanceMeters / 1000
    }
}


