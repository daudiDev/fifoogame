//
//  SocketManager.swift
//  Fifoo Play
//
//  Created by Daudi Sagala on 8/16/26.
//

import Foundation
import Observation
import SocketIO


// MARK: - Application Socket Manager

@MainActor
@Observable
final class SocketManager {

    // MARK: - Singleton

    static let shared = SocketManager()


    // MARK: - Socket Event Names

    private enum SocketEvent {

        static let requestPlayData =
            "userRequestPlayData"

        static let receiveWorkout =
            "userReceiveWorkout"

        static let receiveLiveMessage =
            "userReceiveLiveMessage"

        static let receiveLiveMessages =
            "userReceiveLiveMessages"

        static let sendLiveReaction =
            "userSendLiveReaction"

        static let receiveLiveReaction =
            "userReceiveLiveReaction"

        static let sendLiveMessage =
            "userSendLiveMessage"
    }


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

    private var serverURL: URL?


    // MARK: - Limits

    private let maximumStoredMessages =
        100

    private let maximumStoredReactions =
        100


    // MARK: - Init

    private init() {

        /*
         Development data originates here.

         Later you can replace these with server data.
        */
        // MARK: real data
//    var workout: Workout =  Workout(id: UUID(), name: "", description: "", exercises: [], status: .notStarted, startedAt: Date(), endedAt: Date(), pausedAt: Date(), resumedAt: Date(), pausePeriods: [], currentWorkoutExerciseID: UUID(), createdAt: Date(), updatedAt: Date())
//        liveMessages = []

        workout = Self.sample

        liveMessages =
            Self.sampleLiveMessages

        /*
         DO NOT register socket events here.

         At this point `socket` is nil because
         configure(serverURL:) has not yet created it.
        */
    }
}


// MARK: - Socket Configuration

extension SocketManager {

    func configure(
        serverURL: URL
    ) {

        self.serverURL =
            serverURL


        // Remove handlers from an older socket if
        // configure() is ever called more than once.

        socket?.removeAllHandlers()

        socket?.disconnect()


        let manager =
            SocketIO.SocketManager(
                socketURL: serverURL,
                config: [
                    .log(true),
                    .compress
                ]
            )


        ioManager =
            manager

        socket =
            manager.defaultSocket


        // Register events AFTER the socket exists.

        registerSocketEvents()
    }
}


// MARK: - Connection

extension SocketManager {

    func connect() {

        guard let socket else {

            print(
                """
                SocketManager:
                configure(serverURL:) must be called
                before connect().
                """
            )

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


        // MARK: Connected
        
        socket.on(
            clientEvent: .connect
        ) { [weak self] _, _ in

            Task { @MainActor in

                guard let self else {
                    return
                }

                self.connectionState =
                    .connected

                print(
                    "Socket connected."
                )

                self.requestInitialPlayData()
            }
        }


        // MARK: Disconnected

        socket.on(
            clientEvent: .disconnect
        ) { [weak self] _, _ in

            Task { @MainActor in

                guard let self else {
                    return
                }

                self.connectionState =
                    .disconnected

                print(
                    "Socket disconnected."
                )
            }
        }


        // MARK: Reconnect

        socket.on(
            clientEvent: .reconnect
        ) { [weak self] _, _ in

            Task { @MainActor in

                self?.connectionState =
                    .reconnecting
            }
        }


        // MARK: Error

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


                self?.connectionState =
                    .failed(
                        errorMessage
                    )


                print(
                    "Socket error:",
                    errorMessage
                )
            }
        }


        // MARK: Workout

        socket.on(
            SocketEvent.receiveWorkout
        ) { [weak self] data, _ in

            Task { @MainActor in

                self?.handleWorkout(
                    data
                )
            }
        }


        // MARK: New Live Message

        socket.on(
            SocketEvent.receiveLiveMessage
        ) { [weak self] data, _ in

            Task { @MainActor in

                self?.handleLiveMessage(
                    data
                )
            }
        }


        // MARK: Live Message History

        socket.on(
            SocketEvent.receiveLiveMessages
        ) { [weak self] data, _ in

            Task { @MainActor in

                self?.handleLiveMessages(
                    data
                )
            }
        }


        // MARK: Live Reaction

