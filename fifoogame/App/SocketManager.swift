//
//  SocketManager.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/26/26.
//

import Foundation
import Observation
import SocketIO
import Combine


// MARK: - Application Socket Manager

@MainActor
@Observable
final class SocketManager {

    // MARK: - Singleton

    static let shared = SocketManager()
    
    // MARK: - Application Data

    /// Central source of truth for the Day Map domain.
    ///
    /// UI views observe this store but do not create their own independent
    /// GameStore instances. Step 2 can attach Socket.IO synchronization to the
    /// action methods defined on SocketManager without changing the views.
    let gameStore: GameStore

    // MARK: - Selected Day Map

    /// Calendar date whose Day Map is currently being viewed.
    ///
    /// This is deliberately owned by SocketManager rather than a SwiftUI
    /// view so date selection, Socket.IO request context, and future local
    /// persistence all use the same source of truth.
    private(set) var selectedDayMapDate: Date = Date()

    /// True while a backend-enabled date switch is waiting for its
    /// authoritative snapshot. Local/demo mode changes dates immediately.
    private(set) var isDayMapLoading = false

    // MARK: TODO - replace with backend/user progress data.
    #if DEBUG
    var userDailyProgress = 0.38
    #else
    var userDailyProgress = 0
    #endif

    // MARK: TODO - replace with authenticated user data.
    var currentUserAvatarAssetName = "placeholder"
    #if DEBUG
    var pendingHomeActionCount = 8
    #else
    var pendingHomeActionCount = 0
    #endif

    /// Application-level fallback used when a workout exercise does not
    /// provide its own duration. UI views read this value rather than owning
    /// a duplicate workout default.
    let defaultWorkoutExerciseDuration: TimeInterval = 120


    // MARK: - Search State

    struct SearchResult:
        Identifiable,
        Equatable,
        Sendable {

        let nodeID: GameNodeID
        let kind: GameNodeKind
        let title: String
        let subtitle: String
        let time: DayTime
        let image: GameNodeImage?

        var id: GameNodeID {
            nodeID
        }
    }

    var searchQuery = ""

    private(set) var searchResults:
        [SearchResult] = []

    private var pendingSearchResult:
        SearchResult?

    private var searchSocketDebounceTask:
        Task<Void, Never>?

    private var didInstallDebugDayMapFixture =
        false


    // MARK: - Account / Social Hub State

    private(set) var conversations: [SocialConversationSummary] = []
    private(set) var friends: [SocialFriend] = []
    private(set) var postsFeed: [SocialPost] = []
    private(set) var activePostReplies: [SocialPostReply] = []
    private(set) var activePostID: UUID?
    private(set) var activeConversationID: UUID?
    private(set) var activeConversationMessages: [SocialMessage] = []
    private(set) var isConversationsLoading = false
    private(set) var isFriendsLoading = false
    private(set) var isPostsLoading = false
    private(set) var isConversationLoading = false
    private(set) var isPostRepliesLoading = false


    // MARK: - Playable Workout Catalog

    /// Authenticated workout templates available from the backend. These are
    /// definitions, not active sessions; selecting one creates a fresh local
    /// Workout session ID before Fifoo Play opens.
    private(set) var playableWorkoutTemplates: [Workout] = []
    private(set) var isPlayableWorkoutsLoading = false
    private(set) var playableWorkoutsErrorMessage: String?


    // MARK: - Application Action Trace

    /// Local-only trace used during Step 1 to prove every UI intent reaches
    /// this centralized application layer. Step 2 can map these methods to
    /// concrete Socket.IO emits without changing the views.
    enum ApplicationActionName:
        String,
        Sendable {

        // Day Map
        case dayMapDatePickerOpened
        case dayMapDateSelected
        case dayMapTodaySelected
        case dayMapRefreshRequested

        // Nodes / Day Tiles
        case tileRevealed
        case nodeTapped
        case nodeCreationOpened
        case pathStopTapped
        case suggestedStopViewed
        case suggestedStopEditOpened
        case suggestedStopAccepted
        case suggestedStopRejected
        case nodeCreationTypeSelected
        case nodeAdded
        case nodeUpdated
        case nodeDeleted

        // Add Stop creation
        case addMealBrowseOpened
        case addMealBrowseQueryChanged
        case addMealSelected
        case addMealPhotoSelected
        case addMealPhotoAnalyzed
        case addWorkoutBrowseOpened
        case addWorkoutBrowseQueryChanged
        case addWorkoutSelected
        case addStopMediaSelected
        case addStopMediaUploadStarted
        case addStopMediaUploadCompleted
        case addStopMediaUploadFailed

        // ActivityMeal
        case activityMealUpdated
        case activityMealResourceOpened
        case activityMealStepCompleted
        case activityMealStepSkipped
        case activityMealStepBack
        case activityMealSelected
        case activityMealConfirmed
        case activityMealSourceSelected
        case activityMealRecipeSelected
        case activityMealIngredientsChanged
        case activityMealIngredientsReadyChanged
        case activityMealGroceriesNeededChanged
        case activityMealShoppingListChanged
        case activityMealIngredientStoreSelected
        case activityMealVenueSelected
        case activityMealFulfillmentSelected
        case activityMealHostSelected
        case activityMealInvitationChanged
        case activityMealContributionChanged
        case activityMealAddressChanged
        case activityMealExternalLinkOpened
        case activityMealSkipped
        case activityMealCompleted

        // ActivityWorkout stop
        case activityWorkoutUpdated
        case activityWorkoutBrowseOpened
        case activityWorkoutBrowseClassesOpened
        case activityWorkoutSelected
        case activityWorkoutIndependentScheduleChanged
        case activityWorkoutClassTimeEditAttempted
        case activityWorkoutClassCheckedIn
        case activityWorkoutIndependentActivated

        // ActivityTask
        case activityTaskUpdated
        case activityTaskScheduleChanged
        case activityTaskSkipped
        case activityTaskCompleted

        // Generic/legacy activity actions
        case activityJoined
        case activitySkipped
        case activityCompleted

        // User / Post / Hyperlink
        case userSendMessage
        case userViewProgress
        case postRespond
        case postReplySubmitted
        case postSaved
        case postViewPoster
        case postViewLinkedContent
        case hyperlinkUpvoted
        case hyperlinkDownvoted
        case playOpened
        case playWorkoutPickerOpened
        case playWorkoutSelected

        // Routes
        case completedRouteTapped
        case chosenRouteTapped
        case alternateRouteTapped
        case alternateRouteSelected
        case routeDraftStarted
        case routeDraftEditStarted
        case routeDraftStopAdded
        case routeDraftStopRemoved
        case routeDraftStopMoved
        case routeDraftStopsReordered
        case routeDraftCancelled
        case routePlanned
        case routePreviewGenerated
        case routePreviewSelected
        case routePreviewCommitted
        case routePreviewCleared

        // Roads
        case roadTapped
        case intersectionTapped
        case mapBackgroundTapped

        // Search
        case searchOpened
        case searchChanged
        case searchSubmitted
        case searchCleared
        case searchResultSelected

        // Fifoo Play
        case playClosed
        case workoutStarted
        case workoutPaused
        case workoutResumed
        case workoutEnded
        case workoutCompleted
        case workoutExerciseSelected
        case workoutExerciseStarted
        case workoutExercisePaused
        case workoutExerciseResumed
        case workoutExerciseCompleted
        case workoutExerciseSkipped
        case workoutLiveMessageSent
        case workoutReactionSent
        case workoutVoiceMuteToggled
    }


    enum ActivityMealResource:
        String,
        Sendable {

        case meals
        case recipeDetails
        case recipes
        case ingredients
        case shoppingList
        case ingredientStores
        case venues
        case friends
        case friendChat
        case contributionItems
    }


    struct ApplicationActionRecord:
        Identifiable,
        Equatable,
        Sendable {

        let id: UUID
        let name: ApplicationActionName
        let createdAt: Date
        let metadata: [String: String]
    }


    private(set) var lastApplicationAction:
        ApplicationActionRecord?

    private(set) var recentApplicationActions:
        [ApplicationActionRecord] = []


    // MARK: - Backend / Socket.IO State

    // MARK: - Socket Connection State

    enum SocketConnectionState: Equatable {

        case disconnected
        case connecting
        case connected
        case reconnecting
        case failed(String)
    }


    // MARK: - Dynamic Data

    /// SocketManager is the source of truth for workout data.
    var workout: Workout

    /// Live workout messages.
    var liveMessages: [WorkoutLiveMessage] = []

    /// Live reactions/hearts/emojis.
    var liveReactions: [WorkoutLiveReaction] = []
    
    var isShowingPlay: Bool = false


    // MARK: - Connection State

    private(set) var connectionState:
        SocketConnectionState = .disconnected

    var isConnected: Bool {
        connectionState == .connected
    }


    // MARK: - Socket.IO

    /*
     Important:

     The Socket.IO package already has a class named
     SocketManager.

     Since this application also has a SocketManager,
     explicitly use:

         SocketIO.SocketManager
    */

    private var ioManager:
        SocketIO.SocketManager?

    private var socket:
        SocketIOClient?


    // MARK: - Backend

    #if DEBUG
    private(set) var backendConfiguration:
        GameBackendConfiguration = .localDevelopment
    #else
    private(set) var backendConfiguration:
        GameBackendConfiguration = .productionPlaceholder
    #endif

    private(set) var isSocketAuthenticated = false

    /// Mutations are held until the authoritative day snapshot has been
    /// applied. This prevents reconnect replay from racing a stale snapshot.
    private(set) var hasReceivedInitialSnapshot = false

    private(set) var serverRevision = 0

    private(set) var lastBackendError: String?

    /// Durable exactly-once mutation outbox. Every mutation is persisted before
    /// its first send and removed only after a successful server acknowledgement.
    private(set) var queuedSocketMutations:
        [GameQueuedSocketMutation] = []

    /// Prevents the same request ID from being emitted twice concurrently.
    private var inFlightMutationRequestIDs:
        Set<UUID> = []


    // MARK: - Limits

    private let maximumStoredMessages =
        100

    private let maximumStoredReactions =
        100


    // MARK: - Init

    private init() {

        /*
         Development data originates in non-UI application/domain files.
         SocketManager owns the live Day Map store so SwiftUI never creates a
         separate source of truth.
        */

        #if DEBUG
        gameStore =
            GameStore(
                gameNodes:
                    SampleGameNodes.make()
            )

        // Install a dense full-day route/node fixture automatically while the
        // backend is disabled. This gives the map one Completed route, one
        // Chosen route, five selectable alternatives, and route-bound nodes
        // through 11:59 PM for visual/interaction testing.
        _ = gameStore.installRouteRenderDemo(
            .fullDayAllStates
        )
        #else
        // Release builds never bootstrap sample Day Map state.
        gameStore =
            GameStore(
                gameNodes: []
            )
        #endif

        // Normalize the initially selected map date using the same timezone
        // as the Day Map game clock.
        selectedDayMapDate =
            Self.normalizedDayMapDate(
                Date(),
                timeZoneIdentifier:
                    gameStore.clockTimeZoneIdentifier
            )

        /*
         Development workout data originates here.

         Later you can replace these with server data.
        */
        // MARK: real data
//    var workout: Workout =  Workout(id: UUID(), name: "", description: "", exercises: [], status: .notStarted, startedAt: Date(), endedAt: Date(), pausedAt: Date(), resumedAt: Date(), pausePeriods: [], currentWorkoutExerciseID: UUID(), createdAt: Date(), updatedAt: Date())
//        liveMessages = []

        #if DEBUG
        workout = Self.sample

        liveMessages =
            Self.sampleLiveMessages
        #else
        workout = Self.emptyWorkout
        liveMessages = []
        #endif

        /*
         DO NOT register socket events here.

         At this point `socket` is nil because
         configure(serverURL:) has not yet created it.
        */
    }
}


// MARK: - Socket Configuration

extension SocketManager {

    /// Primary Step 2 configuration entry point.
    ///
    /// `developmentPlaceholder` keeps networking disabled until a real server
    /// URL/authentication source is available, so the current local gameplay
    /// remains fully usable while the backend is being built.
    func configureBackend(
        _ configuration: GameBackendConfiguration
    ) {

        backendConfiguration =
            configuration

        if configuration.isEnabled {

            loadQueuedSocketMutations()

            // Do not expose development fixtures while a real backend is the
            // configured source of truth. Step 9 will replace this blank
            // bootstrap with persisted local state before server reconciliation.
            gameStore.replaceGameNodesFromServer(
                []
            )

            gameStore.replaceRouteStateFromServer(
                DayRouteState()
            )

            workout =
                Self.emptyWorkout

            liveMessages =
                []

            liveReactions =
                []

            userDailyProgress =
                0
        }

        socket?.removeAllHandlers()
        socket?.disconnect()

        isSocketAuthenticated =
            false

        hasReceivedInitialSnapshot =
            false

        connectionState =
            .disconnected

        guard configuration.isEnabled else {
            ioManager = nil
            socket = nil
            return
        }

        #if DEBUG
        let manager =
            SocketIO.SocketManager(
                socketURL:
                    configuration.serverURL,
                config: [
                    .log(true),
                    .compress
                ]
            )
        #else
        let manager =
            SocketIO.SocketManager(
                socketURL:
                    configuration.serverURL,
                config: [
                    .log(false),
                    .compress
                ]
            )
        #endif

        ioManager =
            manager

        socket =
            manager.defaultSocket

        registerSocketEvents()
    }


    /// Backward-compatible convenience used by any older call sites.
    func configure(
        serverURL: URL
    ) {

        configureBackend(
            GameBackendConfiguration(
                serverURL:
                    serverURL,
                userID:
                    backendConfiguration.userID,
                authToken:
                    backendConfiguration.authToken,
                deviceID:
                    backendConfiguration.deviceID,
                isEnabled:
                    true,
                ackTimeout:
                    backendConfiguration.ackTimeout
            )
        )
    }
}


// MARK: - Authenticated Session Reconfiguration

extension SocketManager {

    /// Updates only the credentials used by the next Socket.IO authentication.
    /// A token refresh must not clear the live Day Map or rebuild the socket.
    func updateAuthenticatedCredentials(
        userID: String,
        authToken: String,
        deviceID: String
    ) {
        guard backendConfiguration.isEnabled else { return }
        backendConfiguration =
            GameBackendConfiguration(
                serverURL: backendConfiguration.serverURL,
                userID: userID,
                authToken: authToken,
                deviceID: deviceID,
                isEnabled: true,
                ackTimeout: backendConfiguration.ackTimeout
            )
    }


    /// Clears all in-memory account-scoped state before another user signs in
    /// or the current user logs out. Durable outboxes remain namespaced by user
    /// in UserDefaults and are loaded only when that same account returns.
    func resetForAuthenticationTransition(
        clearPersistedOutbox: Bool = false
    ) {
        if clearPersistedOutbox,
           !backendConfiguration.userID.isEmpty {
            UserDefaults.standard.removeObject(
                forKey: mutationOutboxStorageKey
            )
        }

        disconnect()
        socket?.removeAllHandlers()
        socket = nil
        ioManager = nil

        queuedSocketMutations = []
        inFlightMutationRequestIDs.removeAll()
        serverRevision = 0
        lastBackendError = nil
        hasReceivedInitialSnapshot = false
        isDayMapLoading = false

        gameStore.replaceGameNodesFromServer([])
        gameStore.replaceRouteStateFromServer(DayRouteState())
        gameStore.replaceRevealedTilesFromServer([])
        gameStore.replaceConsumedSuggestedPathStopCellsFromServer([])
        gameStore.prepareSuggestedPathStopsForDayReload()
        gameStore.clearAlternativeRouteFocus()

        workout = Self.emptyWorkout
        liveMessages = []
        liveReactions = []
        userDailyProgress = 0
        isShowingPlay = false
        searchQuery = ""
        searchResults = []
        pendingSearchResult = nil
        searchSocketDebounceTask?.cancel()
        searchSocketDebounceTask = nil

        conversations = []
        friends = []
        postsFeed = []
        activePostReplies = []
        activePostID = nil
        activeConversationID = nil
        activeConversationMessages = []
        isConversationsLoading = false
        isFriendsLoading = false
        isPostsLoading = false
        isConversationLoading = false
        isPostRepliesLoading = false

        playableWorkoutTemplates = []
        isPlayableWorkoutsLoading = false
        playableWorkoutsErrorMessage = nil

        backendConfiguration = .productionPlaceholder
    }
}


// MARK: - Connection

extension SocketManager {

