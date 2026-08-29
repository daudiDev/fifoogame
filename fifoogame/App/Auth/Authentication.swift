import Foundation
import SwiftUI
import Observation
import Security
import UIKit

// MARK: - Auth Models

nonisolated struct AuthUser: Codable, Equatable, Sendable, Identifiable {
    let userID: String
    let username: String
    let firstName: String?
    let lastName: String?
    let email: String
    let joinedAt: Date?

    var id: String { userID }

    var displayName: String {
        let full = [firstName, lastName]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        return full.isEmpty ? username : full
    }
}

nonisolated struct AuthSession: Codable, Equatable, Sendable {
    let user: AuthUser
    let sessionID: String
    let accessToken: String
    let refreshToken: String
    let accessExpiresAt: Date
    let refreshExpiresAt: Date
}

nonisolated struct AuthUserEnvelope: Codable, Sendable {
    let user: AuthUser
}

nonisolated struct AuthMessageResponse: Codable, Sendable {
    let success: Bool
    let message: String?
    let developmentResetToken: String?
}

nonisolated struct AuthSuccessResponse: Codable, Sendable {
    let success: Bool
    let message: String?
}

nonisolated struct AuthErrorEnvelope: Codable, Sendable {
    let success: Bool?
    let errorCode: String?
    let message: String?
}

nonisolated struct AuthServiceError: LocalizedError, Sendable {
    let statusCode: Int
    let code: String?
    let message: String

    var errorDescription: String? { message }

    var isUnauthorized: Bool {
        statusCode == 401 || code == "unauthorized"
    }
}

// MARK: - Keychain

