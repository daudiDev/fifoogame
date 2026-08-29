//
//  fifoogameApp.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/18/26.
//

import SwiftUI

@main
@MainActor
struct fifoogameApp: App {
    var body: some Scene {
        WindowGroup {
            AuthenticationGateView()
        }
    }
}