    func connect() {

        guard backendConfiguration.isEnabled else {

            #if DEBUG
            print(
                "SocketManager: backend networking is disabled. Replace GameBackendConfiguration.developmentPlaceholder and set isEnabled = true when the Node.js server is ready."
            )
            #endif

            return
        }

        if socket == nil {
            configureBackend(
                backendConfiguration
            )
        }

        guard let socket else {
            return
        }

        guard connectionState != .connected,
              connectionState != .connecting
        else {
            return
        }

        connectionState =
            .connecting

        socket.connect()
    }


    func disconnect() {

        socket?.disconnect()

        isSocketAuthenticated =
            false

        hasReceivedInitialSnapshot =
            false

        connectionState =
            .disconnected
    }
}


// MARK: - Socket Events

private extension SocketManager {

    func registerSocketEvents() {

        guard let socket else {
            return
        }

        socket.on(
            clientEvent: .connect
        ) { [weak self] _, _ in

            Task { @MainActor in

                guard let self else {
                    return
                }

                self.connectionState =
                    .connected

                self.lastBackendError =
                    nil

                self.authenticateSocket()
            }
        }


        socket.on(
            clientEvent: .disconnect
        ) { [weak self] _, _ in

            Task { @MainActor in

                self?.isSocketAuthenticated =
                    false

                self?.hasReceivedInitialSnapshot =
                    false

                self?.inFlightMutationRequestIDs.removeAll()

                self?.connectionState =
                    .disconnected
            }
        }


        socket.on(
            clientEvent: .reconnect
        ) { [weak self] _, _ in

            Task { @MainActor in

                self?.isSocketAuthenticated =
                    false

                self?.hasReceivedInitialSnapshot =
                    false

                self?.inFlightMutationRequestIDs.removeAll()

                self?.connectionState =
                    .reconnecting
            }
        }


        socket.on(
            clientEvent: .error
        ) { [weak self] data, _ in

            Task { @MainActor in

                let errorMessage =
                    data
                        .map {
                            String(
                                describing: $0
                            )
                        }
                        .joined(
                            separator: ", "
                        )

                self?.lastBackendError =
                    errorMessage

                self?.connectionState =
                    .failed(
                        errorMessage
                    )
            }
        }


        registerIncoming(
            .snapshot
        ) { [weak self] data in
            self?.handleServerSnapshot(
                data
            )
        }

        registerIncoming(
            .nodeUpserted
        ) { [weak self] data in
            self?.handleServerNodeUpsert(
                data
            )
        }

        registerIncoming(
            .nodeDeleted
        ) { [weak self] data in
            self?.handleServerNodeDelete(
                data
            )
        }

        registerIncoming(
            .tileRevealState
        ) { [weak self] data in
            self?.handleServerTileRevealState(
                data
            )
        }

        registerIncoming(
            .routeState
        ) { [weak self] data in
            self?.handleServerRouteState(
                data
            )
        }

        registerIncoming(
            .searchResults
        ) { [weak self] data in
            self?.handleServerSearchResults(
                data
            )
        }

        registerIncoming(.conversations) { [weak self] data in
            self?.handleSocialConversations(data)
        }

        registerIncoming(.conversationOpened) { [weak self] data in
            self?.handleSocialConversationOpened(data)
        }

        registerIncoming(.conversationMessages) { [weak self] data in
            self?.handleSocialConversationMessages(data)
        }

        registerIncoming(.conversationMessage) { [weak self] data in
            self?.handleSocialConversationMessage(data)
        }

        registerIncoming(.friends) { [weak self] data in
            self?.handleSocialFriends(data)
        }

        registerIncoming(.posts) { [weak self] data in
            self?.handleSocialPosts(data)
        }

        registerIncoming(.postFeedSaved) { [weak self] data in
            self?.handleSocialPostSaved(data)
        }

        registerIncoming(.postReplies) { [weak self] data in
            self?.handleSocialPostReplies(data)
        }

        registerIncoming(.postReply) { [weak self] data in
            self?.handleSocialPostReply(data)
        }

        registerIncoming(
            .workoutCatalog
        ) { [weak self] data in
            self?.handlePlayableWorkoutCatalog(
                data
            )
        }

        registerIncoming(
            .workout
        ) { [weak self] data in
            self?.handleServerWorkout(
                data
            )
        }

        registerIncoming(
            .liveMessage
        ) { [weak self] data in
            self?.handleServerLiveMessage(
                data
            )
        }

        registerIncoming(
            .liveMessages
        ) { [weak self] data in
            self?.handleServerLiveMessages(
                data
            )
        }

        registerIncoming(
            .liveReaction
        ) { [weak self] data in
            self?.handleServerLiveReaction(
                data
            )
        }

        registerIncoming(
            .serverError
        ) { [weak self] data in
            self?.handleServerError(
                data
            )
        }
    }


    func registerIncoming(
        _ event: GameSocketIncomingEvent,
        handler: @escaping @MainActor ([Any]) -> Void
    ) {

        socket?.on(
            event.rawValue
        ) { data, _ in

            Task { @MainActor in
                handler(
                    data
                )
            }
        }
    }
}


// MARK: - Authentication / Initial Sync

private extension SocketManager {

    func authenticateSocket() {

        let payload =
            GameSocketAuthenticationPayload(
                userID:
                    backendConfiguration.userID,
                authToken:
                    backendConfiguration.authToken,
                deviceID:
                    backendConfiguration.deviceID
            )

        emitDirectWithAck(
            event:
                .authenticate,
            payload:
                payload
        ) { [weak self] ack in

            guard let self else {
                return
            }

            guard ack.success else {

                self.isSocketAuthenticated =
                    false

                self.lastBackendError =
                    ack.message
                    ?? "Socket authentication failed."

                if ack.errorCode == "unauthorized" {
                    Task { @MainActor [weak self] in
                        guard let self else { return }
                        if await AuthManager.shared.refreshAccessTokenForSocket() {
                            self.authenticateSocket()
                        }
                    }
                }

                return
            }

            self.isSocketAuthenticated =
                true

            if let revision =
                ack.revision {

                self.serverRevision =
                    max(
                        self.serverRevision,
                        revision
                    )
            }

            self.hasReceivedInitialSnapshot =
                false

            self.requestInitialGameSnapshot()
            self.requestInitialPlayData()
            self.requestConversations()
            self.requestFriends()
            self.requestPostsFeed()
        }
    }
}


// MARK: - Requests

extension SocketManager {

    func requestInitialGameSnapshot() {

        guard canEmitAuthenticatedSocketEvents else {
            return
        }

        let payload =
            GameSocketSyncRequestPayload(
                knownRevision:
                    serverRevision,
                mapDate:
                    currentMapDateString,
                timeZoneIdentifier:
                    gameStore.clockTimeZoneIdentifier
            )

        emitEvent(
            event:
                .requestSnapshot,
            payload:
                payload,
            requiresSnapshot:
                false
        )
    }


    var hasPlayableWorkout: Bool {
        guard !workout.exercises.isEmpty,
              !workout.name
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )
                .isEmpty
        else {
            return false
        }

        switch workout.status {
        case .completed, .ended:
            return false

        case .notStarted, .active, .paused:
            return true
        }
    }


    func playWorkoutPickerOpened() {
        recordApplicationAction(
            .playWorkoutPickerOpened
        )
    }


    func requestPlayableWorkouts() {
        guard canEmitAuthenticatedSocketEvents else {
            isPlayableWorkoutsLoading =
                false

            playableWorkoutsErrorMessage =
                "Connect to Fifoo to load workouts."
            return
        }

        isPlayableWorkoutsLoading =
            true

        playableWorkoutsErrorMessage =
            nil

        emitSocialDirect(
            event:
                .workoutCatalogRequest,
            payload:
                GameEmptyPayload()
        )
    }


    func requestInitialPlayData(
        workoutID: UUID? = nil,
        sourceWorkoutID: String? = nil
    ) {

        guard canEmitAuthenticatedSocketEvents else {
            return
        }

        emitEvent(
            event:
                .requestPlayData,
            payload:
                GamePlayDataRequestPayload(
                    workoutID:
                        workoutID,
                    sourceWorkoutID:
                        sourceWorkoutID
                ),
            requiresSnapshot:
                false
        )
    }
}


// MARK: - Incoming Server State

private extension SocketManager {

    func handleServerSnapshot(
        _ data: [Any]
    ) {

        guard let payload:
            GameDaySnapshotPayload =
                decodeFirstPayload(
                    data,
                    as:
                        GameDaySnapshotPayload.self
                )
        else {
            return
        }

        // A snapshot is authoritative for this Day Map. Do not keep a larger
        // locally cached revision after conflict recovery or reconnect.
        serverRevision =
            payload.revision

        gameStore.replaceGameNodesFromServer(
            payload.nodes
        )

        gameStore.replaceRouteStateFromServer(
            payload.routeState.domainValue
        )

        gameStore.replaceRevealedTilesFromServer(
            Set(
                (payload.revealedTiles ?? [])
                    .map(\.domainValue)
            )
        )

        gameStore.replaceConsumedSuggestedPathStopCellsFromServer(
            Set(
                (payload.suggestionDecisions ?? [])
                    .map { $0.cell.domainValue }
            )
        )

        if let serverWorkout =
            payload.workout {

            workout =
                serverWorkout
        }

        if let progress =
            payload.userDailyProgress {

            userDailyProgress =
                progress
        }

        rebuildSearchResults()

        isDayMapLoading =
            false

        let hadQueuedMutations =
            queuedSocketMutations.contains {
                $0.mapDate == currentMapDateString
            }

        hasReceivedInitialSnapshot =
            true

        flushQueuedSocketMutations()

        // Pass 5.43: an empty path is generated by the backend, never by
        // SwiftUI/GameStore. Avoid racing reconnect mutations; a later
        // authoritative snapshot can request generation once the outbox is
        // empty.
        if !hadQueuedMutations {
            requestBackendGeneratedRouteIfNeeded()
        }
    }


    func handleServerNodeUpsert(
        _ data: [Any]
    ) {

        guard let payload:
            GameNodeUpsertedServerPayload =
                decodeFirstPayload(
                    data,
                    as:
                        GameNodeUpsertedServerPayload.self
                )
        else {
            return
        }

        updateRevisionIfNeeded(
            payload.revision
        )

        gameStore.upsertGameNodeFromServer(
            payload.node
        )

        rebuildSearchResults()
    }


    func handleServerNodeDelete(
        _ data: [Any]
    ) {

        guard let payload:
            GameNodeDeletedServerPayload =
                decodeFirstPayload(
                    data,
                    as:
                        GameNodeDeletedServerPayload.self
                )
        else {
            return
        }

        updateRevisionIfNeeded(
            payload.revision
        )

        gameStore.deleteGameNodeFromServer(
            id:
                payload.nodeID
        )

        rebuildSearchResults()
    }


    func handleServerTileRevealState(
        _ data: [Any]
    ) {

        guard let payload:
            GameTileRevealServerPayload =
                decodeFirstPayload(
                    data,
                    as:
                        GameTileRevealServerPayload.self
                )
        else {
            return
        }

        updateRevisionIfNeeded(
            payload.revision
        )

        gameStore.setTileRevealFromServer(
            payload.cell.domainValue,
            isRevealed:
                payload.isRevealed
        )
    }


    func handleServerRouteState(
        _ data: [Any]
    ) {

        guard let payload:
            GameRouteStateServerPayload =
                decodeFirstPayload(
                    data,
                    as:
                        GameRouteStateServerPayload.self
                )
        else {
            return
        }

        updateRevisionIfNeeded(
            payload.revision
        )

        gameStore.replaceRouteStateFromServer(
            payload.routeState.domainValue
        )
    }


    func handleServerSearchResults(
        _ data: [Any]
    ) {

        guard let payload:
            GameSearchResultsPayload =
                decodeFirstPayload(
                    data,
                    as:
                        GameSearchResultsPayload.self
                )
        else {
            return
        }

        updateRevisionIfNeeded(
            payload.revision
        )

        for node in
            payload.nodes {

            gameStore.upsertGameNodeFromServer(
                node
            )
        }

        rebuildSearchResults()
    }


    func handlePlayableWorkoutCatalog(
        _ data: [Any]
    ) {

        guard let templates: [Workout] =
                decodeFirstPayload(
                    data,
                    as:
                        [Workout].self
                )
        else {
            isPlayableWorkoutsLoading =
                false

            playableWorkoutsErrorMessage =
                "The workout list could not be decoded."
            return
        }

        playableWorkoutTemplates =
            templates

        isPlayableWorkoutsLoading =
            false

        playableWorkoutsErrorMessage =
            nil
    }


    func handleServerWorkout(
        _ data: [Any]
    ) {

        guard let payload:
            GameWorkoutServerPayload =
                decodeFirstPayload(
                    data,
                    as:
                        GameWorkoutServerPayload.self
                )
        else {
            return
        }

        updateRevisionIfNeeded(
            payload.revision
        )

        workout =
            payload.workout
    }


    func handleServerLiveMessage(
        _ data: [Any]
    ) {

        guard let message:
            WorkoutLiveMessage =
                decodeFirstPayload(
                    data,
                    as:
                        WorkoutLiveMessage.self
                )
        else {
            return
        }

        addLiveMessage(
            message
        )
    }


    func handleServerLiveMessages(
        _ data: [Any]
    ) {

        guard let messages:
            [WorkoutLiveMessage] =
                decodeFirstPayload(
                    data,
                    as:
                        [WorkoutLiveMessage].self
                )
        else {
            return
        }

        liveMessages =
            Array(
                messages.suffix(
                    maximumStoredMessages
                )
            )
    }


    func handleServerLiveReaction(
        _ data: [Any]
    ) {

        guard let reaction:
            WorkoutLiveReaction =
                decodeFirstPayload(
                    data,
                    as:
                        WorkoutLiveReaction.self
                )
        else {
            return
        }

        addLiveReaction(
            reaction
        )
    }


    func handleServerError(
        _ data: [Any]
    ) {

        if let payload:
            GameServerErrorPayload =
                decodeFirstPayload(
                    data,
                    as:
                        GameServerErrorPayload.self
                ) {

            lastBackendError =
                payload.message

            if isPlayableWorkoutsLoading {
                isPlayableWorkoutsLoading =
                    false

                playableWorkoutsErrorMessage =
                    payload.message
            }

        } else {

            lastBackendError =
                data
                    .map {
                        String(
                            describing: $0
                        )
                    }
                    .joined(
                        separator: ", "
                    )

            if isPlayableWorkoutsLoading {
                isPlayableWorkoutsLoading =
                    false

                playableWorkoutsErrorMessage =
                    lastBackendError
            }
        }
    }
}


// MARK: - Account / Social Hub

extension SocketManager {

    func requestConversations() {
        isConversationsLoading = true
        emitSocialDirect(
            event: .conversationsRequest,
            payload: GameEmptyPayload()
        )
    }

    func requestFriends() {
        isFriendsLoading = true
        emitSocialDirect(
            event: .friendsRequest,
            payload: SocialFriendsRequestPayload(
                mapDate: currentMapDateString
            )
        )
    }

    func requestPostsFeed(
        limit: Int = 50,
        offset: Int = 0
    ) {
        isPostsLoading = true
        emitSocialDirect(
            event: .postsRequest,
            payload: SocialPostsRequestPayload(
                limit: limit,
                offset: offset
            )
        )
    }

    func openConversation(
        _ conversation: SocialConversationSummary
    ) {
        activeConversationID = conversation.conversationID
        activeConversationMessages = []
        isConversationLoading = true

        emitSocialDirect(
            event: .conversationMessagesRequest,
            payload: SocialConversationIDPayload(
                conversationID: conversation.conversationID
            )
        )
    }

    func openConversation(
        with friend: SocialFriend
    ) {
        activeConversationID = nil
        activeConversationMessages = []
        isConversationLoading = true

        emitSocialDirect(
            event: .conversationOpen,
            payload: SocialConversationPartnerPayload(
                partnerUserID: friend.userID
            )
        )
    }

    func openSupportConversation() {
        activeConversationID = nil
        activeConversationMessages = []
        isConversationLoading = true

        emitSocialDirect(
            event: .supportConversationOpen,
            payload: GameEmptyPayload()
        )
    }

    func closeActiveConversation() {
        activeConversationID = nil
        activeConversationMessages = []
        isConversationLoading = false
    }