nonisolated struct AuthKeychainStore {
    private let service = "ai.fifoo.authentication"
    private let sessionAccount = "authenticated-session"
    private let deviceAccount = "device-id"

    func loadSession() -> AuthSession? {
        guard let data = read(account: sessionAccount) else { return nil }
        return try? JSONDecoder().decode(AuthSession.self, from: data)
    }

    func saveSession(_ session: AuthSession) throws {
        let data = try JSONEncoder().encode(session)
        try write(data, account: sessionAccount)
    }

    func clearSession() {
        delete(account: sessionAccount)
    }

    func deviceID() -> String {
        if let data = read(account: deviceAccount),
           let stored = String(data: data, encoding: .utf8),
           !stored.isEmpty {
            return stored
        }

        let generated = UUID().uuidString
        try? write(Data(generated.utf8), account: deviceAccount)
        return generated
    }

    private func read(account: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess else { return nil }
        return result as? Data
    }

    private func write(_ data: Data, account: String) throws {
        let base: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let update: [String: Any] = [kSecValueData as String: data]
        let updateStatus = SecItemUpdate(base as CFDictionary, update as CFDictionary)

        if updateStatus == errSecSuccess { return }
        guard updateStatus == errSecItemNotFound else {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(updateStatus))
        }

        var add = base
        add[kSecValueData as String] = data
        add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        let addStatus = SecItemAdd(add as CFDictionary, nil)
        guard addStatus == errSecSuccess else {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(addStatus))
        }
    }

    private func delete(account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - REST Auth API

nonisolated struct AuthAPI {
    let baseURL: URL

    func signUp(
        email: String,
        username: String,
        firstName: String,
        lastName: String,
        password: String,
        deviceID: String
    ) async throws -> AuthSession {
        struct Body: Encodable {
            let email: String
            let username: String
            let firstName: String
            let lastName: String
            let password: String
            let deviceID: String
        }
        return try await send(
            path: "/auth/signup",
            method: "POST",
            body: Body(
                email: email,
                username: username,
                firstName: firstName,
                lastName: lastName,
                password: password,
                deviceID: deviceID
            ),
            accessToken: nil,
            response: AuthSession.self
        )
    }

    func login(identifier: String, password: String, deviceID: String) async throws -> AuthSession {
        struct Body: Encodable {
            let identifier: String
            let password: String
            let deviceID: String
        }
        return try await send(
            path: "/auth/login",
            method: "POST",
            body: Body(identifier: identifier, password: password, deviceID: deviceID),
            accessToken: nil,
            response: AuthSession.self
        )
    }

    func refresh(refreshToken: String, deviceID: String) async throws -> AuthSession {
        struct Body: Encodable {
            let refreshToken: String
            let deviceID: String
        }
        return try await send(
            path: "/auth/refresh",
            method: "POST",
            body: Body(refreshToken: refreshToken, deviceID: deviceID),
            accessToken: nil,
            response: AuthSession.self
        )
    }

    func me(accessToken: String) async throws -> AuthUser {
        let envelope: AuthUserEnvelope = try await sendWithoutBody(
            path: "/auth/me",
            method: "GET",
            accessToken: accessToken,
            response: AuthUserEnvelope.self
        )
        return envelope.user
    }

    func logout(accessToken: String, refreshToken: String) async throws {
        struct Body: Encodable { let refreshToken: String }
        let _: AuthSuccessResponse = try await send(
            path: "/auth/logout",
            method: "POST",
            body: Body(refreshToken: refreshToken),
            accessToken: accessToken,
            response: AuthSuccessResponse.self
        )
    }

    func logoutAll(accessToken: String) async throws {
        struct Empty: Encodable {}
        let _: AuthSuccessResponse = try await send(
            path: "/auth/logout-all",
            method: "POST",
            body: Empty(),
            accessToken: accessToken,
            response: AuthSuccessResponse.self
        )
    }

    func forgotPassword(email: String) async throws -> AuthMessageResponse {
        struct Body: Encodable { let email: String }
        return try await send(
            path: "/auth/password/forgot",
            method: "POST",
            body: Body(email: email),
            accessToken: nil,
            response: AuthMessageResponse.self
        )
    }

    func resetPassword(token: String, newPassword: String) async throws -> AuthSuccessResponse {
        struct Body: Encodable {
            let token: String
            let newPassword: String
        }
        return try await send(
            path: "/auth/password/reset",
            method: "POST",
            body: Body(token: token, newPassword: newPassword),
            accessToken: nil,
            response: AuthSuccessResponse.self
        )
    }

    private func send<Body: Encodable, Response: Decodable>(
        path: String,
        method: String,
        body: Body,
        accessToken: String?,
        response: Response.Type
    ) async throws -> Response {
        let data = try JSONEncoder().encode(body)
        return try await request(path: path, method: method, data: data, accessToken: accessToken, response: response)
    }

    private func sendWithoutBody<Response: Decodable>(
        path: String,
        method: String,
        accessToken: String?,
        response: Response.Type
    ) async throws -> Response {
        try await request(path: path, method: method, data: nil, accessToken: accessToken, response: response)
    }

    private func request<Response: Decodable>(
        path: String,
        method: String,
        data: Data?,
        accessToken: String?,
        response: Response.Type
    ) async throws -> Response {
        let url = baseURL.appending(path: path.trimmingCharacters(in: CharacterSet(charactersIn: "/")))
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 20
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let data {
            request.httpBody = data
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        if let accessToken {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }

        let (responseData, urlResponse) = try await URLSession.shared.data(for: request)
        guard let http = urlResponse as? HTTPURLResponse else {
            throw AuthServiceError(statusCode: 0, code: nil, message: "Invalid authentication server response.")
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        guard (200..<300).contains(http.statusCode) else {
            let envelope = try? decoder.decode(AuthErrorEnvelope.self, from: responseData)
            throw AuthServiceError(
                statusCode: http.statusCode,
                code: envelope?.errorCode,
                message: envelope?.message ?? "Authentication request failed."
            )
        }

        return try decoder.decode(Response.self, from: responseData)
    }
}

// MARK: - Auth Manager

@MainActor
@Observable
final class AuthManager {
    enum Phase: Equatable {
        case restoring
        case signedOut
        case signedIn
    }

    static let shared = AuthManager()

    private(set) var phase: Phase = .restoring
    private(set) var currentUser: AuthUser?
    private(set) var isWorking = false
    private(set) var statusMessage: String?
    private(set) var errorMessage: String?
    private(set) var developmentResetToken: String?
    private(set) var pendingPasswordResetToken: String?

    // These are implementation dependencies/state, not observable UI state.
    // Keeping them out of Observation also avoids Swift's @Observable macro
    // generating invalid init accessors for lazy properties.
    private let keychain: AuthKeychainStore
    private let serverURL: URL
    private let api: AuthAPI
    let deviceID: String
    @ObservationIgnored private var session: AuthSession?
    @ObservationIgnored private var refreshTask: Task<Void, Never>?
    @ObservationIgnored private var didRestore = false

    private init() {
        let keychain = AuthKeychainStore()
        let serverURL = GameBackendConfiguration.authenticationServerURL

        self.keychain = keychain
        self.serverURL = serverURL
        self.api = AuthAPI(baseURL: serverURL)
        self.deviceID = keychain.deviceID()
    }

    func restoreSession() async {
        guard !didRestore else { return }
        didRestore = true
        phase = .restoring
        errorMessage = nil

        guard serverURL.host != "invalid.invalid" else {
            phase = .signedOut
            errorMessage = "Set FIFOO_BACKEND_URL for this build before signing in."
            return
        }

        guard let stored = keychain.loadSession(), stored.refreshExpiresAt > Date() else {
            keychain.clearSession()
            phase = .signedOut
            return
        }

        session = stored
        do {
            if stored.accessExpiresAt.timeIntervalSinceNow < 60 {
                let refreshed = try await api.refresh(refreshToken: stored.refreshToken, deviceID: deviceID)
                establish(refreshed, replacingExistingUser: true)
            } else {
                let user = try await api.me(accessToken: stored.accessToken)
                let verified = AuthSession(
                    user: user,
                    sessionID: stored.sessionID,
                    accessToken: stored.accessToken,
                    refreshToken: stored.refreshToken,
                    accessExpiresAt: stored.accessExpiresAt,
                    refreshExpiresAt: stored.refreshExpiresAt
                )
                establish(verified, replacingExistingUser: true)
            }
        } catch let error as AuthServiceError where error.isUnauthorized {
            do {
                let refreshed = try await api.refresh(refreshToken: stored.refreshToken, deviceID: deviceID)
                establish(refreshed, replacingExistingUser: true)
            } catch {
                clearLocalSession()
            }
        } catch {
            // Preserve the refresh credential across a temporary network outage,
            // but do not expose the authenticated app until the server confirms it.
            phase = .signedOut
            errorMessage = "Could not restore your session. Sign in again when the server is reachable."
        }
    }

    func signUp(
        email: String,
        username: String,
        firstName: String,
        lastName: String,
        password: String,
        confirmation: String
    ) async {
        guard password == confirmation else {
            errorMessage = "Passwords do not match."
            return
        }
        await performAuthentication {
            try await api.signUp(
                email: email,
                username: username,
                firstName: firstName,
                lastName: lastName,
                password: password,
                deviceID: deviceID
            )
        }
    }

    func login(identifier: String, password: String) async {
        await performAuthentication {
            try await api.login(identifier: identifier, password: password, deviceID: deviceID)
        }
    }

    func requestPasswordReset(email: String) async {
        await setWorking {
            let response = try await api.forgotPassword(email: email)
            statusMessage = response.message
            developmentResetToken = response.developmentResetToken
            if let token = response.developmentResetToken {
                pendingPasswordResetToken = token
            }
        }
    }

    func resetPassword(token: String, newPassword: String, confirmation: String) async -> Bool {
        guard newPassword == confirmation else {
            errorMessage = "Passwords do not match."
            return false
        }

        var didReset = false
        await setWorking {
            let response = try await api.resetPassword(token: token, newPassword: newPassword)
            statusMessage = response.message
            pendingPasswordResetToken = nil
            developmentResetToken = nil
            didReset = true
        }
        return didReset
    }

    /// Called by SocketManager when a reconnect reaches the server with an
    /// access token that expired while the app was suspended.
    func refreshAccessTokenForSocket() async -> Bool {
        guard let current = session, current.refreshExpiresAt > Date() else {
            clearLocalSession()
            return false
        }

        do {
            let refreshed = try await api.refresh(
                refreshToken: current.refreshToken,
                deviceID: deviceID
            )
            establish(refreshed, replacingExistingUser: false)
            return true
        } catch let error as AuthServiceError where error.isUnauthorized {
            clearLocalSession()
            return false
        } catch {
            errorMessage = "Could not refresh the authenticated session."
            return false
        }
    }


    func logout() async {
        let old = session
        isWorking = true
        errorMessage = nil
        if let old {
            try? await api.logout(accessToken: old.accessToken, refreshToken: old.refreshToken)
        }
        isWorking = false
        clearLocalSession()
    }

    func logoutAllDevices() async {
        guard let session else { return }
        await setWorking {
            try await api.logoutAll(accessToken: session.accessToken)
            clearLocalSession()
        }
    }

    func handleIncomingURL(_ url: URL) {
        guard url.scheme?.lowercased() == "fifoo" else { return }
        let host = url.host?.lowercased()
        guard host == "reset-password" || url.path.lowercased().contains("reset-password") else { return }
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        if let token = components?.queryItems?.first(where: { $0.name == "token" })?.value,
           !token.isEmpty {
            pendingPasswordResetToken = token
        }
    }

    func dismissPasswordReset() {
        pendingPasswordResetToken = nil
    }

    func clearMessages() {
        errorMessage = nil
        statusMessage = nil
    }

    private func performAuthentication(_ operation: () async throws -> AuthSession) async {
        await setWorking {
            let authenticated = try await operation()
            establish(authenticated, replacingExistingUser: currentUser?.userID != authenticated.user.userID)
        }
    }

    private func setWorking(_ operation: () async throws -> Void) async {
        guard !isWorking else { return }
        isWorking = true
        errorMessage = nil
        statusMessage = nil
        do {
            try await operation()
        } catch {
            errorMessage = error.localizedDescription
        }
        isWorking = false
    }

    private func establish(_ newSession: AuthSession, replacingExistingUser: Bool) {
        let previousUserID = currentUser?.userID
        session = newSession
        currentUser = newSession.user
        phase = .signedIn
        errorMessage = nil

        do {
            try keychain.saveSession(newSession)
        } catch {
            errorMessage = "Signed in, but secure session storage failed: \(error.localizedDescription)"
        }

        let socket = SocketManager.shared
        if replacingExistingUser || previousUserID != newSession.user.userID || !socket.backendConfiguration.isEnabled {
            socket.resetForAuthenticationTransition()
            socket.configureBackend(
                .authenticated(
                    serverURL: serverURL,
                    userID: newSession.user.userID,
                    authToken: newSession.accessToken,
                    deviceID: deviceID
                )
            )
            socket.connect()
        } else {
            socket.updateAuthenticatedCredentials(
                userID: newSession.user.userID,
                authToken: newSession.accessToken,
                deviceID: deviceID
            )
            socket.connect()
        }

        scheduleRefresh(for: newSession)
    }

    private func scheduleRefresh(for scheduledSession: AuthSession) {
        refreshTask?.cancel()
        let seconds = max(5, scheduledSession.accessExpiresAt.timeIntervalSinceNow - 90)
        refreshTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(seconds))
            guard !Task.isCancelled else { return }
            await self?.refreshIfCurrent(sessionID: scheduledSession.sessionID)
        }
    }

    private func refreshIfCurrent(sessionID: String) async {
        guard let current = session, current.sessionID == sessionID else { return }
        do {
            let refreshed = try await api.refresh(refreshToken: current.refreshToken, deviceID: deviceID)
            establish(refreshed, replacingExistingUser: false)
        } catch let error as AuthServiceError where error.isUnauthorized {
            clearLocalSession()
        } catch {
            errorMessage = "Session refresh failed. Retrying when the app reconnects."
            scheduleRefreshRetry(sessionID: sessionID)
        }
    }

    private func scheduleRefreshRetry(sessionID: String) {
        refreshTask?.cancel()
        refreshTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(30))
            guard !Task.isCancelled else { return }
            await self?.refreshIfCurrent(sessionID: sessionID)
        }
    }

    private func clearLocalSession() {
        refreshTask?.cancel()
        refreshTask = nil
        session = nil
        currentUser = nil
        keychain.clearSession()
        phase = .signedOut
        SocketManager.shared.resetForAuthenticationTransition(clearPersistedOutbox: true)
    }
}

