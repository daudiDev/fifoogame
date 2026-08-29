//
//  GameBackendConfiguration.swift
//  fifoogame
//
//  Backend/authentication configuration.
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

    /// REST auth and Socket.IO share the same backend origin.
    static var authenticationServerURL: URL {
        #if DEBUG
        return URL(string: "http://172.20.10.2:3000")!
        #else
        if let value = Bundle.main.object(forInfoDictionaryKey: "FIFOO_BACKEND_URL") as? String,
           let url = URL(string: value),
           !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return url
        }
        return URL(string: "https://invalid.invalid")!
        #endif
    }

    static func authenticated(
        serverURL: URL = authenticationServerURL,
        userID: String,
        authToken: String,
        deviceID: String
    ) -> GameBackendConfiguration {
        GameBackendConfiguration(
            serverURL: serverURL,
            userID: userID,
            authToken: authToken,
            deviceID: deviceID,
            isEnabled: true,
            ackTimeout: 10
        )
    }

    #if DEBUG
    /// Explicit legacy fallback for backend integration debugging only.
    static let localDevelopment =
        GameBackendConfiguration(
            serverURL: authenticationServerURL,
            userID: "DUMMY_USER_ID",
            authToken: "DUMMY_AUTH_TOKEN",
            deviceID: "DUMMY_IOS_DEVICE_ID",
            isEnabled: true,
            ackTimeout: 10
        )
    #endif

    static let productionPlaceholder =
        GameBackendConfiguration(
            serverURL: authenticationServerURL,
            userID: "",
            authToken: "",
            deviceID: "",
            isEnabled: false,
            ackTimeout: 10
        )
}