    func sendConversationMessage(
        _ text: String
    ) {
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty,
              let conversationID = activeConversationID
        else { return }

        emitDirectWithAck(
            event: .conversationMessageSend,
            payload: SocialMessageSendPayload(
                conversationID: conversationID,
                body: cleaned
            )
        ) { [weak self] ack in
            guard let self else { return }
            if ack.success {
                self.lastBackendError = nil
            } else {
                self.lastBackendError = ack.message ?? "Message could not be sent."
            }
        }
    }

    func openPostReplies(_ post: SocialPost) {
        activePostID = post.postID
        activePostReplies = []
        isPostRepliesLoading = true
        emitSocialDirect(
            event: .postRepliesRequest,
            payload: SocialPostIDPayload(postID: post.postID)
        )
    }

    func sendPostFeedReply(_ text: String) {
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty, let postID = activePostID else { return }
        emitDirectWithAck(
            event: .postReplySend,
            payload: SocialPostReplySendPayload(postID: postID, body: cleaned)
        ) { [weak self] ack in
            guard let self else { return }
            if !ack.success {
                self.lastBackendError = ack.message ?? "Reply could not be sent."
            }
        }
    }

    func setPostFeedSaved(
        postID: UUID,
        isSaved: Bool
    ) {
        if let index = postsFeed.firstIndex(where: { $0.postID == postID }) {
            postsFeed[index].isSaved = isSaved
            postsFeed[index].saveCount = max(
                0,
                postsFeed[index].saveCount + (isSaved ? 1 : -1)
            )
        }

        emitDirectWithAck(
            event: .postFeedSave,
            payload: SocialPostSavePayload(
                postID: postID,
                isSaved: isSaved
            )
        ) { [weak self] ack in
            guard let self else { return }
            if !ack.success {
                self.lastBackendError = ack.message ?? "Post save could not be updated."
                self.requestPostsFeed()
            }
        }
    }
}


private extension SocketManager {

    func emitSocialDirect<Payload>(
        event: GameSocketOutgoingEvent,
        payload: Payload
    ) where Payload: Codable & Sendable {
        guard canEmitAuthenticatedSocketEvents,
              let socket
        else { return }

        do {
            socket.emit(
                event.rawValue,
                try encodeDictionary(payload)
            )
        } catch {
            lastBackendError =
                "Unable to encode \(event.rawValue): \(error.localizedDescription)"
        }
    }

    func handleSocialConversations(_ data: [Any]) {
        guard let payload: [SocialConversationSummary] =
                decodeFirstPayload(data, as: [SocialConversationSummary].self)
        else { return }
        conversations = payload
        isConversationsLoading = false
    }

    func handleSocialConversationOpened(_ data: [Any]) {
        guard let payload: SocialConversationOpenedPayload =
                decodeFirstPayload(data, as: SocialConversationOpenedPayload.self)
        else { return }
        activeConversationID = payload.conversationID
        requestConversations()
    }

    func handleSocialConversationMessages(_ data: [Any]) {
        guard let payload: SocialConversationMessagesPayload =
                decodeFirstPayload(data, as: SocialConversationMessagesPayload.self)
        else { return }
        guard activeConversationID == nil || activeConversationID == payload.conversationID
        else { return }
        activeConversationID = payload.conversationID
        activeConversationMessages = payload.messages
        isConversationLoading = false
    }

    func handleSocialConversationMessage(_ data: [Any]) {
        guard let message: SocialMessage =
                decodeFirstPayload(data, as: SocialMessage.self)
        else { return }

        if activeConversationID == message.conversationID,
           !activeConversationMessages.contains(where: { $0.messageID == message.messageID }) {
            activeConversationMessages.append(message)
        }

        if let index = conversations.firstIndex(where: { $0.conversationID == message.conversationID }) {
            let old = conversations[index]
            conversations[index] = SocialConversationSummary(
                conversationID: old.conversationID,
                title: old.title,
                participants: old.participants,
                lastMessage: SocialConversationLastMessage(
                    messageID: message.messageID,
                    body: message.body,
                    senderID: message.senderID,
                    createdAt: message.createdAt
                ),
                updatedAt: message.createdAt,
                isSupport: old.isSupport
            )
            conversations.sort {
                ($0.updatedAt ?? .distantPast) > ($1.updatedAt ?? .distantPast)
            }
        } else {
            requestConversations()
        }
    }

    func handleSocialFriends(_ data: [Any]) {
        guard let payload: [SocialFriend] =
                decodeFirstPayload(data, as: [SocialFriend].self)
        else { return }
        friends = payload
        isFriendsLoading = false
    }

    func handleSocialPosts(_ data: [Any]) {
        guard let payload: [SocialPost] =
                decodeFirstPayload(data, as: [SocialPost].self)
        else { return }
        postsFeed = payload
        isPostsLoading = false
    }

    func handleSocialPostReplies(_ data: [Any]) {
        guard let payload: SocialPostRepliesPayload =
                decodeFirstPayload(data, as: SocialPostRepliesPayload.self)
        else { return }
        activePostID = payload.postID
        activePostReplies = payload.replies
        isPostRepliesLoading = false
    }

    func handleSocialPostReply(_ data: [Any]) {
        guard let reply: SocialPostReply =
                decodeFirstPayload(data, as: SocialPostReply.self)
        else { return }

        if activePostID == reply.postID,
           !activePostReplies.contains(where: { $0.replyID == reply.replyID }) {
            activePostReplies.append(reply)
        }

        if let index = postsFeed.firstIndex(where: { $0.postID == reply.postID }) {
            postsFeed[index].replyCount += 1
        }
    }

    func handleSocialPostSaved(_ data: [Any]) {
        guard let payload: SocialPostSavedPayload =
                decodeFirstPayload(data, as: SocialPostSavedPayload.self)
        else { return }
        guard let index = postsFeed.firstIndex(where: { $0.postID == payload.postID })
        else { return }
        postsFeed[index].isSaved = payload.isSaved
        postsFeed[index].saveCount = payload.saveCount
    }
}


// MARK: - Legacy local message/reaction helpers

extension SocketManager {

    /// Kept as a compatibility convenience for existing app code. Step 2 now
    /// sends the structured `game:play:message:send` event.
    func sendLiveMessage(
        _ text: String
    ) {

        sendWorkoutLiveMessageToBackend(
            text
        )
    }


    /// Kept as a compatibility convenience for existing app code. Step 2 now
    /// sends the structured `game:play:reaction:send` event.
    func sendReaction(
        emoji: String
    ) {

        sendWorkoutReactionToBackend(
            emoji
        )
    }
}


// MARK: - JSON Decoder

private extension SocketManager {

    func makeJSONDecoder() -> JSONDecoder {

        let decoder =
            JSONDecoder()

        decoder.dateDecodingStrategy =
            .iso8601

        return decoder
    }


    func makeJSONEncoder() -> JSONEncoder {

        let encoder =
            JSONEncoder()

        encoder.dateEncodingStrategy =
            .iso8601

        return encoder
    }
}


// =====================================================
// MARK: - Step 2 Socket Emit / Ack Infrastructure
// =====================================================

private extension SocketManager {

    var canEmitAuthenticatedSocketEvents: Bool {

        backendConfiguration.isEnabled
        &&
        isConnected
        &&
        isSocketAuthenticated
    }


    var canEmitApplicationEvents: Bool {

        canEmitAuthenticatedSocketEvents
        &&
        hasReceivedInitialSnapshot
    }


    var currentMapDateString: String {

        let timeZone =
            TimeZone(
                identifier:
                    gameStore.clockTimeZoneIdentifier
            )
            ?? .current

        let day =
            CalendarDayKey(
                date:
                    selectedDayMapDate,
                timeZone:
                    timeZone
            )

        return String(
            format:
                "%04d-%02d-%02d",
            day.year,
            day.month,
            day.day
        )
    }


    func makeRequestContext(
        requestID: UUID = UUID()
    ) -> GameSocketRequestContext {

        GameSocketRequestContext(
            requestID:
                requestID,
            userID:
                backendConfiguration.userID,
            deviceID:
                backendConfiguration.deviceID,
            mapDate:
                currentMapDateString,
            timeZoneIdentifier:
                gameStore.clockTimeZoneIdentifier,
            clientRevision:
                serverRevision,
            sentAt:
                Date()
        )
    }


    func emitEvent<Payload>(
        event: GameSocketOutgoingEvent,
        payload: Payload,
        requiresSnapshot: Bool = true
    ) where Payload: Codable & Sendable {

        let canEmit =
            requiresSnapshot
            ? canEmitApplicationEvents
            : canEmitAuthenticatedSocketEvents

        guard canEmit else {
            return
        }

        do {

            let envelope =
                GameSocketEnvelope(
                    context:
                        makeRequestContext(),
                    payload:
                        payload
                )

            let dictionary =
                try encodeDictionary(
                    envelope
                )

            socket?.emit(
                event.rawValue,
                dictionary
            )

        } catch {

            lastBackendError =
                "Unable to encode \(event.rawValue): \(error.localizedDescription)"
        }
    }


    func emitMutation<Payload>(
        event: GameSocketOutgoingEvent,
        payload: Payload
    ) where Payload: Codable & Sendable {

        guard backendConfiguration.isEnabled else {
            return
        }

        let requestID =
            UUID()

        do {

            let envelope =
                GameSocketEnvelope(
                    context:
                        makeRequestContext(
                            requestID:
                                requestID
                        ),
                    payload:
                        payload
                )

            let encoded =
                try makeJSONEncoder()
                    .encode(
                        envelope
                    )

            // Persist before the first network send. If the app terminates
            // after the server commits but before the ack arrives, the same
            // requestID is replayed and backend idempotency returns the original
            // successful result without applying the mutation twice.
            queueMutation(
                event:
                    event,
                requestID:
                    requestID,
                encodedEnvelope:
                    encoded
            )

            guard canEmitApplicationEvents else {
                return
            }

            // Always drain through the durable outbox. This preserves mutation
            // order and lets every request be rebased onto the latest
            // authoritative server revision before it is sent.
            flushQueuedSocketMutations()

        } catch {

            lastBackendError =
                "Unable to encode mutation \(event.rawValue): \(error.localizedDescription)"
        }
    }


    func emitDirectWithAck<Payload>(
        event: GameSocketOutgoingEvent,
        payload: Payload,
        completion: @escaping @MainActor (GameSocketAck) -> Void
    ) where Payload: Codable & Sendable {

        guard backendConfiguration.isEnabled,
              isConnected,
              let socket
        else {

            completion(
                GameSocketAck(
                    success: false,
                    requestID: nil,
                    revision: nil,
                    message: "Socket is not connected.",
                    errorCode: "socket_not_connected"
                )
            )

            return
        }

        do {

            let dictionary =
                try encodeDictionary(
                    payload
                )

            socket
                .emitWithAck(
                    event.rawValue,
                    dictionary
                )
                .timingOut(
                    after:
                        backendConfiguration.ackTimeout
                ) { [weak self] data in

                    Task { @MainActor in

                        guard let self else {
                            return
                        }

                        let ack =
                            self.decodeAck(
                                data
                            )

                        completion(
                            ack
                        )
                    }
                }

        } catch {

            completion(
                GameSocketAck(
                    success: false,
                    requestID: nil,
                    revision: nil,
                    message: error.localizedDescription,
                    errorCode: "encoding_failed"
                )
            )
        }
    }


    func queueMutation(
        event: GameSocketOutgoingEvent,
        requestID: UUID,
        encodedEnvelope: Data
    ) {

        guard !queuedSocketMutations.contains(
            where: {
                $0.requestID == requestID
            }
        ) else {
            return
        }

        queuedSocketMutations.append(
            GameQueuedSocketMutation(
                id:
                    UUID(),
                event:
                    event.rawValue,
                requestID:
                    requestID,
                mapDate:
                    mapDate(
                        inEncodedEnvelope:
                            encodedEnvelope
                    )
                    ?? currentMapDateString,
                encodedEnvelope:
                    encodedEnvelope,
                queuedAt:
                    Date()
            )
        )

        persistQueuedSocketMutations()
    }


    func flushQueuedSocketMutations() {

        guard canEmitApplicationEvents,
              inFlightMutationRequestIDs.isEmpty
        else {
            return
        }

        let pendingIndices =
            queuedSocketMutations
                .indices
                .filter { index in
                    queuedSocketMutations[index].mapDate
                    == currentMapDateString
                }

        guard let index =
            pendingIndices.min(
                by: { lhs, rhs in
                    queuedSocketMutations[lhs].queuedAt
                    < queuedSocketMutations[rhs].queuedAt
                }
            )
        else {
            return
        }

        let mutation =
            queuedSocketMutations[index]

        do {

            let rebasedEnvelope =
                try rebasedMutationEnvelope(
                    mutation.encodedEnvelope,
                    clientRevision:
                        serverRevision
                )

            queuedSocketMutations[index] =
                GameQueuedSocketMutation(
                    id:
                        mutation.id,
                    event:
                        mutation.event,
                    requestID:
                        mutation.requestID,
                    mapDate:
                        mutation.mapDate,
                    encodedEnvelope:
                        rebasedEnvelope,
                    queuedAt:
                        mutation.queuedAt
                )

            persistQueuedSocketMutations()

            sendEncodedMutation(
                event:
                    mutation.event,
                requestID:
                    mutation.requestID,
                encodedEnvelope:
                    rebasedEnvelope
            )

        } catch {

            // A locally corrupted outbox entry can never succeed. Remove only
            // that entry, keep the remaining queue, and continue draining.
            queuedSocketMutations.remove(
                at:
                    index
            )

            persistQueuedSocketMutations()

            lastBackendError =
                "Unable to rebase queued backend mutation: \(error.localizedDescription)"

            flushQueuedSocketMutations()
        }
    }


    func loadQueuedSocketMutations() {

        guard backendConfiguration.isEnabled,
              let data =
                UserDefaults.standard.data(
                    forKey:
                        mutationOutboxStorageKey
                )
        else {

            queuedSocketMutations = []
            return
        }

        do {

            queuedSocketMutations =
                try makeJSONDecoder()
                    .decode(
                        [GameQueuedSocketMutation].self,
                        from:
                            data
                    )
                    .sorted {
                        $0.queuedAt < $1.queuedAt
                    }

        } catch {

            queuedSocketMutations = []
            lastBackendError =
                "Unable to restore queued backend mutations: \(error.localizedDescription)"
        }
    }


    func persistQueuedSocketMutations() {

        let defaults =
            UserDefaults.standard

        guard !queuedSocketMutations.isEmpty else {

            defaults.removeObject(
                forKey:
                    mutationOutboxStorageKey
            )

            return
        }

        do {

            let data =
                try makeJSONEncoder()
                    .encode(
                        queuedSocketMutations
                    )

            defaults.set(
                data,
                forKey:
                    mutationOutboxStorageKey
            )

        } catch {

            lastBackendError =
                "Unable to persist queued backend mutations: \(error.localizedDescription)"
        }
    }


    var mutationOutboxStorageKey: String {

        "fifoo.gameMutationOutbox.v1.\(backendConfiguration.userID)"
    }


    func mapDate(
        inEncodedEnvelope data: Data
    ) -> String? {

        guard let object =
                try? JSONSerialization.jsonObject(
                    with:
                        data
                ) as? [String: Any],
              let context =
                object["context"] as? [String: Any]
        else {
            return nil
        }

        return context["mapDate"] as? String
    }


    func rebasedMutationEnvelope(
        _ data: Data,
        clientRevision: Int
    ) throws -> Data {

        let object =
            try JSONSerialization.jsonObject(
                with:
                    data
            )

        guard var envelope =
                object as? [String: Any],
              var context =
                envelope["context"] as? [String: Any]
        else {
            throw GameSocketEncodingError.expectedDictionary
        }

        context["clientRevision"] =
            max(0, clientRevision)

        context["sentAt"] =
            ISO8601DateFormatter()
                .string(
                    from:
                        Date()
                )

        envelope["context"] =
            context

        return try JSONSerialization.data(
            withJSONObject:
                envelope
        )
    }


    func shouldRetryMutation(
        after ack: GameSocketAck
    ) -> Bool {

        guard !ack.success else {
            return false
        }

        switch ack.errorCode {

        case "ack_timeout_or_invalid",
             "socket_not_connected",
             "server_error",
             "database_unavailable",
             "conflict":

            return true

        default:
            return false
        }
    }