// MARK: - Authentication Gate

struct AuthenticationGateView: View {
    @State private var auth = AuthManager.shared

    var body: some View {
        Group {
            switch auth.phase {
            case .restoring:
                AuthLaunchView()
            case .signedOut:
                WelcomeAuthView()
            case .signedIn:
                DayMapView()
                    .id(auth.currentUser?.userID)
            }
        }
        .task {
            await auth.restoreSession()
        }
        .onOpenURL { url in
            auth.handleIncomingURL(url)
        }
        .sheet(
            isPresented: Binding(
                get: { auth.pendingPasswordResetToken != nil },
                set: { if !$0 { auth.dismissPasswordReset() } }
            )
        ) {
            PasswordResetView(initialToken: auth.pendingPasswordResetToken ?? "")
        }
    }
}

private struct AuthLaunchView: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [.black, Color(red: 0.08, green: 0.13, blue: 0.18)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            VStack(spacing: 18) {
                Text("fifoo")
                    .font(.custom("Chewy-Regular", size: 58))
                    .foregroundStyle(.white)
                ProgressView()
                    .tint(.white)
            }
        }
    }
}

struct WelcomeAuthView: View {
    @State private var auth = AuthManager.shared

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color(red: 0.05, green: 0.08, blue: 0.12), Color(red: 0.18, green: 0.27, blue: 0.36)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer()
                    VStack(spacing: 18) {
                        Text("fifoo")
                            .font(.custom("Chewy-Regular", size: 72))
                            .foregroundStyle(.white)

                        Image("purple_pied_piper")
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 320, maxHeight: 320)
                            .accessibilityLabel("Purple Pied Piper")