        socket.on(
            SocketEvent.receiveLiveReaction
        ) { [weak self] data, _ in

            Task { @MainActor in

                self?.handleLiveReaction(
                    data
                )
            }
        }
    }
}


// MARK: - Requests

extension SocketManager {

    func requestInitialPlayData() {

        guard isConnected else {
            return
        }


        socket?.emit(
            SocketEvent.requestPlayData
        )
    }
}


// MARK: - Workout Handling

private extension SocketManager {

    func handleWorkout(
        _ data: [Any]
    ) {

        guard let dictionary =
                data.first
                    as? [String: Any]
        else {

            print(
                "Invalid workout socket payload."
            )

            return
        }


        do {

            let jsonData =
                try JSONSerialization.data(
                    withJSONObject:
                        dictionary
                )


            let decodedWorkout =
                try makeJSONDecoder()
                    .decode(
                        Workout.self,
                        from: jsonData
                    )


            workout =
                decodedWorkout


        } catch {

            print(
                "Workout decoding error:",
                error
            )
        }
    }
}


// MARK: - Live Message Handling

private extension SocketManager {

    func handleLiveMessage(
        _ data: [Any]
    ) {

        guard let dictionary =
                data.first
                    as? [String: Any]
        else {

            print(
                "Invalid live message payload."
            )

            return
        }


        do {

            let jsonData =
                try JSONSerialization.data(
                    withJSONObject:
                        dictionary
                )


            let message =
                try makeJSONDecoder()
                    .decode(
                        WorkoutLiveMessage.self,
                        from: jsonData
                    )


            addLiveMessage(
                message
            )


        } catch {

            print(
                "Live message decoding error:",
                error
            )
        }
    }


    func handleLiveMessages(
        _ data: [Any]
    ) {

        guard let array =
                data.first
                    as? [[String: Any]]
        else {

            print(
                "Invalid message history payload."
            )

            return
        }


        do {

            let jsonData =
                try JSONSerialization.data(
                    withJSONObject:
                        array
                )


            let messages =
                try makeJSONDecoder()
                    .decode(
                        [WorkoutLiveMessage].self,
                        from: jsonData
                    )


            liveMessages =
                Array(
                    messages.suffix(
                        maximumStoredMessages
                    )
                )


        } catch {

            print(
                "Message history decoding error:",
                error
            )
        }
    }
}


// MARK: - Live Reaction Handling

private extension SocketManager {

    func handleLiveReaction(
        _ data: [Any]
    ) {

        guard let dictionary =
                data.first
                    as? [String: Any]
        else {

            print(
                "Invalid live reaction payload."
            )

            return
        }


        do {

            let jsonData =
                try JSONSerialization.data(
                    withJSONObject:
                        dictionary
                )


            let reaction =
                try makeJSONDecoder()
                    .decode(
                        WorkoutLiveReaction.self,
                        from: jsonData
                    )


            addLiveReaction(
                reaction
            )


        } catch {

            print(
                "Live reaction decoding error:",
                error
            )
        }
    }
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


// MARK: - Sending Data

extension SocketManager {

    func sendLiveMessage(
        _ text: String
    ) {

        guard isConnected else {
            return
        }


        let payload:
            [String: Any] = [

                "message":
                    text
            ]


        socket?.emit(
            SocketEvent.sendLiveMessage,
            payload
        )
    }


    func sendReaction(
        emoji: String
    ) {

        guard isConnected else {
            return
        }

        let workout =
            self.workout

        let payload:
            [String: Any] = [

                "emoji":
                    emoji,

                "workoutId":
                    workout.id.uuidString,

                "exerciseId":
                    workout
                        .currentWorkoutExerciseID?
                        .uuidString
                    ?? "",

                "createdAt":
                    ISO8601DateFormatter()
                        .string(
                            from: Date()
                        )
            ]


        socket?.emit(
            SocketEvent.sendLiveReaction,
            payload
        )
    }
    
}


// MARK: - JSON Decoder

private extension SocketManager {

    func makeJSONDecoder() -> JSONDecoder {

        let decoder =
            JSONDecoder()

        /*
         When you know the exact date format your
         backend sends, configure it here.

         Example:

         decoder.dateDecodingStrategy =
             .iso8601
        */

        return decoder
    }
}


// MARK: - Development Sample Data

private extension SocketManager {
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