    func sendEncodedMutation(
        event: String,
        requestID: UUID,
        encodedEnvelope: Data
    ) {

        guard canEmitApplicationEvents,
              let socket,
              !inFlightMutationRequestIDs.contains(
                requestID
              )
        else {
            return
        }

        inFlightMutationRequestIDs.insert(
            requestID
        )

        do {

            let object =
                try JSONSerialization.jsonObject(
                    with:
                        encodedEnvelope
                )

            guard let dictionary =
                object as? [String: Any]
            else {

                throw GameSocketEncodingError.expectedDictionary
            }

            socket
                .emitWithAck(
                    event,
                    dictionary
                )
                .timingOut(
                    after:
                        backendConfiguration.ackTimeout
                ) { [weak self] data in

                    Task { @MainActor in

                        guard let self else {
                            return
                        }

                        let ack =
                            self.decodeAck(
                                data
                            )

                        self.inFlightMutationRequestIDs.remove(
                            requestID
                        )

                        #if DEBUG
                        print(
                            "Socket mutation ack:",
                            event,
                            "success=\(ack.success)",
                            "revision=\(ack.revision.map { String($0) } ?? "nil")",
                            "error=\(ack.errorCode ?? "nil")",
                            "message=\(ack.message ?? "nil")"
                        )
                        #endif

                        if ack.success {

                            self.queuedSocketMutations.removeAll {
                                $0.requestID == requestID
                            }

                            self.persistQueuedSocketMutations()

                            self.updateRevisionIfNeeded(
                                ack.revision
                            )

                            self.lastBackendError =
                                nil

                            // Drain exactly one mutation at a time. The ack's
                            // revision becomes the base revision for the next
                            // queued request.
                            self.flushQueuedSocketMutations()

                        } else {

                            self.lastBackendError =
                                ack.message
                                ?? "Server rejected \(event)."

                            if self.shouldRetryMutation(
                                after:
                                    ack
                            ) {

                                // It was persisted before first send, so leave
                                // it in the durable outbox for reconnect replay.
                                if !self.queuedSocketMutations.contains(
                                    where: {
                                        $0.requestID == requestID
                                    }
                                ) {

                                    self.queuedSocketMutations.append(
                                        GameQueuedSocketMutation(
                                            id:
                                                UUID(),
                                            event:
                                                event,
                                            requestID:
                                                requestID,
                                            mapDate:
                                                self.mapDate(
                                                    inEncodedEnvelope:
                                                        encodedEnvelope
                                                )
                                                ?? self.currentMapDateString,
                                            encodedEnvelope:
                                                encodedEnvelope,
                                            queuedAt:
                                                Date()
                                        )
                                    )
                                }

                                self.persistQueuedSocketMutations()

                                if ack.errorCode == "conflict" {

                                    // Another device or request advanced the
                                    // Day Map. Stop application mutations,
                                    // fetch the authoritative snapshot, then
                                    // rebase/replay this same request ID.
                                    self.hasReceivedInitialSnapshot =
                                        false

                                    self.requestInitialGameSnapshot()
                                }

                            } else {

                                // Validation/authorization/not-found failures are
                                // terminal for this exact payload. Remove the
                                // optimistic local result by reconciling with the
                                // server before continuing the rest of the queue.
                                self.queuedSocketMutations.removeAll {
                                    $0.requestID == requestID
                                }

                                self.persistQueuedSocketMutations()

                                self.hasReceivedInitialSnapshot =
                                    false

                                self.requestInitialGameSnapshot()
                            }
                        }
                    }
                }

        } catch {

            inFlightMutationRequestIDs.remove(
                requestID
            )

            queuedSocketMutations.removeAll {
                $0.requestID == requestID
            }

            persistQueuedSocketMutations()

            lastBackendError =
                "Unable to send \(event): \(error.localizedDescription)"

            // The encoded outbox entry is locally unusable; reconcile any
            // optimistic UI and allow the remaining queue to continue.
            hasReceivedInitialSnapshot =
                false

            requestInitialGameSnapshot()
        }
    }


    func encodeDictionary<Value: Encodable>(
        _ value: Value
    ) throws -> [String: Any] {

        let data =
            try makeJSONEncoder()
                .encode(
                    value
                )

        let object =
            try JSONSerialization.jsonObject(
                with:
                    data
            )

        guard let dictionary =
            object as? [String: Any]
        else {
            throw GameSocketEncodingError.expectedDictionary
        }

        return dictionary
    }


    func decodeFirstPayload<Value: Decodable>(
        _ data: [Any],
        as type: Value.Type
    ) -> Value? {

        guard let first =
            data.first
        else {
            return nil
        }

        do {

            let jsonData =
                try JSONSerialization.data(
                    withJSONObject:
                        first
                )

            return try makeJSONDecoder()
                .decode(
                    Value.self,
                    from:
                        jsonData
                )

        } catch {

            lastBackendError =
                "Unable to decode server payload: \(error.localizedDescription)"

            #if DEBUG
            print(
                "Socket payload decode error:",
                error
            )
            #endif

            return nil
        }
    }


    func decodeAck(
        _ data: [Any]
    ) -> GameSocketAck {

        if let ack:
            GameSocketAck =
                decodeFirstPayload(
                    data,
                    as:
                        GameSocketAck.self
                ) {

            return ack
        }

        return GameSocketAck(
            success: false,
            requestID: nil,
            revision: nil,
            message: "No valid acknowledgement received before timeout.",
            errorCode: "ack_timeout_or_invalid"
        )
    }


    func emitWorkoutMutation(
        event: GameSocketOutgoingEvent
    ) {

        emitMutation(
            event:
                event,
            payload:
                GameWorkoutMutationPayload(
                    workout:
                        workout
                )
        )
    }


    func emitWorkoutExerciseMutation(
        event: GameSocketOutgoingEvent,
        exerciseID: UUID
    ) {

        emitMutation(
            event:
                event,
            payload:
                GameWorkoutExerciseMutationPayload(
                    workoutID:
                        workout.id,
                    workoutExerciseID:
                        exerciseID,
                    workout:
                        workout
                )
        )
    }


    func sendWorkoutLiveMessageToBackend(
        _ text: String
    ) {

        emitMutation(
            event:
                .liveMessageSend,
            payload:
                GameWorkoutLiveMessageSendPayload(
                    workoutID:
                        workout.id,
                    workoutExerciseID:
                        workout.currentWorkoutExerciseID,
                    message:
                        text,
                    createdAt:
                        Date()
                )
        )
    }


    func sendWorkoutReactionToBackend(
        _ emoji: String
    ) {

        emitMutation(
            event:
                .liveReactionSend,
            payload:
                GameWorkoutLiveReactionSendPayload(
                    workoutID:
                        workout.id,
                    workoutExerciseID:
                        workout.currentWorkoutExerciseID,
                    emoji:
                        emoji,
                    createdAt:
                        Date()
                )
        )
    }


    func emitCurrentRouteDraftState() {

        emitEvent(
            event:
                .routeDraftUpdate,
            payload:
                GameRouteDraftUpdatePayload(
                    draft:
                        GameFutureRouteDraftPayload(
                            draft:
                                gameStore.futureRouteDraft
                        )
                )
        )
    }


    func emitCurrentRoutePreviewState() {

        let payload =
            gameStore.futureRoutePreview.map {
                GameFutureRoutePreviewPayload(
                    preview:
                        $0
                )
            }

        emitEvent(
            event:
                .routePreviewUpdate,
            payload:
                GameRoutePreviewUpdatePayload(
                    preview:
                        payload
                )
        )
    }


    func emitCurrentRouteSelection(
        routeID: RouteID
    ) {

        emitMutation(
            event:
                .routeSelect,
            payload:
                GameRouteSelectionPayload(
                    selectedRouteID:
                        routeID,
                    completedRoute:
                        GameCompletedRoutePayload(
                            completedRoute:
                                gameStore.routeState.completedRoute
                        ),
                    currentDayTime:
                        gameStore.currentDayTime
                )
        )
    }


    func emitCurrentRouteCommit() {

        emitMutation(
            event:
                .routePreviewCommit,
            payload:
                GameRouteCommitPayload(
                    routeState:
                        GameDayRouteStatePayload(
                            routeState:
                                gameStore.routeState
                        )
                )
        )
    }


    func updateRevisionIfNeeded(
        _ revision: Int?
    ) {

        guard let revision else {
            return
        }

        serverRevision =
            max(
                serverRevision,
                revision
            )
    }
}


private enum GameSocketEncodingError:
    Error {

    case expectedDictionary
}


// MARK: - Message Mutation

extension SocketManager {

    func addLiveMessage(
        _ message: WorkoutLiveMessage
    ) {

        guard !liveMessages.contains(
            where: {
                $0.id == message.id
            }
        )
        else {
            return
        }


        liveMessages.append(
            message
        )

        trimLiveMessagesIfNeeded()
    }


    func clearLiveMessages() {

        liveMessages.removeAll()
    }
}


// MARK: - Reaction Mutation

extension SocketManager {

    func addLiveReaction(
        _ reaction: WorkoutLiveReaction
    ) {

        guard !liveReactions.contains(
            where: {
                $0.id == reaction.id
            }
        )
        else {
            return
        }


        liveReactions.append(
            reaction
        )

        trimLiveReactionsIfNeeded()
    }


    func clearLiveReactions() {

        liveReactions.removeAll()
    }
}


// MARK: - Trimming

private extension SocketManager {

    func trimLiveMessagesIfNeeded() {

        guard liveMessages.count >
                maximumStoredMessages
        else {
            return
        }


        liveMessages.removeFirst(
            liveMessages.count -
                maximumStoredMessages
        )
    }


    func trimLiveReactionsIfNeeded() {

        guard liveReactions.count >
                maximumStoredReactions
        else {
            return
        }


        liveReactions.removeFirst(
            liveReactions.count -
                maximumStoredReactions
        )
    }
}


// MARK: - Development Sample Data

private extension SocketManager {

    static var emptyWorkout: Workout {

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


    static let sample = Workout(
        name: "Full Body Workout",
        description: "Full body strength and cardio workout.",
        exercises: [
            
            WorkoutExercise(
                exerciseId: UUID(),
                name: "Barbell Bench Press",
                media: ExerciseMedia(
                    mediaType: .image,
                    url: URL(
                        string: "https://res.cloudinary.com/dgowl1p3x/image/upload/v1786605546/workout_photos/bench_press.jpg"
                    )!
                ),
                exerciseCategory: .strength,
                equipment: [.barbell, .bench],
                sets: 4,
                reps: 10,
                duration: 30,
                durationUnit: .seconds,
                minDuration: 18,
                status: .notStarted,
                weight: 135,
                instructions: ExerciseInstructions(
                    
                    demoVideoURL: URL(
                        string: "https://example.com/videos/squat-demo.mp4"
                    ),
                    
                    steps: [
                        
                        ExerciseInstructionStep(
                            stepNumber: 1,
                            instruction: "Stand with your feet about shoulder-width apart.",
                            detail: "Keep your toes pointed slightly outward."
                        ),
                        
                        ExerciseInstructionStep(
                            stepNumber: 2,
                            instruction: "Brace your core and keep your chest upright.",
                            detail: "Keep your spine neutral throughout the movement."
                        ),
                        
                        ExerciseInstructionStep(
                            stepNumber: 3,
                            instruction: "Push your hips back and bend your knees.",
                            detail: "Lower yourself under control as if sitting into a chair."
                        ),
                        
                        ExerciseInstructionStep(
                            stepNumber: 4,
                            instruction: "Lower until you reach a comfortable squat depth.",
                            detail: "Keep your knees tracking in the same direction as your toes."
                        ),
                        
                        ExerciseInstructionStep(
                            stepNumber: 5,
                            instruction: "Push through your feet to return to standing.",
                            detail: "Extend your hips and knees together."
                        )
                    ]
                )
            ),
            
            WorkoutExercise(
                exerciseId: UUID(),
                name: "Plank",
                media: ExerciseMedia(
                    mediaType: .image,
                    url: URL(
                        string: "https://picsum.photos/id/1016/1200/1800"
                    )!
                ),
                exerciseCategory: .strength,
                equipment: [.none],
                sets: 3,
                duration: 45,
                durationUnit: .seconds,
                minDuration: 20,
                status: .notStarted
            ),
            
            WorkoutExercise(
                exerciseId: UUID(),
                name: "Treadmill Run",
                media: ExerciseMedia(
                    mediaType: .image,
                    url: URL(
                        string: "https://res.cloudinary.com/dgowl1p3x/image/upload/v1786605772/workout_photos/treadmill.jpg"
                    )!
                ),
                exerciseCategory: .cardio,
                equipment: [.treadmill],
                duration: 15,
                durationUnit: .minutes,
                minDuration: 630,
                distance: 1.5,
                distanceUnit: .miles,
                status: .notStarted
            )
        ],
        status: WorkoutStatus.notStarted
    )
}

private extension SocketManager {

    static var sampleLiveMessages:
        [WorkoutLiveMessage] {

        [
            WorkoutLiveMessage(
                username: "Sarah",
                message:
                    "Let's go!! 🔥"
            ),

            WorkoutLiveMessage(
                username: "Mike",
                message:
                    "You've got this 💪"
            ),

            WorkoutLiveMessage(
                username: "Coach Alex",
                message:
                    "Keep your core tight"
            ),

            WorkoutLiveMessage(
                username: "James",
                message:
                    "🔥🔥🔥"
            ),

            WorkoutLiveMessage(
                username: "Lisa",
                message:
                    "You got this!"
            )
        ]
    }
}


// =====================================================
// MARK: - Day Map Date Selection
// =====================================================

extension SocketManager {

    /// Called by the calendar title button before the DatePicker sheet opens.
    func dayMapDatePickerOpened() {

        recordApplicationAction(
            .dayMapDatePickerOpened,
            metadata: [
                "mapDate":
                    currentMapDateString
            ]
        )
    }


    /// Changes the Day Map being viewed and refreshes backend state for that
    /// date. The date is normalized to the start of its local calendar day so
    /// the value remains date-only from the application's perspective.
    func selectDayMapDate(
        _ date: Date
    ) {

        let normalized =
            Self.normalizedDayMapDate(
                date,
                timeZoneIdentifier:
                    gameStore.clockTimeZoneIdentifier
            )

        let previous =
            currentMapDateString

        selectedDayMapDate =
            normalized

        let changed =
            previous != currentMapDateString

        // Keep the legacy AppManager bridge synchronized while remaining
        // compatible with any unfinished non-map views that still read it.
        AppManager.shared.selectedDate =
            normalized

        recordApplicationAction(
            .dayMapDateSelected,
            metadata: [
                "previousMapDate": previous,
                "mapDate": currentMapDateString
            ]
        )

        guard changed else {
            return
        }

        reloadSelectedDayMap()
    }


    func selectTodayDayMap() {

        let today =
            Self.normalizedDayMapDate(
                Date(),
                timeZoneIdentifier:
                    gameStore.clockTimeZoneIdentifier
            )

        recordApplicationAction(
            .dayMapTodaySelected,
            metadata: [
                "mapDate":
                    currentMapDateString
            ]
        )

        selectDayMapDate(
            today
        )
    }


    func selectPreviousDayMap() {

        selectRelativeDayMap(
            offset: -1
        )
    }


    func selectNextDayMap() {

        selectRelativeDayMap(
            offset: 1
        )
    }


    /// Re-fetches/rebuilds the currently selected Day Map without changing
    /// its calendar date.
    func refreshSelectedDayMap() {

        recordApplicationAction(
            .dayMapRefreshRequested,
            metadata: [
                "mapDate":
                    currentMapDateString
            ]
        )

        reloadSelectedDayMap()
    }


    var isViewingTodayDayMap: Bool {

        let timeZone =
            TimeZone(
                identifier:
                    gameStore.clockTimeZoneIdentifier
            )
            ?? .current

        var calendar =
            Calendar(identifier: .gregorian)

        calendar.timeZone =
            timeZone

        return calendar.isDateInToday(
            selectedDayMapDate
        )
    }
}


private extension SocketManager {

    func selectRelativeDayMap(
        offset: Int
    ) {

        let timeZone =
            TimeZone(
                identifier:
                    gameStore.clockTimeZoneIdentifier
            )
            ?? .current

        var calendar =
            Calendar(identifier: .gregorian)

        calendar.timeZone =
            timeZone

        guard let date =
            calendar.date(
                byAdding: .day,
                value: offset,
                to: selectedDayMapDate
            )
        else {
            return
        }

        selectDayMapDate(
            date
        )
    }


    func reloadSelectedDayMap() {

        // A newly selected day has its own independent server revision.
        serverRevision = 0
        hasReceivedInitialSnapshot = false
        lastBackendError = nil

        guard backendConfiguration.isEnabled else {

            // Local/demo mode has no historical backend yet. Keep the
            // currently rendered fixture usable while updating the shared
            // calendar context immediately.
            isDayMapLoading = false
            rebuildSearchResults()
            return
        }

        isDayMapLoading = true

        gameStore.prepareSuggestedPathStopsForDayReload()

        // If disconnected, authentication/reconnect will request the currently
        // selected date automatically. If connected, request it now.
        requestInitialGameSnapshot()
        requestInitialPlayData()
    }


