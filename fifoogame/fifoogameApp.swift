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

    private let socketManager =
        SocketManager.shared


    init() {

        // Step 2 backend bootstrap. The supplied placeholder configuration has
        // isEnabled = false, so the current app remains local-only until the
        // real Node.js URL/user authentication values are supplied.
        socketManager.configureBackend(
            .developmentPlaceholder
        )

        socketManager.connect()
    }


    var body: some Scene {

        WindowGroup {
            DayMapView()
        }
    }
}
