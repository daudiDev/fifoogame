//
//  fifoogameApp.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/18/26.
//

import SwiftUI

@main
struct fifoogameApp: App {
    private let socketManager = SocketManager.shared
    var body: some Scene {
        WindowGroup {
            DayMapView()
        }
    }
}