    static func normalizedDayMapDate(
        _ date: Date,
        timeZoneIdentifier: String
    ) -> Date {

        let timeZone =
            TimeZone(
                identifier:
                    timeZoneIdentifier
            )
            ?? .current

        var calendar =
            Calendar(identifier: .gregorian)

        calendar.timeZone =
            timeZone

        return calendar.startOfDay(
            for: date
        )
    }
}


// =====================================================
// MARK: - Step 1 Application Action Gateway
// =====================================================

extension SocketManager {

    /// Default coordinate used when the user opens Add Node from the bottom
    /// app toolbar instead of tapping a road/intersection.
    var defaultNewNodeCoordinate: MapCoordinate {

        MapCoordinate(
            time:
                gameStore.currentDayTime,
            progress:
                MapProgress(50)
        )
    }


    func prepareDayMapForPresentation() {

        gameStore.startClock()

        #if DEBUG
        // Keep all development/demo data setup outside SwiftUI views.
        // This is intentionally DEBUG-only so a production build does not
        // replace backend/persisted route state with a render fixture.
        if !backendConfiguration.isEnabled,
           !didInstallDebugDayMapFixture {

            didInstallDebugDayMapFixture = true

            gameStore.useSimulatedClock(
                speed: 60
            )

            gameStore.resetSimulationDay(
                to:
                    DayTime(
                        secondsFromMidnight:
                            8 * 3600
                    )
            )

            gameStore.printDebugRouteVertices()
            gameStore.installDebugRouteScenario()

            _ = gameStore.installRouteRenderDemo(
                .fullDayAllStates
            )
        }
        #endif
    }


    func dayMapDidDisappear() {

        gameStore.stopClock()
    }


    func startDayMapGameClock() {

        gameStore.startGameClock()
    }


    func stopDayMapGameClock() {

        gameStore.stopGameClock()
    }
}


// =====================================================
// MARK: - Node Actions
// =====================================================

extension SocketManager {

    /// First tap on a hidden card is a reveal action, not a background tap.
    /// GameStore performs the optimistic local transition; Step 2 now emits an
    /// acknowledged reveal mutation so discovery state can reconcile cross-device.
    func handleDayTileReveal(
        cellID: GridCellID,
        nodeID: GameNodeID?
    ) {

        var metadata: [String: String] = [
            "column":
                String(cellID.column),
            "row":
                String(cellID.row)
        ]

        if let nodeID {
            metadata["nodeId"] =
                nodeID.rawValue.uuidString
        }

        recordApplicationAction(
            .tileRevealed,
            metadata: metadata
        )

        emitMutation(
            event:
                .tileReveal,
            payload:
                GameTileRevealMutationPayload(
                    cell:
                        GameTileCellPayload(
                            cellID: cellID
                        ),
                    nodeID:
                        nodeID,
                    isRevealed:
                        true
                )
        )
    }


    /// Central entry point for tapping an existing game node. The scene uses
    /// this before GameStore resolves which presentation/action should open.
    func handleGameNodeTap(
        nodeID: GameNodeID
    ) {

        let node =
            gameStore.gameNode(
                id:
                    nodeID
            )

        recordApplicationAction(
            .nodeTapped,
            metadata:
                node.map(nodeMetadata)
                ?? [
                    "nodeId":
                        nodeID.rawValue.uuidString
                ]
        )
    }


    /// Records that the Add Node workflow was opened at a semantic map
    /// coordinate. Presentation remains a SwiftUI concern; the coordinate and
    /// eventual node draft originate in this application layer.
    func nodeCreationSheetOpened(
        at coordinate: MapCoordinate
    ) {

        recordApplicationAction(
            .nodeCreationOpened,
            metadata:
                coordinateMetadata(
                    coordinate
                )
        )
    }


    func pathStopTapped(
        cellID: GridCellID,
        coordinate: MapCoordinate
    ) {

        recordPathStopAction(
            .pathStopTapped,
            cellID: cellID,
            coordinate: coordinate
        )
    }


    func suggestedStopViewed(
        cellID: GridCellID,
        coordinate: MapCoordinate
    ) {

        recordPathStopAction(
            .suggestedStopViewed,
            cellID: cellID,
            coordinate: coordinate
        )
    }


    func suggestedStopEditOpened(
        cellID: GridCellID,
        coordinate: MapCoordinate
    ) {

        recordPathStopAction(
            .suggestedStopEditOpened,
            cellID: cellID,
            coordinate: coordinate
        )
    }


    func suggestedStopAccepted(
        cellID: GridCellID,
        coordinate: MapCoordinate
    ) {

        recordPathStopAction(
            .suggestedStopAccepted,
            cellID: cellID,
            coordinate: coordinate
        )

        gameStore.markSuggestedPathStopConsumed(
            cellID
        )

        emitMutation(
            event:
                .suggestedStopDecision,
            payload:
                GameSuggestedStopDecisionPayload(
                    cell:
                        GameTileCellPayload(
                            cellID: cellID
                        ),
                    decision:
                        .accepted
                )
        )
    }


    func suggestedStopRejected(
        cellID: GridCellID,
        coordinate: MapCoordinate
    ) {

        recordPathStopAction(
            .suggestedStopRejected,
            cellID: cellID,
            coordinate: coordinate
        )

        gameStore.markSuggestedPathStopConsumed(
            cellID
        )

        emitMutation(
            event:
                .suggestedStopDecision,
            payload:
                GameSuggestedStopDecisionPayload(
                    cell:
                        GameTileCellPayload(
                            cellID: cellID
                        ),
                    decision:
                        .rejected
                )
        )
    }


    /// App/backend hook for installing actual suggestion content on an empty
    /// path card. No local fallback is fabricated when this has not been set.
    func provideSuggestedPathStop(
        _ content: GameNodeContent,
        for cellID: GridCellID
    ) {

        gameStore.setSuggestedPathStop(
            SuggestedPathStop(
                content: content
            ),
            for: cellID
        )
    }


    func clearSuggestedPathStop(
        for cellID: GridCellID
    ) {

        gameStore.clearSuggestedPathStop(
            for: cellID
        )
    }


    private func recordPathStopAction(
        _ action: ApplicationActionName,
        cellID: GridCellID,
        coordinate: MapCoordinate
    ) {

        var metadata =
            coordinateMetadata(
                coordinate
            )

        metadata["column"] =
            String(cellID.column)

        metadata["row"] =
            String(cellID.row)

        recordApplicationAction(
            action,
            metadata: metadata
        )
    }


    /// Creates the initial domain draft for Meal / Workout / Task / Tip /
    /// Request. This function is intentionally side-effect free. SwiftUI may
    /// construct navigation destinations more than once, so draft construction
    /// must never publish observable state or record an application action.
    func makeNewGameNodeDraft(
        addType: AddGameNodeType,
        coordinate: MapCoordinate
    ) -> GameMapNode {

        GameNodeFactory.make(
            addType:
                addType,
            coordinate:
                coordinate
        )
    }


    /// Records the user's actual selection of a creation type. This is kept
    /// separate from draft construction so view/destination evaluation cannot
    /// accidentally create an observation/render loop.
    func nodeCreationTypeSelected(
        addType: AddGameNodeType,
        coordinate: MapCoordinate
    ) {

        let draft =
            GameNodeFactory.make(
                addType:
                    addType,
                coordinate:
                    coordinate
            )

        var metadata =
            coordinateMetadata(
                coordinate
            )

        metadata["addType"] =
            addType.rawValue

        metadata["nodeKind"] =
            draft.content.kind.rawValue

        recordApplicationAction(
            .nodeCreationTypeSelected,
            metadata:
                metadata
        )
    }


    func addGameNode(
        _ node: GameMapNode,
        attachToExistingPath: Bool = false
    ) {

        gameStore.addGameNode(
            node
        )

        // GameStore may canonicalize placement-derived values while adding a
        // node (for example a road-vertex time). Persist and route the exact
        // version that is now the local source of truth rather than the
        // pre-insertion draft supplied by the editor.
        let storedNode =
            gameStore.gameNode(
                id: node.id
            )
            ?? node

        var metadata =
            nodeMetadata(
                storedNode
            )

        metadata["attachToExistingPath"] =
            attachToExistingPath
            ? "true"
            : "false"

        recordApplicationAction(
            .nodeAdded,
            metadata:
                metadata
        )

        let attachedAnchor =
            GameNodeRouteAnchorResolver()
                .resolve(
                    node: storedNode,
                    graph: gameStore.roadGraph
                )

        // Backend route attachment is only valid for a future routable stop.
        // If the user edited the stop time while the Add Stop flow was open,
        // never let that make persistence depend on a route validation error:
        // save the node normally instead.
        let isFutureRoutableStop =
            attachedAnchor.map {
                $0.nodeCoordinate.time
                    > gameStore.currentDayTime
            }
            ?? false

        // When there is no path yet, the first future routable addition gives
        // the backend enough data to create the authoritative initial path.
        // When a path already exists, only the explicit Attach choice rebuilds
        // it.
        let shouldBuildOrAttachPath =
            isFutureRoutableStop
            &&
            (
                attachToExistingPath
                ||
                !gameStore.routeState.hasChosenFutureRoute
            )

        if shouldBuildOrAttachPath {

            emitMutation(
                event:
                    .routeAttachNode,
                payload:
                    GameRouteAttachNodePayload(
                        node: storedNode,
                        roadGraph: gameStore.roadGraph,
                        nodeAnchors: backendRouteNodeAnchors(),
                        attachedNodeAnchor:
                            attachedAnchor.map {
                                GameBackendRouteNodeAnchorPayload(
                                    anchor: $0
                                )
                            },
                        currentDayTime: gameStore.currentDayTime,
                        completedRoute:
                            GameCompletedRoutePayload(
                                completedRoute:
                                    gameStore.routeState.completedRoute
                            ),
                        maxAlternatives: 3
                    )
            )

        } else {

            emitMutation(
                event:
                    .nodeAdd,
                payload:
                    GameNodeMutationPayload(
                        node: storedNode
                    )
            )
        }
    }


    func updateGameNode(
        _ node: GameMapNode
    ) {

        persistNodeUpdate(
            node,
            actionName:
                .nodeUpdated
        )
    }


    func deleteGameNode(
        id: GameNodeID
    ) {

        let node =
            gameStore.gameNode(
                id: id
            )

        gameStore.deleteGameNode(
            id: id
        )

        recordApplicationAction(
            .nodeDeleted,
            metadata:
                node.map(nodeMetadata)
                ?? [
                    "nodeId":
                        id.rawValue.uuidString
                ]
        )

        emitMutation(
            event:
                .nodeDelete,
            payload:
                GameNodeDeletePayload(
                    nodeID: id
                )
        )
    }


    func handleActivityNodeAction(
        _ action: ActivityNodeEditorAction,
        node: GameMapNode
    ) {

        let actionName: ApplicationActionName

        switch action {
        case .join:
            actionName = .activityJoined

        case .skip:
            actionName = .activitySkipped

        case .completed:
            actionName = .activityCompleted
        }

        performActivityNodeMutation(
            action,
            node:
                node,
            actionName:
                actionName
        )
    }



    // MARK: - Add Stop Creation Actions

    func addMealBrowseOpened(
        at coordinate: MapCoordinate
    ) {

        recordApplicationAction(
            .addMealBrowseOpened,
            metadata:
                coordinateMetadata(
                    coordinate
                )
        )
    }


    func addMealBrowseQueryChanged(
        _ query: String
    ) {

        recordApplicationAction(
            .addMealBrowseQueryChanged,
            metadata: [
                "queryLength":
                    String(query.count)
            ]
        )
    }


    func addMealSelected(
        mealID: String,
        title: String,
        source: String
    ) {

        recordApplicationAction(
            .addMealSelected,
            metadata: [
                "mealId":
                    mealID,
                "title":
                    title,
                "source":
                    source
            ]
        )
    }


    func addMealPhotoSelected() {

        recordApplicationAction(
            .addMealPhotoSelected
        )
    }


    func addMealPhotoAnalyzed(
        suggestedTitle: String
    ) {

        recordApplicationAction(
            .addMealPhotoAnalyzed,
            metadata: [
                "suggestedTitle":
                    suggestedTitle
            ]
        )
    }


    func addWorkoutBrowseOpened(
        at coordinate: MapCoordinate
    ) {

        recordApplicationAction(
            .addWorkoutBrowseOpened,
            metadata:
                coordinateMetadata(
                    coordinate
                )
        )
    }


    func addWorkoutBrowseQueryChanged(
        _ query: String
    ) {

        recordApplicationAction(
            .addWorkoutBrowseQueryChanged,
            metadata: [
                "queryLength":
                    String(query.count)
            ]
        )
    }


    func addWorkoutSelected(
        workoutID: String,
        title: String,
        workoutType: ActivityWorkoutType
    ) {

        recordApplicationAction(
            .addWorkoutSelected,
            metadata: [
                "workoutId":
                    workoutID,
                "title":
                    title,
                "workoutType":
                    workoutType.rawValue
            ]
        )
    }


    func addStopMediaSelected(
        context: String,
        imageCount: Int,
        videoCount: Int
    ) {

        recordApplicationAction(
            .addStopMediaSelected,
            metadata: [
                "context":
                    context,
                "imageCount":
                    String(imageCount),
                "videoCount":
                    String(videoCount)
            ]
        )
    }


    func addStopMediaUploadStarted(
        context: String,
        itemCount: Int
    ) {

        recordApplicationAction(
            .addStopMediaUploadStarted,
            metadata: [
                "context":
                    context,
                "itemCount":
                    String(itemCount)
            ]
        )
    }


    func addStopMediaUploadCompleted(
        context: String,
        uploadedCount: Int
    ) {

        recordApplicationAction(
            .addStopMediaUploadCompleted,
            metadata: [
                "context":
                    context,
                "uploadedCount":
                    String(uploadedCount)
            ]
        )
    }


    func addStopMediaUploadFailed(
        context: String,
        message: String
    ) {

        recordApplicationAction(
            .addStopMediaUploadFailed,
            metadata: [
                "context":
                    context,
                "message":
                    message
            ]
        )
    }


    // MARK: - ActivityMeal Actions

    func updateActivityMeal(
        _ node: GameMapNode
    ) {

        persistNodeUpdate(
            node,
            actionName:
                .activityMealUpdated,
            socketEvent:
                .activityMealUpdate
        )
    }


    /// ActivityMeal Skip currently removes the stop from the map. Preserve
    /// that established product behavior while emitting the semantic Step 2
    /// mutation so the server can update meal/activity state and delete the stop.
    func skipActivityMealAndRemoveStop(
        _ node: GameMapNode
    ) {

        gameStore.deleteGameNode(
            id:
                node.id
        )

        recordApplicationAction(
            .activityMealSkipped,
            metadata:
                nodeMetadata(
                    node
                )
        )

        emitMutation(
            event:
                .activityMealSkip,
            payload:
                GameActivityMutationPayload(
                    action:
                        .skip,
                    node:
                        node
                )
        )
    }


    func completeActivityMeal(
        _ node: GameMapNode
    ) {

        performActivityNodeMutation(
            .completed,
            node:
                node,
            actionName:
                .activityMealCompleted,
            socketEventOverride:
                .activityMealComplete
        )
    }


    func activityMealResourceOpened(
        nodeID: GameNodeID,
        resource: ActivityMealResource
    ) {

        recordApplicationAction(
            .activityMealResourceOpened,
            metadata:
                applicationMetadata(
                    nodeID:
                        nodeID,
                    extra: [
                        "resource":
                            resource.rawValue
                    ]
                )
        )
    }


    func activityMealStepCompleted(
        nodeID: GameNodeID,
        stepID: String
    ) {

        recordApplicationAction(
            .activityMealStepCompleted,
            metadata:
                applicationMetadata(
                    nodeID:
                        nodeID,
                    extra: [
                        "stepId":
                            stepID
                    ]
                )
        )
    }


    func activityMealStepSkipped(
        nodeID: GameNodeID,
        stepID: String
    ) {

        recordApplicationAction(
            .activityMealStepSkipped,
            metadata:
                applicationMetadata(
                    nodeID:
                        nodeID,
                    extra: [
                        "stepId":
                            stepID
                    ]
                )
        )
    }


