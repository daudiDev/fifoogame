//
//  PedometerManager.swift
//  Fifoo Play
//
//  Created by Daudi Sagala on 8/13/26.
//


import Foundation
import CoreMotion
import Observation

@MainActor
@Observable
final class PedometerManager {
    
    // MARK: - Singleton
    
    static let shared = PedometerManager()
    
    
    // MARK: - Core Motion
    
    private let pedometer = CMPedometer()
    
    
    // MARK: - State
    
    private(set) var isTracking: Bool = false
    
    private(set) var steps: Int = 0
    
    /// Stored in meters.
    private(set) var distanceMeters: Double = 0
    
    private(set) var floorsAscended: Int = 0
    private(set) var floorsDescended: Int = 0
    
    /// Steps per minute, when available.
    private(set) var cadence: Double?
    
    /// Seconds per meter, when available.
    private(set) var pace: Double?
    
    private(set) var errorMessage: String?
    
    
    // MARK: - Session
    
    private(set) var trackingStartedAt: Date?
    
    
    private init() {}
}

extension PedometerManager {
    
    var isStepCountingAvailable: Bool {
        CMPedometer.isStepCountingAvailable()
    }
    
    var isDistanceAvailable: Bool {
        CMPedometer.isDistanceAvailable()
    }
    
    var isFloorCountingAvailable: Bool {
        CMPedometer.isFloorCountingAvailable()
    }
    
    var authorizationStatus: CMAuthorizationStatus {
        CMPedometer.authorizationStatus()
    }
}

extension PedometerManager {
    
    // MARK: - Start
    
    func startTracking(
        from startDate: Date = .now
    ) {
        
        guard CMPedometer.isStepCountingAvailable() else {
            errorMessage = "Step counting is unavailable on this device."
            return
        }
        
        // Prevent duplicate live sessions.
        stopTracking()
        
        resetLiveValues()
        
        trackingStartedAt = startDate
        isTracking = true
        
        pedometer.startUpdates(
            from: startDate
        ) { [weak self] data, error in
            
            guard let self else {
                return
            }
            
            Task { @MainActor in
                
                if let error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                
                guard let data else {
                    return
                }
                
                self.steps =
                    data.numberOfSteps.intValue
                
                if let distance = data.distance {
                    self.distanceMeters =
                        distance.doubleValue
                }
                
                if let floorsAscended =
                    data.floorsAscended {
                    
                    self.floorsAscended =
                        floorsAscended.intValue
                }
                
                if let floorsDescended =
                    data.floorsDescended {
                    
                    self.floorsDescended =
                        floorsDescended.intValue
                }
                
                if let cadence =
                    data.currentCadence {
                    
                    self.cadence =
                        cadence.doubleValue * 60
                }
                
                if let pace =
                    data.currentPace {
                    
                    self.pace =
                        pace.doubleValue
                }
            }
        }
    }
}

extension PedometerManager {
    
    // MARK: - Stop
    
    func stopTracking() {
        
        pedometer.stopUpdates()
        
        isTracking = false
        trackingStartedAt = nil
    }
    
    
    // MARK: - Reset
    
    func resetLiveValues() {
        
        steps = 0
        distanceMeters = 0
        
        floorsAscended = 0
        floorsDescended = 0
        
        cadence = nil
        pace = nil
        
        errorMessage = nil
    }
}

struct PedometerSnapshot {
    
    let steps: Int
    
    let distanceMeters: Double
    
    let floorsAscended: Int
    let floorsDescended: Int
    
    let cadence: Double?
    let pace: Double?
}

extension PedometerManager {
    
    var snapshot: PedometerSnapshot {
        
        PedometerSnapshot(
            steps: steps,
            distanceMeters: distanceMeters,
            floorsAscended: floorsAscended,
            floorsDescended: floorsDescended,
            cadence: cadence,
            pace: pace
        )
    }
}