                        Text("A simple daily game that makes your weight loss simpler")
                            .font(.title3.weight(.medium))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white.opacity(0.82))
                            .padding(.horizontal, 20)
                    }
                    Spacer(minLength: 20)
                    VStack(spacing: 12) {
                        NavigationLink {
                            SignUpView()
                        } label: {
                            AuthPrimaryButtonLabel(title: "Create account")
                        }

                        NavigationLink {
                            LoginView()
                        } label: {
                            Text("Log in")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 18))
                                .overlay(RoundedRectangle(cornerRadius: 18).stroke(.white.opacity(0.22)))
                        }

                        if let error = auth.errorMessage {
                            Text(error)
                                .font(.footnote)
                                .foregroundStyle(.red.opacity(0.95))
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.horizontal, 28)
                    .padding(.bottom, 34)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

struct LoginView: View {
    @State private var auth = AuthManager.shared
    @State private var identifier = ""
    @State private var password = ""

    var body: some View {
        AuthFormContainer(title: "Welcome back", subtitle: "Log in to continue your Day Map.") {
            AuthTextField(title: "Email or username", text: $identifier, contentType: .username)
            AuthSecureField(title: "Password", text: $password)

            NavigationLink("Forgot password?") {
                ForgotPasswordView()
            }
            .font(.subheadline.weight(.semibold))
            .frame(maxWidth: .infinity, alignment: .trailing)

            Button {
                Task { await auth.login(identifier: identifier, password: password) }
            } label: {
                AuthPrimaryButtonLabel(title: auth.isWorking ? "Logging in…" : "Log in")
            }
            .disabled(auth.isWorking || identifier.trimmingCharacters(in: .whitespaces).isEmpty || password.isEmpty)

            AuthFeedbackView(auth: auth)
        }
        .onAppear { auth.clearMessages() }
    }
}