    func activityMealStepMovedBack(
        nodeID: GameNodeID,
        stepID: String
    ) {

        recordApplicationAction(
            .activityMealStepBack,
            metadata:
                applicationMetadata(
                    nodeID:
                        nodeID,
                    extra: [
                        "stepId":
                            stepID
                    ]
                )
        )
    }


    func activityMealSelectedMeal(
        nodeID: GameNodeID,
        mealID: String,
        title: String
    ) {

        recordApplicationAction(
            .activityMealSelected,
            metadata:
                applicationMetadata(
                    nodeID:
                        nodeID,
                    extra: [
                        "mealId":
                            mealID,
                        "title":
                            title
                    ]
                )
        )
    }


    func activityMealConfirmationChanged(
        nodeID: GameNodeID,
        isConfirmed: Bool
    ) {

        recordApplicationAction(
            .activityMealConfirmed,
            metadata:
                applicationMetadata(
                    nodeID:
                        nodeID,
                    extra: [
                        "isConfirmed":
                            String(isConfirmed)
                    ]
                )
        )
    }


    func activityMealSourceSelected(
        nodeID: GameNodeID,
        source: ActivityMealSource
    ) {

        recordApplicationAction(
            .activityMealSourceSelected,
            metadata:
                applicationMetadata(
                    nodeID:
                        nodeID,
                    extra: [
                        "source":
                            source.rawValue
                    ]
                )
        )
    }


    func activityMealRecipeSelected(
        nodeID: GameNodeID,
        recipeID: String,
        title: String
    ) {

        recordApplicationAction(
            .activityMealRecipeSelected,
            metadata:
                applicationMetadata(
                    nodeID:
                        nodeID,
                    extra: [
                        "recipeId":
                            recipeID,
                        "title":
                            title
                    ]
                )
        )
    }


    func activityMealIngredientsChanged(
        nodeID: GameNodeID,
        count: Int
    ) {

        recordApplicationAction(
            .activityMealIngredientsChanged,
            metadata:
                applicationMetadata(
                    nodeID:
                        nodeID,
                    extra: [
                        "count":
                            String(count)
                    ]
                )
        )
    }


    func activityMealIngredientsReadyChanged(
        nodeID: GameNodeID,
        isReady: Bool
    ) {

        recordApplicationAction(
            .activityMealIngredientsReadyChanged,
            metadata:
                applicationMetadata(
                    nodeID:
                        nodeID,
                    extra: [
                        "isReady":
                            String(isReady)
                    ]
                )
        )
    }


    func activityMealGroceriesNeededChanged(
        nodeID: GameNodeID,
        isNeeded: Bool
    ) {

        recordApplicationAction(
            .activityMealGroceriesNeededChanged,
            metadata:
                applicationMetadata(
                    nodeID:
                        nodeID,
                    extra: [
                        "isNeeded":
                            String(isNeeded)
                    ]
                )
        )
    }


    func activityMealShoppingListChanged(
        nodeID: GameNodeID,
        count: Int
    ) {

        recordApplicationAction(
            .activityMealShoppingListChanged,
            metadata:
                applicationMetadata(
                    nodeID:
                        nodeID,
                    extra: [
                        "count":
                            String(count)
                    ]
                )
        )
    }


    func activityMealIngredientStoreSelected(
        nodeID: GameNodeID,
        storeID: String,
        name: String
    ) {

        recordApplicationAction(
            .activityMealIngredientStoreSelected,
            metadata:
                applicationMetadata(
                    nodeID:
                        nodeID,
                    extra: [
                        "storeId":
                            storeID,
                        "name":
                            name
                    ]
                )
        )
    }


    func activityMealVenueSelected(
        nodeID: GameNodeID,
        venueID: String,
        name: String
    ) {

        recordApplicationAction(
            .activityMealVenueSelected,
            metadata:
                applicationMetadata(
                    nodeID:
                        nodeID,
                    extra: [
                        "venueId":
                            venueID,
                        "name":
                            name
                    ]
                )
        )
    }


    func activityMealFulfillmentSelected(
        nodeID: GameNodeID,
        mode: ActivityMealFulfillmentMode
    ) {

        recordApplicationAction(
            .activityMealFulfillmentSelected,
            metadata:
                applicationMetadata(
                    nodeID:
                        nodeID,
                    extra: [
                        "mode":
                            mode.rawValue
                    ]
                )
        )
    }


    func activityMealHostSelected(
        nodeID: GameNodeID,
        friendID: String,
        name: String
    ) {

        recordApplicationAction(
            .activityMealHostSelected,
            metadata:
                applicationMetadata(
                    nodeID:
                        nodeID,
                    extra: [
                        "friendId":
                            friendID,
                        "name":
                            name
                    ]
                )
        )
    }


    func activityMealInvitationChanged(
        nodeID: GameNodeID,
        isConfirmed: Bool
    ) {

        recordApplicationAction(
            .activityMealInvitationChanged,
            metadata:
                applicationMetadata(
                    nodeID:
                        nodeID,
                    extra: [
                        "isConfirmed":
                            String(isConfirmed)
                    ]
                )
        )
    }


    func activityMealContributionChanged(
        nodeID: GameNodeID,
        itemCount: Int
    ) {

        recordApplicationAction(
            .activityMealContributionChanged,
            metadata:
                applicationMetadata(
                    nodeID:
                        nodeID,
                    extra: [
                        "itemCount":
                            String(itemCount)
                    ]
                )
        )
    }


    func activityMealAddressChanged(
        nodeID: GameNodeID,
        hasAddress: Bool
    ) {

        recordApplicationAction(
            .activityMealAddressChanged,
            metadata:
                applicationMetadata(
                    nodeID:
                        nodeID,
                    extra: [
                        "hasAddress":
                            String(hasAddress)
                    ]
                )
        )
    }


    func activityMealExternalLinkOpened(
        nodeID: GameNodeID,
        destination: String
    ) {

        recordApplicationAction(
            .activityMealExternalLinkOpened,
            metadata:
                applicationMetadata(
                    nodeID:
                        nodeID,
                    extra: [
                        "destination":
                            destination
                    ]
                )
        )
    }


    // MARK: - ActivityWorkout Stop Actions

    func updateActivityWorkout(
        _ node: GameMapNode
    ) {

        persistNodeUpdate(
            node,
            actionName:
                .activityWorkoutUpdated,
            socketEvent:
                .activityWorkoutUpdate
        )
    }


    func activityWorkoutBrowseOpened(
        nodeID: GameNodeID,
        classesOnly: Bool
    ) {

        recordApplicationAction(
            classesOnly
            ? .activityWorkoutBrowseClassesOpened
            : .activityWorkoutBrowseOpened,
            metadata:
                applicationMetadata(
                    nodeID:
                        nodeID
                )
        )
    }


    func selectActivityWorkout(
        _ node: GameMapNode,
        selectedWorkoutID: String,
        selectedWorkoutType: ActivityWorkoutType
    ) {

        persistNodeUpdate(
            node,
            actionName:
                .activityWorkoutSelected,
            extraMetadata: [
                "selectedWorkoutId":
                    selectedWorkoutID,
                "selectedWorkoutType":
                    selectedWorkoutType.rawValue
            ],
            socketEvent:
                .activityWorkoutSelect
        )
    }


    func rescheduleIndependentActivityWorkout(
        _ node: GameMapNode
    ) {

        persistNodeUpdate(
            node,
            actionName:
                .activityWorkoutIndependentScheduleChanged,
            socketEvent:
                .activityWorkoutReschedule
        )
    }


    func activityWorkoutClassTimeEditAttempted(
        nodeID: GameNodeID
    ) {

        recordApplicationAction(
            .activityWorkoutClassTimeEditAttempted,
            metadata:
                applicationMetadata(
                    nodeID:
                        nodeID
                )
        )
    }


    func checkInActivityWorkoutClass(
        _ node: GameMapNode
    ) {

        persistNodeUpdate(
            node,
            actionName:
                .activityWorkoutClassCheckedIn,
            socketEvent:
                .activityWorkoutCheckIn
        )
    }


    // MARK: - ActivityTask Actions

    func updateActivityTask(
        _ node: GameMapNode
    ) {

        persistNodeUpdate(
            node,
            actionName:
                .activityTaskUpdated,
            socketEvent:
                .activityTaskUpdate
        )
    }


    /// Permanently removes an ActivityTask stop from the selected Day Map.
    /// Task deletion uses the generic authoritative node-delete contract; the
    /// backend scopes deletion to the authenticated user's current Day Map.
    func deleteActivityTask(
        _ node: GameMapNode
    ) {

        guard case let .activity(content) = node.content,
              content.resolvedActivityType == .task
        else {
            lastBackendError =
                "Cannot delete ActivityTask from a non-task node."
            return
        }

        deleteGameNode(
            id: node.id
        )
    }


    func rescheduleActivityTask(
        _ node: GameMapNode
    ) {

        persistNodeUpdate(
            node,
            actionName:
                .activityTaskScheduleChanged,
            socketEvent:
                .activityTaskReschedule
        )
    }


    func skipActivityTask(
        _ node: GameMapNode
    ) {

        performActivityNodeMutation(
            .skip,
            node:
                node,
            actionName:
                .activityTaskSkipped,
            socketEventOverride:
                .activityTaskSkip
        )
    }


    func completeActivityTask(
        _ node: GameMapNode
    ) {

        performActivityNodeMutation(
            .completed,
            node:
                node,
            actionName:
                .activityTaskCompleted,
            socketEventOverride:
                .activityTaskComplete
        )
    }


    // MARK: - Post Actions

    func respondToPost(
        _ node: GameMapNode
    ) {

        recordApplicationAction(
            .postRespond,
            metadata:
                nodeMetadata(
                    node
                )
        )
    }


    func submitPostReply(
        text: String,
        node: GameMapNode
    ) {

        let cleaned =
            text.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !cleaned.isEmpty else {
            return
        }

        recordApplicationAction(
            .postReplySubmitted,
            metadata:
                applicationMetadata(
                    nodeID:
                        node.id,
                    extra: [
                        "replyLength":
                            String(cleaned.count)
                    ]
                )
        )

        guard case let .post(content) = node.content else {

            lastBackendError =
                "Cannot submit a post reply from a non-post node."

            return
        }

        emitMutation(
            event:
                .postReplyCreate,
            payload:
                GamePostReplyCreatePayload(
                    nodeID:
                        node.id,
                    postID:
                        content.postID,
                    parentReplyID:
                        nil,
                    text:
                        cleaned,
                    createdAt:
                        Date()
                )
        )
    }


    func savePost(
        _ node: GameMapNode
    ) {

        var updatedNode =
            node

        if case var .post(content) = updatedNode.content,
           var snapshot = content.snapshot {

            if !snapshot.isSaved {
                snapshot.postSavedCount += 1
            }

            snapshot.savedPostStatus =
                "Saved"

            content.snapshot =
                snapshot

            updatedNode.content =
                .post(
                    content
                )

            gameStore.updateGameNode(
                updatedNode
            )
        }

        recordApplicationAction(
            .postSaved,
            metadata:
                nodeMetadata(
                    updatedNode
                )
        )

        emitMutation(
            event:
                .postSave,
            payload:
                GamePostSavePayload(
                    node:
                        updatedNode
                )
        )
    }


    func viewPostPoster(
        _ node: GameMapNode
    ) {

        recordApplicationAction(
            .postViewPoster,
            metadata:
                nodeMetadata(
                    node
                )
        )
    }


    func viewPostLinkedContent(
        _ linkedContent: PostNodeLinkedContent,
        node: GameMapNode
    ) {

        var metadata =
            nodeMetadata(
                node
            )

        metadata["linkedContent"] =
            linkedContent.title

        recordApplicationAction(
            .postViewLinkedContent,
            metadata:
                metadata
        )
    }


    // MARK: - User Stop Actions

    func openUserConversation(
        _ node: GameMapNode
    ) {

        gameStore.updateGameNode(
            node
        )

        recordApplicationAction(
            .userSendMessage,
            metadata:
                nodeMetadata(
                    node
                )
        )
    }


    func openUserProgress(
        _ node: GameMapNode
    ) {

        gameStore.updateGameNode(
            node
        )

        recordApplicationAction(
            .userViewProgress,
            metadata:
                nodeMetadata(
                    node
                )
        )
    }


    func handleUserNodeAction(
        _ action: UserNodeEditorAction,
        node: GameMapNode
    ) {

        switch action {
        case .sendMessage:
            openUserConversation(
                node
            )

        case .viewProgress:
            openUserProgress(
                node
            )
        }
    }



    func handlePostNodeAction(
        _ action: PostNodeViewAction,
        node: GameMapNode
    ) {

        switch action {
        case .respond:
            respondToPost(
                node
            )

        case let .submitReply(text):
            submitPostReply(
                text:
                    text,
                node:
                    node
            )

        case .save:
            savePost(
                node
            )

        case .viewPoster:
            viewPostPoster(
                node
            )

        case let .viewLinkedContent(linkedContent):
            viewPostLinkedContent(
                linkedContent,
                node:
                    node
            )
        }
    }



    // MARK: - Hyperlink Actions

    func upvoteHyperlink(
        _ node: GameMapNode
    ) {

        recordApplicationAction(
            .hyperlinkUpvoted,
            metadata:
                nodeMetadata(
                    node
                )
        )

        emitMutation(
            event:
                .hyperlinkVote,
            payload:
                GameHyperlinkVotePayload(
                    nodeID:
                        node.id,
                    vote:
                        .upvote
                )
        )
    }


    func downvoteHyperlink(
        _ node: GameMapNode
    ) {

        recordApplicationAction(
            .hyperlinkDownvoted,
            metadata:
                nodeMetadata(
                    node
                )
        )

        emitMutation(
            event:
                .hyperlinkVote,
            payload:
                GameHyperlinkVotePayload(
                    nodeID:
                        node.id,
                    vote:
                        .downvote
                )
        )
    }


    func handleHyperlinkNodeAction(
        _ action: HyperlinkNodeViewAction,
        node: GameMapNode
    ) {

        switch action {
        case .upvote:
            upvoteHyperlink(
                node
            )

        case .downvote:
            downvoteHyperlink(
                node
            )
        }
    }



    func openPlay() {

        isShowingPlay =
            true

        recordApplicationAction(
            .playOpened
        )
    }
}


// =====================================================
// MARK: - Route Actions
// =====================================================

extension SocketManager {

    func handleCompletedRouteTap() {

        recordApplicationAction(
            .completedRouteTapped
        )
    }


    func handleChosenRouteTap(
        routeID: RouteID
    ) {

        recordApplicationAction(
            .chosenRouteTapped,
            metadata: [
                "routeId":
                    routeID.rawValue.uuidString
            ]
        )
    }


    func handleAlternateRouteTap(
        routeID: RouteID
    ) {

        recordApplicationAction(
            .alternateRouteTapped,
            metadata: [
                "routeId":
                    routeID.rawValue.uuidString
            ]
        )
    }


    @discardableResult
    func chooseFutureRoute(
        routeID: RouteID
    ) -> Bool {

        if gameStore.routeState.chosenFutureRoute.id == routeID {
            return true
        }

        guard gameStore.routeState.alternativeRoutes.contains(
            where: { $0.id == routeID }
        ) else {
            return false
        }

        recordApplicationAction(
            .alternateRouteSelected,
            metadata: [
                "routeId":
                    routeID.rawValue.uuidString
            ]
        )

        // The client no longer constructs/switches route geometry. It sends
        // only the user's selected alternative and the latest completed-route
        // context; the backend performs the authoritative swap and broadcasts
        // the resulting route state.
        emitCurrentRouteSelection(
            routeID:
                routeID
        )

        return true
    }

    func beginNewFutureRouteDraft() {

        gameStore.beginNewFutureRouteDraft()

        recordApplicationAction(
            .routeDraftStarted
        )

        emitCurrentRouteDraftState()
    }


    @discardableResult
    func beginEditingChosenFutureRoute() -> Bool {

        let succeeded =
            gameStore.beginEditingChosenFutureRoute()

        if succeeded {

            recordApplicationAction(
                .routeDraftEditStarted,
                metadata: [
                    "routeId":
                        gameStore
                            .routeState
                            .chosenFutureRoute
                            .id
                            .rawValue
                            .uuidString
                ]
            )

            emitCurrentRouteDraftState()
        }

        return succeeded
    }


