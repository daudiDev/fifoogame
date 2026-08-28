//
//  GameBackendConfiguration.swift
//  fifoogame
//
//  Step 2: Socket.IO client/backend contract configuration.
//

import Foundation


nonisolated struct GameBackendConfiguration:
    Equatable,
    Sendable {

    let serverURL: URL
    let userID: String
    let authToken: String
    let deviceID: String
    let isEnabled: Bool
    let ackTimeout: TimeInterval


    init(
        serverURL: URL,
        userID: String,
        authToken: String,
        deviceID: String,
        isEnabled: Bool = true,
        ackTimeout: TimeInterval = 10
    ) {

        self.serverURL = serverURL
        self.userID = userID
        self.authToken = authToken
        self.deviceID = deviceID
        self.isEnabled = isEnabled
        self.ackTimeout = max(1, ackTimeout)
    }
}


extension GameBackendConfiguration {

    /// Safe default while the Node.js server has not been created yet.
    /// Replace the URL/user/token values when the real server is available,
    /// then set `isEnabled` to true.
    static let developmentPlaceholder =
        GameBackendConfiguration(
            serverURL:
                URL(
                    string:
                        "https://YOUR-FIFOO-SERVER.example.com"
                )!,
            userID:
                "DUMMY_USER_ID",
            authToken:
                "DUMMY_AUTH_TOKEN",
            deviceID:
                "DUMMY_IOS_DEVICE_ID",
            isEnabled:
                false,
            ackTimeout:
                10
        )
}