struct SignUpView: View {
    @State private var auth = AuthManager.shared
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmation = ""

    var body: some View {
        AuthFormContainer(title: "Create your account") {
            HStack(spacing: 10) {
                AuthTextField(title: "First name", text: $firstName, contentType: .givenName)
                AuthTextField(title: "Last name", text: $lastName, contentType: .familyName)
            }
            AuthTextField(title: "Username", text: $username, contentType: .username)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            AuthTextField(title: "Email", text: $email, contentType: .emailAddress)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
            AuthSecureField(title: "Password (10+ characters)", text: $password)
            AuthSecureField(title: "Confirm password", text: $confirmation)

            Button {
                Task {
                    await auth.signUp(
                        email: email,
                        username: username,
                        firstName: firstName,
                        lastName: lastName,
                        password: password,
                        confirmation: confirmation
                    )
                }
            } label: {
                AuthPrimaryButtonLabel(title: auth.isWorking ? "Creating…" : "Create account")
            }
            .disabled(auth.isWorking || username.isEmpty || email.isEmpty || password.count < 10 || confirmation.isEmpty)

            AuthFeedbackView(auth: auth)
        }
        .onAppear { auth.clearMessages() }
    }
}

struct ForgotPasswordView: View {
    @State private var auth = AuthManager.shared
    @State private var email = ""
    @State private var token = ""
    @State private var password = ""
    @State private var confirmation = ""
    @State private var requestSent = false