    @discardableResult
    func addFutureRouteStop(
        nodeID: GameNodeID
    ) -> Bool {

        let succeeded =
            gameStore.addStopToFutureRouteDraft(
                nodeID
            )

        if succeeded {

            recordApplicationAction(
                .routeDraftStopAdded,
                metadata: [
                    "nodeId":
                        nodeID.rawValue.uuidString
                ]
            )

            emitCurrentRouteDraftState()
        }

        return succeeded
    }


    @discardableResult
    func removeFutureRouteStop(
        nodeID: GameNodeID
    ) -> Bool {

        let succeeded =
            gameStore.removeStopFromFutureRouteDraft(
                nodeID:
                    nodeID
            )

        if succeeded {

            recordApplicationAction(
                .routeDraftStopRemoved,
                metadata: [
                    "nodeId":
                        nodeID.rawValue.uuidString
                ]
            )

            emitCurrentRouteDraftState()
        }

        return succeeded
    }


    @discardableResult
    func moveFutureRouteStop(
        from sourceIndex: Int,
        to destinationIndex: Int
    ) -> Bool {

        let succeeded =
            gameStore.moveFutureRouteDraftStop(
                from:
                    sourceIndex,
                to:
                    destinationIndex
            )

        if succeeded {

            recordApplicationAction(
                .routeDraftStopMoved,
                metadata: [
                    "fromIndex":
                        "\(sourceIndex)",
                    "toIndex":
                        "\(destinationIndex)"
                ]
            )

            emitCurrentRouteDraftState()
        }

        return succeeded
    }


    @discardableResult
    func reorderFutureRouteStops(
        fromIndices: [Int],
        toOffset: Int
    ) -> Bool {

        let succeeded =
            gameStore.moveFutureRouteDraftStops(
                fromIndices:
                    fromIndices,
                toOffset:
                    toOffset
            )

        if succeeded {

            recordApplicationAction(
                .routeDraftStopsReordered,
                metadata: [
                    "fromIndices":
                        fromIndices
                            .map(String.init)
                            .joined(separator: ","),
                    "toOffset":
                        "\(toOffset)"
                ]
            )

            emitCurrentRouteDraftState()
        }

        return succeeded
    }


    func cancelFutureRouteDraft() {

        gameStore.clearFutureRouteDraft()

        recordApplicationAction(
            .routeDraftCancelled
        )

        emitCurrentRouteDraftState()
    }


    @discardableResult
    func planFutureRouteDraft()
        -> FutureRouteDraftPlanningResult {

        let result =
            gameStore.planFutureRouteDraft()

        recordApplicationAction(
            .routePlanned,
            metadata: [
                "succeeded":
                    result.succeeded
                    ? "true"
                    : "false"
            ]
        )

        return result
    }


    @discardableResult
    func generateFutureRoutePreview(
        maxAlternatives: Int = 3
    ) -> Bool {

        let succeeded =
            gameStore.generateFutureRoutePreview(
                maxAlternatives:
                    maxAlternatives
            )

        recordApplicationAction(
            .routePreviewGenerated,
            metadata: [
                "succeeded":
                    succeeded
                    ? "true"
                    : "false",
                "maxAlternatives":
                    "\(maxAlternatives)"
            ]
        )

        if succeeded {
            emitCurrentRoutePreviewState()
        }

        return succeeded
    }


    @discardableResult
    func selectFutureRoutePreview(
        routeID: RouteID
    ) -> Bool {

        let succeeded =
            gameStore.selectFutureRoutePreview(
                routeID:
                    routeID
            )

        if succeeded {

            recordApplicationAction(
                .routePreviewSelected,
                metadata: [
                    "routeId":
                        routeID.rawValue.uuidString
                ]
            )

            emitCurrentRoutePreviewState()
        }

        return succeeded
    }


    @discardableResult
    func commitFutureRoutePreview()
        -> FutureRouteCommitResult {

        let result =
            gameStore.commitFutureRoutePreview()

        recordApplicationAction(
            .routePreviewCommitted,
            metadata: [
                "succeeded":
                    result.succeeded
                    ? "true"
                    : "false"
            ]
        )

        if result.succeeded {
            emitCurrentRouteCommit()
        }

        return result
    }


    func clearFutureRoutePreview() {

        gameStore.clearFutureRoutePreview()

        recordApplicationAction(
            .routePreviewCleared
        )

        emitCurrentRoutePreviewState()
    }
}


// =====================================================
// MARK: - Road / Empty Map Actions
// =====================================================

extension SocketManager {

    func handleMapBackgroundTap(
        coordinate: MapCoordinate
    ) {

        recordApplicationAction(
            .mapBackgroundTapped,
            metadata:
                coordinateMetadata(
                    coordinate
                )
        )

        emitEvent(
            event:
                .roadInteraction,
            payload:
                GameRoadInteractionPayload(
                    kind:
                        .background,
                    coordinate:
                        coordinate,
                    edgeID:
                        nil,
                    vertexID:
                        nil
                )
        )
    }


    func handleRoadTap(
        edgeID: RoadEdgeID,
        coordinate: MapCoordinate
    ) {

        var metadata =
            coordinateMetadata(
                coordinate
            )

        metadata["edgeId"] =
            edgeID.rawValue

        recordApplicationAction(
            .roadTapped,
            metadata:
                metadata
        )

        emitEvent(
            event:
                .roadInteraction,
            payload:
                GameRoadInteractionPayload(
                    kind:
                        .road,
                    coordinate:
                        coordinate,
                    edgeID:
                        edgeID,
                    vertexID:
                        nil
                )
        )
    }


    func handleIntersectionTap(
        vertexID: RoadVertexID,
        coordinate: MapCoordinate
    ) {

        var metadata =
            coordinateMetadata(
                coordinate
            )

        metadata["vertexId"] =
            vertexID.rawValue

        recordApplicationAction(
            .intersectionTapped,
            metadata:
                metadata
        )

        emitEvent(
            event:
                .roadInteraction,
            payload:
                GameRoadInteractionPayload(
                    kind:
                        .intersection,
                    coordinate:
                        coordinate,
                    edgeID:
                        nil,
                    vertexID:
                        vertexID
                )
        )
    }
}


// =====================================================
// MARK: - Backend Route Authority
// =====================================================

extension SocketManager {

    /// Requests initial path generation only when the authoritative snapshot
    /// contains no chosen path. The user never taps a Build/Create Path UI.
    func requestBackendGeneratedRouteIfNeeded() {

        guard
            backendConfiguration.isEnabled,
            hasReceivedInitialSnapshot,
            !gameStore.routeState.hasChosenFutureRoute,
            !gameStore.routeState.hasCompletedRoute
        else {
            return
        }

        let anchors =
            backendRouteNodeAnchors()

        guard !anchors.isEmpty else {
            return
        }

        emitMutation(
            event:
                .routeBuild,
            payload:
                GameBackendRouteBuildPayload(
                    roadGraph:
                        gameStore.roadGraph,
                    nodeAnchors:
                        anchors,
                    currentDayTime:
                        gameStore.currentDayTime,
                    maxAlternatives:
                        3
                )
        )
    }
}


private extension SocketManager {

    func backendRouteNodeAnchors()
        -> [GameBackendRouteNodeAnchorPayload] {

        let resolver =
            GameNodeRouteAnchorResolver()

        return gameStore.gameNodes
            .filter(\.isEnabled)
            .compactMap { node in

                resolver.resolve(
                    node: node,
                    graph: gameStore.roadGraph
                )
            }
            .map {
                GameBackendRouteNodeAnchorPayload(
                    anchor: $0
                )
            }
    }
}


// =====================================================
// MARK: - Search Actions
// =====================================================

extension SocketManager {

    func searchDidOpen() {

        recordApplicationAction(
            .searchOpened
        )

        rebuildSearchResults()
    }


    func updateSearchQuery(
        _ query: String
    ) {

        searchQuery =
            query

        rebuildSearchResults()

        recordApplicationAction(
            .searchChanged,
            metadata: [
                "query":
                    query
            ]
        )

        scheduleBackendSearch(
            query
        )
    }


    func submitSearch() {

        searchSocketDebounceTask?.cancel()
        searchSocketDebounceTask = nil

        rebuildSearchResults()

        recordApplicationAction(
            .searchSubmitted,
            metadata: [
                "query":
                    searchQuery,
                "resultCount":
                    "\(searchResults.count)"
            ]
        )

        let cleaned =
            searchQuery.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !cleaned.isEmpty else {
            return
        }

        emitEvent(
            event:
                .searchQuery,
            payload:
                GameSearchQueryPayload(
                    query:
                        cleaned,
                    localResultCount:
                        searchResults.count
                )
        )
    }


    func clearSearch() {

        searchSocketDebounceTask?.cancel()
        searchSocketDebounceTask = nil

        searchQuery =
            ""

        searchResults =
            []

        recordApplicationAction(
            .searchCleared
        )
    }


    /// Stores the result selection until the Search sheet has actually
    /// dismissed. AppOverlayView commits it from the sheet's onDismiss hook so
    /// DayMapView never attempts to present a node sheet on top of SearchView.
    func selectSearchResult(
        _ result: SearchResult
    ) {

        pendingSearchResult =
            result

        recordApplicationAction(
            .searchResultSelected,
            metadata: [
                "nodeId":
                    result.nodeID.rawValue.uuidString,
                "kind":
                    result.kind.rawValue,
                "title":
                    result.title
            ]
        )
    }


    func activatePendingSearchResult() {

        guard let result =
            pendingSearchResult
        else {

            return
        }

        pendingSearchResult =
            nil

        gameStore.requestGameNodeAction(
            id:
                result.nodeID
        )

        clearSearch()
    }
}


// =====================================================
// MARK: - Fifoo Play Actions
// =====================================================

extension SocketManager {

    /// Creates a fresh Fifoo Play session from a reusable backend workout
    /// template. `sourceWorkoutID` retains the catalog definition identity,
    /// while the new UUID becomes the independent session identity persisted
    /// by workout_sessions.client_workout_id.
    func activateStandaloneWorkout(
        from template: Workout
    ) {

        var exercises =
            template.exercises

        for index in exercises.indices {
            exercises[index].status = .notStarted
            exercises[index].stepsCompleted = 0
            exercises[index].pedometerDistanceMeters = 0
            exercises[index].floorsAscended = 0
            exercises[index].floorsDescended = 0
            exercises[index].averageCadence = nil
            exercises[index].averagePace = nil
            exercises[index].startedAt = nil
            exercises[index].pausedAt = nil
            exercises[index].resumedAt = nil
            exercises[index].completedAt = nil
            exercises[index].pausePeriods = []
        }

        let sourceWorkoutID =
            template.sourceWorkoutID
            ??
            template.id.uuidString

        workout =
            Workout(
                id:
                    UUID(),
                sourceWorkoutID:
                    sourceWorkoutID,
                sourceActivityNodeID:
                    nil,
                name:
                    template.name,
                description:
                    template.description,
                exercises:
                    exercises,
                status:
                    .notStarted,
                startedAt:
                    nil,
                endedAt:
                    nil,
                pausedAt:
                    nil,
                resumedAt:
                    nil,
                pausePeriods:
                    [],
                currentWorkoutExerciseID:
                    nil,
                totalSteps:
                    0,
                totalPedometerDistanceMeters:
                    0,
                totalFloorsAscended:
                    0,
                totalFloorsDescended:
                    0,
                createdAt:
                    Date(),
                updatedAt:
                    Date()
            )

        liveMessages =
            []

        liveReactions =
            []

        recordApplicationAction(
            .playWorkoutSelected,
            metadata: [
                "sourceWorkoutId":
                    sourceWorkoutID,
                "title":
                    template.name
            ]
        )
    }


    /// Loads the selected independent ActivityWorkout into the existing Fifoo
    /// Play engine. ActivityWorkout summaries intentionally do not duplicate
    /// the full exercise payload; until the backend catalog supplies one, the
    /// current exercise template is reused and reset for the selected workout.
    func activateIndependentWorkout(
        from summary: ActivityWorkoutNodeSummary,
        activityNodeID: GameNodeID
    ) {

        let sessionID =
            activityNodeID.rawValue

        // If this exact ActivityWorkout occurrence is already restored from
        // PostgreSQL, preserve its lifecycle/exercise progress instead of
        // resetting it merely because the user reopened the node.
        if workout.id == sessionID,
           workout.sourceActivityNodeID == sessionID,
           workout.sourceWorkoutID == summary.workoutID {

            requestInitialPlayData(
                workoutID:
                    sessionID,
                sourceWorkoutID:
                    summary.workoutID
            )

            recordApplicationAction(
                .activityWorkoutIndependentActivated,
                metadata: [
                    "workoutId":
                        summary.workoutID,
                    "title":
                        summary.title,
                    "restoredSession":
                        "true"
                ]
            )

            return
        }

        let isLocalBrowseWorkout =
            summary.workoutID.hasPrefix("independent-")

        var exercises =
            isLocalBrowseWorkout
            ? Self.sample.exercises
            : workout.exercises

        if summary.workoutID == "independent-upper-body" {
            exercises = exercises.filter {
                $0.name.localizedCaseInsensitiveContains("bench")
            }
        } else if summary.workoutID == "independent-cardio-core" {
            exercises = exercises.filter { exercise in
                exercise.name.localizedCaseInsensitiveContains("plank")
                || exercise.name.localizedCaseInsensitiveContains("treadmill")
            }
        }

        for index in exercises.indices {
            exercises[index].status = .notStarted
            exercises[index].stepsCompleted = 0
            exercises[index].pedometerDistanceMeters = 0
            exercises[index].floorsAscended = 0
            exercises[index].floorsDescended = 0
            exercises[index].averageCadence = nil
            exercises[index].averagePace = nil
            exercises[index].startedAt = nil
            exercises[index].pausedAt = nil
            exercises[index].resumedAt = nil
            exercises[index].completedAt = nil
            exercises[index].pausePeriods = []
        }

        workout = Workout(
            id:
                sessionID,
            sourceWorkoutID:
                summary.workoutID,
            sourceActivityNodeID:
                sessionID,
            name: summary.title,
            description: summary.description,
            exercises: exercises,
            status: .notStarted,
            startedAt: nil,
            endedAt: nil,
            pausedAt: nil,
            resumedAt: nil,
            pausePeriods: [],
            currentWorkoutExerciseID: nil,
            totalSteps: 0,
            totalPedometerDistanceMeters: 0,
            totalFloorsAscended: 0,
            totalFloorsDescended: 0,
            createdAt: Date(),
            updatedAt: Date()
        )

        // Ask the backend for this exact ActivityWorkout occurrence. If no
        // persisted session exists, the fresh not-started workout above stays
        // in place. If one exists, game:play:workout replaces it.
        requestInitialPlayData(
            workoutID:
                sessionID,
            sourceWorkoutID:
                summary.workoutID
        )

        recordApplicationAction(
            .activityWorkoutIndependentActivated,
            metadata: [
                "workoutId":
                    summary.workoutID,
                "title":
                    summary.title,
                "sessionId":
                    sessionID.uuidString
            ]
        )
    }


    func closePlay(
        pauseActiveWorkout: Bool = true
    ) {

        let didPauseWorkout =
            pauseActiveWorkout
            &&
            workout.status == .active

        if didPauseWorkout {

            WorkoutSessionManager.shared.pauseWorkout()

            emitWorkoutMutation(
                event:
                    .workoutPause
            )
        }

        isShowingPlay =
            false

        recordApplicationAction(
            .playClosed,
            metadata: [
                "workoutId":
                    workout.id.uuidString
            ]
        )
    }


    func startWorkoutSession() {

        WorkoutSessionManager.shared.startWorkout()

        recordApplicationAction(
            .workoutStarted,
            metadata:
                workoutMetadata
        )

        emitWorkoutMutation(
            event:
                .workoutStart
        )
    }


    func pauseWorkoutSession() {

        WorkoutSessionManager.shared.pauseWorkout()

        recordApplicationAction(
            .workoutPaused,
            metadata:
                workoutMetadata
        )

        emitWorkoutMutation(
            event:
                .workoutPause
        )
    }


    func resumeWorkoutSession() {

        WorkoutSessionManager.shared.resumeWorkout()

        recordApplicationAction(
            .workoutResumed,
            metadata:
                workoutMetadata
        )

        emitWorkoutMutation(
            event:
                .workoutResume
        )
    }


    func endWorkoutSession() {

        WorkoutSessionManager.shared.endWorkout()

        recordApplicationAction(
            .workoutEnded,
            metadata:
                workoutMetadata
        )

        emitWorkoutMutation(
            event:
                .workoutEnd
        )
    }


    func completeWorkoutSession() {

        WorkoutSessionManager.shared.completeWorkout()

        recordApplicationAction(
            .workoutCompleted,
            metadata:
                workoutMetadata
        )

        emitWorkoutMutation(
            event:
                .workoutComplete
        )
    }


    func selectCurrentWorkoutExercise(
        id: UUID
    ) {

        WorkoutSessionManager.shared.setCurrentExercise(
            id: id
        )

        recordApplicationAction(
            .workoutExerciseSelected,
            metadata:
                exerciseMetadata(
                    id
                )
        )

        emitWorkoutExerciseMutation(
            event:
                .exerciseSelect,
            exerciseID:
                id
        )
    }


    func startWorkoutExercise(
        id: UUID
    ) {

        WorkoutSessionManager.shared.startExercise(
            id: id
        )

        recordApplicationAction(
            .workoutExerciseStarted,
            metadata:
                exerciseMetadata(
                    id
                )
        )

        emitWorkoutExerciseMutation(
            event:
                .exerciseStart,
            exerciseID:
                id
        )
    }


    func pauseWorkoutExercise(
        id: UUID
    ) {

        WorkoutSessionManager.shared.pauseExercise(
            id: id
        )

        recordApplicationAction(
            .workoutExercisePaused,
            metadata:
                exerciseMetadata(
                    id
                )
        )

        emitWorkoutExerciseMutation(
            event:
                .exercisePause,
            exerciseID:
                id
        )
    }


    func resumeWorkoutExercise(
        id: UUID
    ) {

        WorkoutSessionManager.shared.resumeExercise(
            id: id
        )

        recordApplicationAction(
            .workoutExerciseResumed,
            metadata:
                exerciseMetadata(
                    id
                )
        )

        emitWorkoutExerciseMutation(
            event:
                .exerciseResume,
            exerciseID:
                id
        )
    }


    func completeWorkoutExercise(
        id: UUID
    ) {

        WorkoutSessionManager.shared.completeExercise(
            id: id
        )

        recordApplicationAction(
            .workoutExerciseCompleted,
            metadata:
                exerciseMetadata(
                    id
                )
        )

        emitWorkoutExerciseMutation(
            event:
                .exerciseComplete,
            exerciseID:
                id
        )
    }


    func skipWorkoutExercise(
        id: UUID
    ) {

        WorkoutSessionManager.shared.skipExercise(
            id: id
        )

        recordApplicationAction(
            .workoutExerciseSkipped,
            metadata:
                exerciseMetadata(
                    id
                )
        )

        emitWorkoutExerciseMutation(
            event:
                .exerciseSkip,
            exerciseID:
                id
        )
    }


    enum ManualWorkoutAdvanceOutcome:
        String,
        Sendable {

        case completed
        case skipped
        case ignored
    }


    /// Applies the workout rule for a user-driven upward swipe: once the
    /// exercise has reached minDuration it is completed; otherwise it is
    /// skipped. Keeping the rule here prevents PlayView from owning gameplay
    /// state transitions.
    @discardableResult
    func finishWorkoutExerciseForManualAdvance(
        id: UUID,
        elapsedTime: TimeInterval
    ) -> ManualWorkoutAdvanceOutcome {

        guard let exercise =
            workout.exercises.first(
                where: {
                    $0.workoutExerciseId == id
                }
            ),
              exercise.status == .active ||
              exercise.status == .paused
        else {
            return .ignored
        }

        let minimumDuration =
            TimeInterval(
                max(
                    0,
                    exercise.minDuration ?? 0
                )
            )

        if max(0, elapsedTime) >= minimumDuration {

            completeWorkoutExercise(
                id:
                    id
            )

            return .completed

        } else {

            skipWorkoutExercise(
                id:
                    id
            )

            return .skipped
        }
    }


    func workoutProgress() -> Double {

        WorkoutSessionManager.shared.workoutProgress()
    }


    func sendWorkoutLiveMessage(
        _ text: String
    ) {

        let cleaned =
            text.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !cleaned.isEmpty else {
            return
        }

        sendLiveMessage(
            cleaned
        )

        recordApplicationAction(
            .workoutLiveMessageSent,
            metadata: [
                "workoutId":
                    workout.id.uuidString,
                "message":
                    cleaned
            ]
        )
    }


    func sendWorkoutReaction(
        emoji: String
    ) {

        let cleaned =
            emoji.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !cleaned.isEmpty else {
            return
        }

        sendReaction(
            emoji:
                cleaned
        )

        recordApplicationAction(
            .workoutReactionSent,
            metadata: [
                "workoutId":
                    workout.id.uuidString,
                "emoji":
                    cleaned
            ]
        )
    }


    var isWorkoutVoiceMuted: Bool {

        WorkoutVoiceManager.shared.isMuted
    }


    func toggleWorkoutVoiceMute() {

        WorkoutVoiceManager.shared.toggleMute()

        recordApplicationAction(
            .workoutVoiceMuteToggled,
            metadata: [
                "isMuted":
                    isWorkoutVoiceMuted
                    ? "true"
                    : "false"
            ]
        )
    }
}


// =====================================================
// MARK: - Scene Interaction Gateway
// =====================================================

extension SocketManager:
    SceneInteractionDelegate {

    func sceneDidEmit(
        _ interaction: SceneInteraction
    ) {

        switch interaction {

        case let .backgroundTapped(
            _,
            coordinate
        ):

            handleMapBackgroundTap(
                coordinate:
                    coordinate
            )

        case let .dayTileTapped(
            cellID,
            nodeID,
            routeTarget,
            isRevealed,
            _,
            coordinate
        ):

            if !isRevealed {

                handleDayTileReveal(
                    cellID: cellID,
                    nodeID: nodeID
                )

            } else if
                let nodeID,
                let routeTarget,
                case let .alternative(routeID) = routeTarget,
                !gameStore.isAlternativeRouteFocused(routeID)
            {

                // First tap on an alternate node is a route-focus action, not
                // a node-details action. GameStore applies the matching state
                // transition immediately after this application-layer log.
                handleAlternateRouteTap(
                    routeID: routeID
                )

            } else if let nodeID {

                handleGameNodeTap(
                    nodeID:
                        nodeID
                )

            } else if routeTarget != nil {

                // GameStore decides whether this empty path card has real
                // app-provided suggestion content or should go straight to
                // the normal Add Stop flow.
                pathStopTapped(
                    cellID: cellID,
                    coordinate: coordinate
                )

            } else {

                handleMapBackgroundTap(
                    coordinate:
                        coordinate
                )
            }

        case let .roadEdgeTapped(
            edgeID,
            _,
            coordinate
        ):

            handleRoadTap(
                edgeID:
                    edgeID,
                coordinate:
                    coordinate
            )

        case let .roadVertexTapped(
            vertexID,
            _,
            coordinate
        ):

            handleIntersectionTap(
                vertexID:
                    vertexID,
                coordinate:
                    coordinate
            )

        case let .gameNodeTapped(
            nodeID,
            _,
            _
        ):

            handleGameNodeTap(
                nodeID:
                    nodeID
            )

        case let .routeTapped(
            target,
            _,
            _
        ):

            switch target {

            case .completed:

                handleCompletedRouteTap()

            case let .chosen(routeID):

                handleChosenRouteTap(
                    routeID:
                        routeID
                )

            case let .alternative(routeID):

                handleAlternateRouteTap(
                    routeID:
                        routeID
                )
            }
        }

        // GameStore remains the domain-state engine. The important change for
        // Step 1 is that every scene/user intent passes through SocketManager
        // first, giving Step 2 one place to attach Socket.IO communication.
        gameStore.sceneDidEmit(
            interaction
        )
    }
}


// =====================================================
// MARK: - Step 1 Helpers
// =====================================================

private extension SocketManager {

    var workoutMetadata:
        [String: String] {

        [
            "workoutId":
                workout.id.uuidString,
            "status":
                workout.status.rawValue
        ]
    }


    func exerciseMetadata(
        _ id: UUID
    ) -> [String: String] {

        [
            "workoutId":
                workout.id.uuidString,
            "workoutExerciseId":
                id.uuidString
        ]
    }


    func nodeMetadata(
        _ node: GameMapNode
    ) -> [String: String] {

        [
            "nodeId":
                node.id.rawValue.uuidString,
            "kind":
                node.content.kind.rawValue,
            "title":
                node.content.title,
            "time":
                node.time.displayClockString
        ]
    }


    func coordinateMetadata(
        _ coordinate: MapCoordinate
    ) -> [String: String] {

        [
            "time":
                coordinate.time.displayClockString,
            "secondsFromMidnight":
                "\(coordinate.time.secondsFromMidnight)",
            "progressPercent":
                "\(coordinate.progress.percent)"
        ]
    }


    func applicationMetadata(
        nodeID: GameNodeID,
        extra: [String: String] = [:]
    ) -> [String: String] {

        var metadata =
            gameStore
                .gameNode(
                    id:
                        nodeID
                )
                .map(
                    nodeMetadata
                )
            ?? [
                "nodeId":
                    nodeID.rawValue.uuidString
            ]

        for (key, value) in extra {
            metadata[key] = value
        }

        return metadata
    }


    func persistNodeUpdate(
        _ node: GameMapNode,
        actionName: ApplicationActionName,
        extraMetadata: [String: String] = [:],
        socketEvent: GameSocketOutgoingEvent = .nodeUpdate
    ) {

        gameStore.updateGameNode(
            node
        )

        var metadata =
            nodeMetadata(
                node
            )

        for (key, value) in extraMetadata {
            metadata[key] = value
        }

        recordApplicationAction(
            actionName,
            metadata:
                metadata
        )

        emitMutation(
            event:
                socketEvent,
            payload:
                GameNodeMutationPayload(
                    node: node
                )
        )
    }


    func performActivityNodeMutation(
        _ action: ActivityNodeEditorAction,
        node: GameMapNode,
        actionName: ApplicationActionName,
        socketEventOverride: GameSocketOutgoingEvent? = nil
    ) {

        var updatedNode =
            node

        if case var .activity(content) = updatedNode.content,
           let statusValue = action.statusValue {

            content.status =
                statusValue

            updatedNode.content =
                .activity(
                    content
                )
        }

        gameStore.updateGameNode(
            updatedNode
        )

        recordApplicationAction(
            actionName,
            metadata:
                nodeMetadata(
                    updatedNode
                )
        )

        let socketAction: GameActivitySocketAction
        let defaultSocketEvent: GameSocketOutgoingEvent

        switch action {
        case .join:
            socketAction = .join
            defaultSocketEvent = .activityJoin

        case .skip:
            socketAction = .skip
            defaultSocketEvent = .activitySkip

        case .completed:
            socketAction = .complete
            defaultSocketEvent = .activityComplete
        }

        emitMutation(
            event:
                socketEventOverride
                ?? defaultSocketEvent,
            payload:
                GameActivityMutationPayload(
                    action:
                        socketAction,
                    node:
                        updatedNode
                )
        )
    }


    func recordApplicationAction(
        _ name: ApplicationActionName,
        metadata: [String: String] = [:]
    ) {

        let record =
            ApplicationActionRecord(
                id: UUID(),
                name: name,
                createdAt: Date(),
                metadata: metadata
            )

        lastApplicationAction =
            record

        recentApplicationActions.append(
            record
        )

        if recentApplicationActions.count > 100 {

            recentApplicationActions.removeFirst(
                recentApplicationActions.count - 100
            )
        }

        #if DEBUG
        print(
            "SocketManager action:",
            name.rawValue,
            metadata
        )
        #endif

        // Application-action events are observability/UI-intent events.
        // Authoritative mutations use their typed events below. Avoid emitting
        // every search keystroke; submitSearch() sends the actual search query.
        if name != .searchChanged
            && name != .addMealBrowseQueryChanged
            && name != .addWorkoutBrowseQueryChanged {

            emitEvent(
                event:
                    .applicationAction,
                payload:
                    GameApplicationActionPayload(
                        action:
                            name.rawValue,
                        metadata:
                            metadata,
                        occurredAt:
                            record.createdAt
                    )
            )
        }
    }


    func scheduleBackendSearch(
        _ query: String
    ) {

        searchSocketDebounceTask?.cancel()

        let cleaned =
            query.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !cleaned.isEmpty else {

            searchSocketDebounceTask =
                nil

            return
        }

        searchSocketDebounceTask =
            Task { [weak self] in

                try? await Task.sleep(
                    nanoseconds:
                        350_000_000
                )

                guard !Task.isCancelled,
                      let self,
                      self.searchQuery
                        .trimmingCharacters(
                            in: .whitespacesAndNewlines
                        ) == cleaned
                else {
                    return
                }

                self.emitEvent(
                    event:
                        .searchQuery,
                    payload:
                        GameSearchQueryPayload(
                            query:
                                cleaned,
                            localResultCount:
                                self.searchResults.count
                        )
                )
            }
    }


    func rebuildSearchResults() {

        let cleanedQuery =
            searchQuery
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

        guard !cleanedQuery.isEmpty else {

            searchResults =
                []

            return
        }

        let searchTerms =
            cleanedQuery
                .lowercased()
                .split(
                    whereSeparator:
                        \.isWhitespace
                )
                .map(String.init)

        searchResults =
            gameStore
                .gameNodes
                .filter(\.isEnabled)
                .compactMap { node in

                    let haystack =
                        searchText(
                            for:
                                node
                        )
                        .lowercased()

                    guard searchTerms.allSatisfy({
                        haystack.contains($0)
                    }) else {

                        return nil
                    }

                    return makeSearchResult(
                        for:
                            node
                    )
                }
                .sorted { lhs, rhs in

                    if lhs.time == rhs.time {

                        return lhs.title.localizedCaseInsensitiveCompare(
                            rhs.title
                        ) == .orderedAscending
                    }

                    return lhs.time.secondsFromMidnight <
                        rhs.time.secondsFromMidnight
                }
    }


    func searchText(
        for node: GameMapNode
    ) -> String {

        var values = [
            node.content.title,
            node.content.kind.displayName,
            node.time.displayClockString
        ]

        switch node.content {

        case let .play(content):

            values.append(
                content.title
            )

        case let .user(content):

            values.append(
                content.userID
            )

            if let profile = content.profile {

                values.append(contentsOf: [
                    profile.username,
                    profile.firstName,
                    profile.lastName,
                    profile.goal
                ])
            }

        case let .activity(content):

            values.append(contentsOf: [
                content.activityID,
                content.activityTypeDisplayName,
                content.location,
                content.description ?? "",
                content.status
            ])

            if let meal = content.meal {
                values.append(meal.title)
            }

            if let workout = content.workout {
                values.append(workout.title)
                values.append(contentsOf: workout.categories)
            }

            if let task = content.task {
                values.append(task.title)
                values.append(task.description)
            }

        case let .post(content):

            values.append(
                content.postID
            )

            if let snapshot = content.snapshot {

                values.append(contentsOf: [
                    snapshot.postTypeDisplayName,
                    snapshot.subject,
                    snapshot.posterName,
                    snapshot.posterLocation
                ])

                values.append(contentsOf:
                    snapshot.tags
                )
            }

        case let .media(content):

            values.append(contentsOf: [
                content.mediaID,
                content.mediaType.rawValue,
                content.urlString ?? ""
            ])

        case let .hyperlink(content):

            values.append(
                content.urlString
            )
        }

        return values.joined(
            separator: " "
        )
    }


    func makeSearchResult(
        for node: GameMapNode
    ) -> SearchResult {

        SearchResult(
            nodeID:
                node.id,
            kind:
                node.content.kind,
            title:
                node.content.title
                    .trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )
                    .isEmpty
                ? "Untitled"
                : node.content.title,
            subtitle:
                searchSubtitle(
                    for:
                        node
                ),
            time:
                node.time,
            image:
                node.content.image
        )
    }


    func searchSubtitle(
        for node: GameMapNode
    ) -> String {

        switch node.content {

        case .play:

            return "Fifoo Play"

        case let .user(content):

            if let username = content.profile?.username,
               !username.isEmpty {

                return username.hasPrefix("@")
                    ? username
                    : "@\(username)"
            }

            return "User"

        case let .activity(content):

            let type =
                content.activityTypeDisplayName

            let status =
                content.status
                    .trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )

            return status.isEmpty
                ? type
                : "\(type) • \(status)"

        case let .post(content):

            return content.snapshot?
                .postTypeDisplayName
                ?? "Post"

        case let .media(content):

            return content.mediaType.rawValue.capitalized

        case let .hyperlink(content):

            if let host = URL(
                string:
                    content.urlString
            )?.host,
               !host.isEmpty {

                return host
            }

            return "Link"
        }
    }
}