    var body: some View {
        AuthFormContainer(title: "Reset password", subtitle: "We’ll issue a short-lived reset link for your account.") {
            if !requestSent {
                AuthTextField(title: "Email", text: $email, contentType: .emailAddress)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)

                Button {
                    Task {
                        await auth.requestPasswordReset(email: email)
                        requestSent = auth.errorMessage == nil
                        if let development = auth.developmentResetToken {
                            token = development
                        }
                    }
                } label: {
                    AuthPrimaryButtonLabel(title: auth.isWorking ? "Sending…" : "Send reset instructions")
                }
                .disabled(auth.isWorking || email.isEmpty)
            } else {
                Text("Check your email for the reset link. In local development, the token is filled automatically.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                AuthTextField(title: "Reset token", text: $token, contentType: nil)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                AuthSecureField(title: "New password", text: $password)
                AuthSecureField(title: "Confirm new password", text: $confirmation)

                Button {
                    Task {
                        if await auth.resetPassword(token: token, newPassword: password, confirmation: confirmation) {
                            requestSent = false
                            password = ""
                            confirmation = ""
                        }
                    }
                } label: {
                    AuthPrimaryButtonLabel(title: auth.isWorking ? "Updating…" : "Update password")
                }
                .disabled(auth.isWorking || token.isEmpty || password.count < 10 || confirmation.isEmpty)
            }

            AuthFeedbackView(auth: auth)
        }
        .onAppear { auth.clearMessages() }
    }
}

struct PasswordResetView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var auth = AuthManager.shared
    @State private var token: String
    @State private var password = ""
    @State private var confirmation = ""

    init(initialToken: String) {
        _token = State(initialValue: initialToken)
    }

    var body: some View {
        NavigationStack {
            AuthFormContainer(title: "Choose a new password", subtitle: "This link is single-use and expires automatically.") {
                AuthTextField(title: "Reset token", text: $token, contentType: nil)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                AuthSecureField(title: "New password", text: $password)
                AuthSecureField(title: "Confirm password", text: $confirmation)
                Button {
                    Task {
                        if await auth.resetPassword(token: token, newPassword: password, confirmation: confirmation) {
                            dismiss()
                        }
                    }
                } label: {
                    AuthPrimaryButtonLabel(title: auth.isWorking ? "Updating…" : "Update password")
                }
                .disabled(auth.isWorking || token.isEmpty || password.count < 10 || confirmation.isEmpty)
                AuthFeedbackView(auth: auth)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Auth UI Components

private struct AuthFormContainer<Content: View>: View {
    let title: String
    let subtitle: String?
    let content: Content

    init(title: String, subtitle: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.largeTitle.bold())

                    if let subtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.bottom, 8)

                content
            }
            .padding(24)
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct AuthTextField: View {
    let title: String
    @Binding var text: String
    let contentType: UITextContentType?

    var body: some View {
        TextField(title, text: $text)
            .textContentType(contentType)
            .padding(.horizontal, 16)
            .frame(height: 54)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct AuthSecureField: View {
    let title: String
    @Binding var text: String

    var body: some View {
        SecureField(title, text: $text)
            .textContentType(.password)
            .padding(.horizontal, 16)
            .frame(height: 54)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct AuthPrimaryButtonLabel: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 18))
    }
}

private struct AuthFeedbackView: View {
    let auth: AuthManager

    var body: some View {
        Group {
            if let error = auth.errorMessage {
                Text(error)
                    .foregroundStyle(.red)
            } else if let status = auth.statusMessage {
                Text(status)
                    .foregroundStyle(.secondary)
            }
        }
        .font(.footnote)
    }
}
